/*
 * Copyright 2010 Niels Provos and Nick Mathewson
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/* XXXX sys/signalfd is present with glibc 2.8 or later.  But linux 2.6.22
 * and later have the syscall.  I wonder... */

#include <sys/signalfd.h>
#include <signal.h>
#include <string.h>

#include <unistd.h>
#include <fcntl.h>

#include <event2/event.h>
#include <event2/event_struct.h>

#include "event-internal.h"
#include "evsignalfd-internal.h"
#include "evmap-internal.h"
#include "evthread-internal.h"

static int evsigfd_add(struct event_base *, int, short, short, void *);
static int evsigfd_del(struct event_base *, int, short, short, void *);

const struct eventop evsigfdops = {
	"signalfd",
	NULL,
	evsigfd_add,
	evsigfd_del,
	NULL,
	NULL,
	0, 0, 0
};

#ifndef _EVENT_DISABLE_THREAD_SUPPORT
static void *evsigfd_lock = NULL;
#endif
static int evsigfd_global_sig_count[NSIG];
static sigset_t evsigfd_orig_sigset;

#define EVSIGFD_LOCK() EVLOCK_LOCK(evsigfd_lock, 0)
#define EVSIGFD_UNLOCK() EVLOCK_UNLOCK(evsigfd_lock, 0)

static void
evsigfd_read_cb(evutil_socket_t fd, short what, void *arg)
{
	struct event_base *base = arg;
	struct signalfd_siginfo si;
	int ncaught[NSIG];
	int i;

	memset(&ncaught, 0, sizeof(ncaught));

	while (1) {
		int r = read(fd, &si, sizeof(si));

		if (r <= 0) {
			break; /* XXXX log real errors */
		}
		if (si.ssi_signo < NSIG) {
			++ncaught[si.ssi_signo];
		}
	}
	EVBASE_ACQUIRE_LOCK(base, th_base_lock);
	for (i=0; i < NSIG; ++i) {
		if (ncaught[i]) {
			evmap_signal_active(base, i, ncaught[i]);
		}
	}
	EVBASE_RELEASE_LOCK(base, th_base_lock);
}


int
evsigfd_init(struct event_base *base)
{
	struct evsigfd_info *sigbase = &base->evsigfd;
	int fd;
	int flags;

#ifndef _EVENT_DISABLE_THREAD_SUPPORT
	if (evsigfd_lock == NULL)
		EVTHREAD_ALLOC_LOCK(evsigfd_lock, 0);
#endif

	memset(sigbase, 0, sizeof(struct evsigfd_info));
	if (sigemptyset(&sigbase->ev_signalset) < 0)
		return -1;
	if ((fd = sigbase->ev_signalfd =
		signalfd(-1, &sigbase->ev_signalset, 0)) < 0)
		return -1;

	flags = O_NONBLOCK;
	if (fcntl(fd, F_SETFL, flags) == -1) {
		event_warn("fcntl(%d, F_SETFL)", fd);
		close(fd);
		return -1;
	}
	flags = FD_CLOEXEC;
	if (fcntl(fd, F_SETFD, flags) == -1) {
		event_warn("fcntl(%d, F_SETFD)", fd);
		close(fd);
		return -1;
	}

	event_assign(&sigbase->ev_signal, base, fd, EV_READ|EV_PERSIST,
	    evsigfd_read_cb, base);
	sigbase->ev_signal.ev_flags |= EVLIST_INTERNAL;

	base->evsigsel = &evsigfdops;
	base->evsigbase = &base->evsigfd;

	/* XXX will we handle reinit properly? */

	return 0;
}

static int
evsigfd_add(struct event_base *base, int sig, short events, short old, void *p)
{
	struct evsigfd_info *sigbase = &base->evsigfd;
	int res = 0;

	if (sigaddset(&sigbase->ev_signalset, sig) < 0)
		return -1;

	if (signalfd(sigbase->ev_signalfd, &sigbase->ev_signalset, 0)<0)
		return -1;

	EVSIGFD_LOCK();
	if (++evsigfd_global_sig_count[sig] == 1) {
		sigset_t sigset, oldset;
		sigemptyset(&sigset);
		sigaddset(&sigset, sig);
		/* XXXX undefined with pthreads by posix.  ok by linux???? */
		if (sigprocmask(SIG_BLOCK, &sigset, &oldset) < 0) {
			res = -1;
		} else {
			if (sigismember(&oldset, sig))
				sigaddset(&evsigfd_orig_sigset, sig);
		}
	}
	EVSIGFD_UNLOCK();

	if (res == 0 && !sigbase->ev_signal_added) {
		res = event_add(&sigbase->ev_signal, NULL);
		if (res == 0)
			sigbase->ev_signal_added = 1;
	}

	return res;
}
static int
evsigfd_del(struct event_base *base, int sig, short events, short old, void *p)
{
	struct evsigfd_info *sigbase = &base->evsigfd;
	int res = 0;
	if (sigdelset(&sigbase->ev_signalset, sig) < 0)
		return -1;
	if (signalfd(sigbase->ev_signalfd, &sigbase->ev_signalset, 0) < 0)
		return -1;

	EVSIGFD_LOCK();
	if (--evsigfd_global_sig_count[sig] == 0) {
		if (sigismember(&evsigfd_orig_sigset, sig)) {
			/* This signal was blocked to begin with. */
			sigdelset(&evsigfd_orig_sigset, sig);
		} else {
			/* Unblock this signal. */
			sigset_t sigset;
			sigemptyset(&sigset);
			sigaddset(&sigset, sig);
			/* XXXX unspecified with pthreads by posix.
			   ok by linux???? */
			sigprocmask(SIG_UNBLOCK, &sigset, NULL);
		}
	}
	EVUTIL_ASSERT(evsigfd_global_sig_count[sig] >= 0);
	EVSIGFD_UNLOCK();

	return res;
}

void
evsigfd_dealloc(struct event_base *base)
{
	struct evsigfd_info *sigbase = &base->evsigfd;
	event_del(&sigbase->ev_signal);
	event_debug_unassign(&base->sig.ev_signal);
	close(sigbase->ev_signalfd);

	/* XXX restore handlers & whatnot? */
}
