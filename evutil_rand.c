/*
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

/* This file has our secure PRNG code, which is currently based on
 * arc4random (using a platform implementation if available), but
 * renamed for export to the rest of the library, because it's not
 * nice to name your APIs after their implementations.
 */

#include "config.h"

#include "arc4random-internal.h"
#include "util-internal.h"
#include "evthread-internal.h"

#include <limits.h>

int
evutil_secure_rng_init(void)
{
	/* call arc4random() now to force it to self-initialize */
	(void) ev_arc4random();
	return 0;
}

void
evutil_secure_rng_get_bytes(void *buf, size_t n)
{
	ev_arc4random_buf(buf, n);
}

void
evutil_secure_rng_add_bytes(const char *buf, size_t n)
{
	/* arc4random_addrandom isn't const-correct :-( */
	ev_arc4random_addrandom((unsigned char *) buf,
				n>(size_t)INT_MAX ? INT_MAX : (int)n);
}

#ifndef DISABLE_THREAD_SUPPORT
int
evutil_secure_rng_global_setup_locks_(int enable_locks)
{
	return ev_arc4random_setup_locks(enable_locks);
}
#endif

void
evutil_free_secure_rng_globals_(void)
{
	ev_arc4random_free_locks();
}
