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
#ifndef EVENT2_UTIL_COMPAT_H_INCLUDED_
#define EVENT2_UTIL_COMPAT_H_INCLUDED_

/** @file event2/util_compat.h

    Grab bag of definitions which used to be exposed in util.h despite
    being intended primarily for internal use.  Preserved here for
    backward compatibility's sake.

 */

#include <event2/util.h>

#ifdef EVENT__HAVE_STDINT_H
#include <stdint.h>
#elif defined(EVENT__HAVE_INTTYPES_H)
#include <inttypes.h>
#else
#include <limits.h>
#endif

/* Backward compatibility for historical defensiveness against the
   possibility that SIZE_MAX might not be available.  SIZE_MAX is
   guaranteed to be defined by both stdint.h and inttypes.h, but
   if we don't have either of those, limits.h will also do it.  */
#define EV_SIZE_MAX SIZE_MAX

/* Backward compatibility for historical defensiveness against the
   possibility that offsetof might not be available.  event2/util.h
   includes stddef.h, so we don't have to do it again.  */
#define evutil_offsetof(type, field) offsetof(type, field)

/* Obsolete alternative name for evutil_closesocket. */
#define EVUTIL_CLOSESOCKET(s) evutil_closesocket(s)

#endif
