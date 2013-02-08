/*      $OpenBSD: queue.h,v 1.16 2000/09/07 19:47:59 art Exp $  */
/*      $NetBSD: queue.h,v 1.11 1996/05/16 05:17:14 mycroft Exp $       */

/*
 * Copyright (c) 1991, 1993
 *      The Regents of the University of California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *      @(#)queue.h     8.5 (Berkeley) 8/20/94
 */

#ifndef EVENT2_QUTIL_H_INCLUDED_
#define EVENT2_QUTIL_H_INCLUDED_

/* Internal use only: This file defines the subset of BSD
 * <sys/queue.h> that is used by libevent, with all the macros
 * renamed to avoid collision with the system header (which may
 * be included indirectly by other system headers on platforms
 * that have it).
 *
 * Once event_struct.h, http_struct.h, keyvalq_struct.h, and
 * rpc_struct.h are unexported or cease to require this file,
 * we can make this an -internal header.
 */

#define EVENT__LIST_HEAD(name, type)					\
struct name {								\
	struct type *lh_first;	/* first element */			\
}

#define EVENT__LIST_HEAD_INITIALIZER(head)				\
	{ NULL }

#define EVENT__LIST_ENTRY(type)						\
struct {								\
	struct type *le_next;	/* next element */			\
	struct type **le_prev;	/* address of previous next element */	\
}

#define	EVENT__LIST_FIRST(head)	     ((head)->lh_first)
#define	EVENT__LIST_END(head)	     NULL
#define	EVENT__LIST_EMPTY(head)						\
	(EVENT__LIST_FIRST(head) == EVENT__LIST_END(head))
#define	EVENT__LIST_NEXT(elm, field) ((elm)->field.le_next)

#define EVENT__LIST_FOREACH(var, head, field)				\
	for((var) = EVENT__LIST_FIRST(head);				\
	    (var)!= EVENT__LIST_END(head);				\
	    (var) = EVENT__LIST_NEXT(var, field))

#define	EVENT__LIST_INIT(head) do {					\
	EVENT__LIST_FIRST(head) = EVENT__LIST_END(head);		\
} while (0)

#define EVENT__LIST_INSERT_HEAD(head, elm, field) do {			\
	if (((elm)->field.le_next = (head)->lh_first) != NULL)		\
		(head)->lh_first->field.le_prev = &(elm)->field.le_next;\
	(head)->lh_first = (elm);					\
	(elm)->field.le_prev = &(head)->lh_first;			\
} while (0)

#define EVENT__LIST_REMOVE(elm, field) do {				\
	if ((elm)->field.le_next != NULL)				\
		(elm)->field.le_next->field.le_prev =			\
		    (elm)->field.le_prev;				\
	*(elm)->field.le_prev = (elm)->field.le_next;			\
} while (0)

#define EVENT__TAILQ_HEAD(name, type)					\
struct name {								\
	struct type *tqh_first;	/* first element */			\
	struct type **tqh_last;	/* addr of last next element */		\
}

#define EVENT__TAILQ_ENTRY(type)					\
struct {								\
	struct type *tqe_next;	/* next element */			\
	struct type **tqe_prev;	/* address of previous next element */	\
}

#define	EVENT__TAILQ_FIRST(head)	((head)->tqh_first)
#define EVENT__TAILQ_END(head)		NULL
#define	EVENT__TAILQ_NEXT(elm, field)	((elm)->field.tqe_next)
#define EVENT__TAILQ_LAST(head, headname)				\
	(*(((struct headname *)((head)->tqh_last))->tqh_last))
#define EVENT__TAILQ_PREV(elm, headname, field)				\
       (*(((struct headname *)((elm)->field.tqe_prev))->tqh_last))
#define	EVENT__TAILQ_EMPTY(head)					\
	(EVENT__TAILQ_FIRST(head) == EVENT__TAILQ_END(head))

#define EVENT__TAILQ_FOREACH(var, head, field)				\
	for((var) = EVENT__TAILQ_FIRST(head);					\
	    (var) != EVENT__TAILQ_END(head);					\
	    (var) = EVENT__TAILQ_NEXT(var, field))

#define EVENT__TAILQ_FOREACH_REVERSE(var, head, headname, field)	\
	for((var) = EVENT__TAILQ_LAST(head, headname);				\
	    (var) != EVENT__TAILQ_END(head);					\
	    (var) = EVENT__TAILQ_PREV(var, headname, field))

#define	EVENT__TAILQ_INIT(head) do {					\
	(head)->tqh_first = NULL;					\
	(head)->tqh_last = &(head)->tqh_first;				\
} while (0)

#define EVENT__TAILQ_INSERT_HEAD(head, elm, field) do {			\
	if (((elm)->field.tqe_next = (head)->tqh_first) != NULL)	\
		(head)->tqh_first->field.tqe_prev =			\
		    &(elm)->field.tqe_next;				\
	else								\
		(head)->tqh_last = &(elm)->field.tqe_next;		\
	(head)->tqh_first = (elm);					\
	(elm)->field.tqe_prev = &(head)->tqh_first;			\
} while (0)

#define EVENT__TAILQ_INSERT_TAIL(head, elm, field) do {			\
	(elm)->field.tqe_next = NULL;					\
	(elm)->field.tqe_prev = (head)->tqh_last;			\
	*(head)->tqh_last = (elm);					\
	(head)->tqh_last = &(elm)->field.tqe_next;			\
} while (0)

#define EVENT__TAILQ_INSERT_AFTER(head, listelm, elm, field) do {	\
	if (((elm)->field.tqe_next = (listelm)->field.tqe_next) != NULL)\
		(elm)->field.tqe_next->field.tqe_prev =			\
		    &(elm)->field.tqe_next;				\
	else								\
		(head)->tqh_last = &(elm)->field.tqe_next;		\
	(listelm)->field.tqe_next = (elm);				\
	(elm)->field.tqe_prev = &(listelm)->field.tqe_next;		\
} while (0)

#define EVENT__TAILQ_REMOVE(head, elm, field) do {			\
	if (((elm)->field.tqe_next) != NULL)				\
		(elm)->field.tqe_next->field.tqe_prev =			\
		    (elm)->field.tqe_prev;				\
	else								\
		(head)->tqh_last = (elm)->field.tqe_prev;		\
	*(elm)->field.tqe_prev = (elm)->field.tqe_next;			\
} while (0)

#endif	/* qutil.h */
