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

#ifndef ARC4RANDOM_INTERNAL_H_INCLUDED_
#define ARC4RANDOM_INTERNAL_H_INCLUDED_

#include <event2/util.h>

/* Including arc4random-internal.h should always bring in stdlib.h,
   regardless of whether we need to define our own arc4random.  */
#include <stdlib.h>

#ifdef HAVE_ARC4RANDOM

#define ev_arc4random() arc4random()
#define ev_arc4random_addrandom(buf_, n_) arc4random_addrandom(buf_, n_)
#define ev_arc4random_setup_locks(enable_) ((enable_), 0)
#define ev_arc4random_free_locks() do { } while (0)

#else

extern ev_uint32_t ev_arc4random_(void);
#define ev_arc4random() ev_arc4random_()

extern void ev_arc4random_addrandom_(unsigned char *buf, int n);
#define ev_arc4random_addrandom(buf_, n_) ev_arc4random_addrandom_(buf_, n_)

#ifdef DISABLE_THREAD_SUPPORT

#define ev_arc4random_setup_locks(enable_) ((enable_), 0)
#define ev_arc4random_free_locks() do { } while (0)

#else

extern int ev_arc4random_setup_locks_(int enable_locks);
#define ev_arc4random_setup_locks(enable_) ev_arc4random_setup_locks_(enable_)

extern void ev_arc4random_free_locks_(void);
#define ev_arc4random_free_locks() ev_arc4random_free_locks_()

#endif /* !DISABLE_THREAD_SUPPORT */
#endif /* !HAVE_ARC4RANDOM */

#ifdef HAVE_ARC4RANDOM_BUF

#ifndef __APPLE__
#define ev_arc4random_buf(buf_, n_) arc4random_buf(buf_, n_)
#else
/* OSX 10.7 introduced arc4random_buf, so if you build your program
 * there, you'll get surprised when older versions of OSX fail to run.
 * To solve this, we can check whether the function pointer is set,
 * and fall back otherwise.  (OSX does this using some linker
 * trickery.)
 */
static inline void
ev_arc4random_buf(void *buf, size_t n)
{
	if (arc4random_buf != NULL) {
		return arc4random_buf(buf, n);
	}
	/* Make sure that we start out with b at a 4-byte alignment; plenty
	 * of CPUs care about this for 32-bit access. */
	if (n >= 4 && ((ev_uintptr_t)b) & 3) {
		ev_uint32_t u = arc4random();
		int n_bytes = 4 - (((ev_uintptr_t)b) & 3);
		memcpy(b, &u, n_bytes);
		b += n_bytes;
		n -= n_bytes;
	}
	while (n >= 4) {
		*(ev_uint32_t*)b = arc4random();
		b += 4;
		n -= 4;
	}
	if (n) {
		ev_uint32_t u = arc4random();
		memcpy(b, &u, n);
	}
}
#endif /* __APPLE__ */

#else /* !HAVE_ARC4RANDOM_BUF */

extern void ev_arc4random_buf_(void *buf, size_t n);
#define ev_arc4random_buf(buf_, n_) ev_arc4random_buf_(buf_, n_)

#endif /* !HAVE_ARC4RANDOM_BUF */

#endif /* arc4random-internal.h */
