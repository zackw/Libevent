/*
 * Copyright (c) 2000-2007 Niels Provos <provos@citi.umich.edu>
 * Copyright (c) 2007-2012 Niels Provos and Nick Mathewson
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
#ifndef EVENT2_EVENT_STRUCT_H_INCLUDED_
#define EVENT2_EVENT_STRUCT_H_INCLUDED_

/** @file event2/event_struct.h

  Structures used by event.h.  Using these structures directly WILL harm
  forward compatibility: be careful.

  No field declared in this file should be used directly in user code.  Except
  for historical reasons, these fields would not be exposed at all.
 */

#include <event2/util.h>

/* For evkeyvalq */
#include <event2/keyvalq_struct.h>

/* For EVENT__LIST_ENTRY, EVENT__LIST_HEAD,
       EVENT__TAILQ_ENTRY, EVENT__TAILQ_HEAD */
#include <event2/qutil.h>

#ifdef __cplusplus
extern "C" {
#endif

#define EVLIST_TIMEOUT	    0x01
#define EVLIST_INSERTED	    0x02
#define EVLIST_SIGNAL	    0x04
#define EVLIST_ACTIVE	    0x08
#define EVLIST_INTERNAL	    0x10
#define EVLIST_ACTIVE_LATER 0x20
#define EVLIST_INIT	    0x80

#define EVLIST_ALL          0xbf

struct event_callback {
	EVENT__TAILQ_ENTRY(event_callback) evcb_active_next;
	short evcb_flags;
	ev_uint8_t evcb_pri;	/* smaller numbers are higher priority */
	ev_uint8_t evcb_closure;
	/* allows us to adopt for different types of events */
        union {
		void (*evcb_callback)(evutil_socket_t, short, void *arg);
		void (*evcb_selfcb)(struct event_callback *, void *arg);
	} evcb_cb_union;
	void *evcb_arg;
};

struct event_base;
struct event {
	struct event_callback ev_evcallback;

	/* for managing timeouts */
	union {
		EVENT__TAILQ_ENTRY(event) ev_next_with_common_timeout;
		int min_heap_idx;
	} ev_timeout_pos;
	evutil_socket_t ev_fd;

	struct event_base *ev_base;

	union {
		/* used for io events */
		struct {
			EVENT__LIST_ENTRY (event) ev_io_next;
			struct timeval ev_timeout;
		} ev_io;

		/* used by signal events */
		struct {
			EVENT__LIST_ENTRY (event) ev_signal_next;
			short ev_ncalls;
			/* Allows deletes in callback */
			short *ev_pncalls;
		} ev_signal;
	} ev_;

	short ev_events;
	short ev_res;		/* result passed to event callback */
	struct timeval ev_timeout;
};

EVENT__TAILQ_HEAD (event_list, event);
EVENT__LIST_HEAD (event_dlist, event);

#ifdef __cplusplus
}
#endif

#endif /* EVENT2_EVENT_STRUCT_H_INCLUDED_ */
