# Complex checks for particular functions.

AC_DEFUN([LIBEVENT_INCLUDES_NETDB],
[AC_INCLUDES_DEFAULT
#ifdef HAVE_NETDB_H
#include <netdb.h>
#endif
])

# This only requires its own macro because AC_CHECK_FUNCS doesn't let
# you specify additional header files to include.  As long as we have
# to drop down to AC_LINK_IFELSE, though, we might as well make the
# call well-formed.
AC_DEFUN([LIBEVENT_FUNC_GETADDRINFO],
 [AC_CACHE_CHECK([for getaddrinfo], [libevent_cv_func_getaddrinfo],
   [AC_LINK_IFELSE([AC_LANG_PROGRAM([LIBEVENT_INCLUDES_NETDB],
    [[struct addrinfo *res;
      return getaddrinfo("node", "service", 0, &res);]])],
     [libevent_cv_func_getaddrinfo=yes],
     [libevent_cv_func_getaddrinfo=no])])
  AS_VAR_IF([libevent_cv_func_getaddrinfo], [yes],
   [AC_DEFINE([HAVE_GETADDRINFO], [1],
     [Define to 1 if you have the `getaddrinfo' function.])])])

# Check for gethostbyname_r in all its glorious incompatible versions.
# (This is taken originally from Tor, which based its logic on
# Python's configure.in.)
AC_DEFUN([LIBEVENT_FUNC_GETHOSTBYNAME_R],
 [AC_CACHE_CHECK([how many arguments gethostbyname_r takes],
                 [libevent_cv_func_gethostbyname_r_nargs],
   [libevent_cv_func_gethostbyname_r_nargs="failed"
    AC_COMPILE_IFELSE([AC_LANG_PROGRAM([LIBEVENT_INCLUDES_NETDB],
    [[char *cp1, *cp2;
      struct hostent *h1, *h2;
      int i1, i2;
      (void)gethostbyname_r(cp1,h1,cp2,i1,&h2,&i2);]])],
     [libevent_cv_func_gethostbyname_r_nargs=6])
    AS_VAR_IF([libevent_cv_func_gethostbyname_r_nargs], [failed],
     [AC_COMPILE_IFELSE([AC_LANG_PROGRAM([LIBEVENT_INCLUDES_NETDB],
      [[char *cp1, *cp2;
        struct hostent *h1;
        int i1, i2;
        (void)gethostbyname_r(cp1,h1,cp2,i1,&i2);]])],
       [libevent_cv_func_gethostbyname_r_nargs=5])])
    AS_VAR_IF([libevent_cv_func_gethostbyname_r_nargs], [failed],
     [AC_COMPILE_IFELSE([AC_LANG_PROGRAM([LIBEVENT_INCLUDES_NETDB],
      [[char *cp1;
        struct hostent *h1;
        struct hostent_data hd;
        (void) gethostbyname_r(cp1,h1,&hd);]])],
       [libevent_cv_func_gethostbyname_r_nargs=3])])])
  AS_CASE([$libevent_cv_func_gethostbyname_r_nargs],
   [6], [AC_DEFINE([HAVE_GETHOSTBYNAME_R_6_ARG], [1],
          [Define to 1 if you have a `gethostbyname_r' with 6 arguments.])],
   [5], [AC_DEFINE([HAVE_GETHOSTBYNAME_R_5_ARG], [1],
          [Define to 1 if you have a `gethostbyname_r' with 5 arguments.])],
   [3], [AC_DEFINE([HAVE_GETHOSTBYNAME_R_3_ARG], [1],
          [Define to 1 if you have a `gethostbyname_r' with 3 arguments.])])])

# Check for a fully operational kqueue.
AC_DEFUN([LIBEVENT_FUNC_KQUEUE_WORKS],
 [if test "${ac_cv_header_sys_event_h+set}" != set; then
    AC_CHECK_HEADERS([sys/event.h])
  fi
  if test "${ac_cv_func_kqueue+set}" != set; then
    AC_CHECK_FUNCS([kqueue])
  fi
  if test $ac_cv_header_sys_event_h != yes || \
     test $ac_cv_func_kqueue != yes; then
    libevent_cv_func_kqueue_works=no
  else
    AC_CACHE_CHECK([whether kqueue works correctly with pipes],
                   [libevent_cv_func_kqueue_works],
     [AC_RUN_IFELSE([AC_LANG_SOURCE([[
#include <sys/types.h>
#include <sys/time.h>
#include <sys/event.h>
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>

int
main(void)
{
	int kq;
	int n;
	int fd[2];
	struct kevent ev;
	struct timespec ts;
	char buf[8000];

	if (pipe(fd) == -1)
		return 1;
	if (fcntl(fd[1], F_SETFL, O_NONBLOCK) == -1)
		return 1;

	while ((n = write(fd[1], buf, sizeof(buf))) == sizeof(buf))
		;

        if ((kq = kqueue()) == -1)
		return 1;

	memset(&ev, 0, sizeof(ev));
	ev.ident = fd[1];
	ev.filter = EVFILT_WRITE;
	ev.flags = EV_ADD | EV_ENABLE;
	n = kevent(kq, &ev, 1, NULL, 0, NULL);
	if (n == -1)
		return 1;

	read(fd[0], buf, sizeof(buf));

	ts.tv_sec = 0;
	ts.tv_nsec = 0;
	n = kevent(kq, NULL, 0, &ev, 1, &ts);
	if (n == -1 || n == 0)
		return 1;

	return 0;
}
]])],
       [libevent_cv_func_kqueue_works=yes],
       [libevent_cv_func_kqueue_works=no],
       [# when cross compiling
        libevent_cv_func_kqueue_works=no])])
  fi
  if test $libevent_cv_func_kqueue_works = yes; then
    AC_DEFINE([HAVE_WORKING_KQUEUE], [1],
              [Define if kqueue works correctly with pipes.])
  fi])

# Check for kernel and C library support for epoll.
AC_DEFUN([LIBEVENT_FUNC_EPOLL],
 [if test "${ac_cv_header_sys_epoll_h+set}" != set; then
    AC_CHECK_HEADERS([sys/epoll.h])
  fi
  if test "${ac_cv_func_epoll_ctl+set}" != set; then
    AC_CHECK_FUNCS([epoll_ctl])
  fi
  haveepoll=no
  if test $ac_cv_header_sys_epoll_h = yes; then
    if test $ac_cv_func_epoll_ctl = yes; then
      haveepoll=yes
    else
      AC_CACHE_CHECK([for epoll system calls], [libevent_cv_syscall_epoll],
       [AC_RUN_IFELSE([AC_LANG_SOURCE([[
#include <stdint.h>
#include <sys/param.h>
#include <sys/types.h>
#include <sys/syscall.h>
#include <sys/epoll.h>
#include <unistd.h>

int
epoll_create(int size)
{
	return (syscall(__NR_epoll_create, size));
}

int
main(int argc, char **argv)
{
	int epfd;

	epfd = epoll_create(256);
	return (epfd == -1) ? 1 : 0;
}
]])],
       [libevent_cv_syscall_epoll=yes],
       [libevent_cv_syscall_epoll=no],
       [# when cross compiling
        libevent_cv_syscall_epoll=no])])
      if test $ac_cv_syscall_epoll = yes; then
        haveepoll=yes
        AC_LIBOBJ([epoll_sub])
      fi
    fi
  fi
  if test $haveepoll = yes; then
    AC_DEFINE([HAVE_EPOLL], [1],
              [Define if your system supports the `epoll' interface.])
  fi])
