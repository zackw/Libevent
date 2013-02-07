dnl Copyright 2000-2007 Niels Provos
dnl Copyright 2007-2012 Niels Provos and Nick Mathewson
dnl
dnl See LICENSE for copying information.
dnl
dnl Original version Dug Song <dugsong@monkey.org>

AC_INIT([libevent],[2.1.2-alpha-dev])
AC_PREREQ([2.69])
AC_CONFIG_SRCDIR(event.c)
AC_CONFIG_AUX_DIR([config-aux])
AC_CONFIG_MACRO_DIR([config-aux])
AC_CONFIG_HEADERS([config.h  evconfig-private.h:evconfig-private.h.in])
AC_CONFIG_FILES([libevent.pc libevent_openssl.pc libevent_pthreads.pc
                 Makefile])
AM_INIT_AUTOMAKE
dnl AM_SILENT_RULES req. automake 1.11.  [no] defaults V=1
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])
AC_DEFINE(NUMERIC_VERSION, 0x02010201, [Numeric representation of the version])

dnl Additional configure options...
LIBEVENT_DISABLE([gcc-warnings],
                 [verbose warnings from GCC])
LIBEVENT_ENABLE( [gcc-warnings-are-errors],
                 [making warnings into errors])
LIBEVENT_ENABLE( [gcc-hardening],
                 [compiler defenses against some security bugs])
LIBEVENT_DISABLE([thread-support],
                 [support for multithreading])
LIBEVENT_DISABLE([malloc-replacement],
                 [support for user-supplied memory management functions])
LIBEVENT_DISABLE([openssl],
                 [support for the SSL protocol (via openssl)])
LIBEVENT_DISABLE([debug-mode],
                 [support for running in debug mode])
LIBEVENT_DISABLE([libevent-install], [installation of libevent])
LIBEVENT_DISABLE([libevent-regress], [regression tests])
LIBEVENT_ENABLE( [function-sections],
           [compiler options for smaller static binaries (with --gc-sections)])
LIBEVENT_ENABLE( [verbose-debug], [verbose debug logging])

if test $enable_thread_support = no; then
   AC_DEFINE(DISABLE_THREAD_SUPPORT, 1,
	[Define if libevent should not be compiled with thread support])
fi

if test $enable_malloc_replacement = no; then
  AC_DEFINE(DISABLE_MM_REPLACEMENT, 1,
        [Define if libevent should not allow replacing the mm functions])
fi

if test $enable_debug_mode = no; then
  AC_DEFINE(DISABLE_DEBUG_MODE, 1,
        [Define if libevent should build without support for a debug mode])
fi

AM_CONDITIONAL([BUILD_REGRESS], [test "$enable_libevent_regress" = "yes"])
AM_CONDITIONAL([INSTALL_LIBEVENT], [test "$enable_libevent_install" = "yes"])

dnl the 'build' machine is where we run configure and compile
dnl the 'host' machine is where the resulting stuff runs.
AC_CANONICAL_BUILD
AC_CANONICAL_HOST

dnl Checks for programs.
dnl mkdir -p handled by AM_INIT_AUTOMAKE
dnl sed handled by LT_INIT
dnl pkg-config 0.15.0 may not be strictly necessary, but it's what we
dnl were looking for before
AM_PROG_CC_C_O
AC_PROG_INSTALL
AC_PROG_LN_S
PKG_PROG_PKG_CONFIG([0.15.0])

# Set up the compilation environment.  Must come before any compile
# checks, including those embedded in e.g. LT_INIT.  Preprocessor
# checks are OK (as long as they only test predefined macros, not
# stuff from header files).

# Try and get a full POSIX environment on obscure systems.
AC_USE_SYSTEM_EXTENSIONS
AC_SYS_LARGEFILE

# Windows and Cygwin require special treatment in various places.
AC_CACHE_CHECK([for Windows], [ac_cv_sys_win32],
  [AC_PREPROC_IFELSE([AC_LANG_PROGRAM([[
#ifndef _WIN32
#error "not WIN32"
#endif
  ]])], [ac_cv_sys_win32=yes], [ac_cv_sys_win32=no])])
bwin32=$ac_cv_sys_win32

AC_CACHE_CHECK([for Cygwin], [ac_cv_sys_cygwin],
  [AC_PREPROC_IFELSE([AC_LANG_PROGRAM([[
#ifndef __CYGWIN__
#error "not Cygwin"
#endif
  ]])], [ac_cv_sys_cygwin=yes], [ac_cv_sys_cygwin=no])])

AM_CONDITIONAL(BUILD_WIN32, test x$bwin32 = xtrue)
AM_CONDITIONAL(BUILD_CYGWIN, test x$cygwin = xtrue)
AM_CONDITIONAL(BUILD_WITH_NO_UNDEFINED, test x$bwin32 = xtrue || test x$cygwin = xtrue)

# check if we can compile with pthreads
have_pthread=no
if test $bwin32 != yes && test $enable_thread_support = yes; then
  AX_PTHREAD
  if test x$ax_pthread_ok = xyes; then
    have_pthread=yes
    CFLAGS="$CFLAGS $PTHREAD_CFLAGS"
  fi
fi
AM_CONDITIONAL(PTHREAD, [test "$have_pthread" != "no"])

# At least some versions of gcc >=2.95 miscompile the sockaddr code
# with strict aliasing optimizations on.
AX_APPEND_COMPILE_FLAGS([-fno-strict-aliasing])

# GCC's "hardening" options (which defend against various overflows)
if test $enable_gcc_hardening = yes; then
  hflags="-D_FORTIFY_SOURCE=2 -fwrapv -fPIE -fstack-protector-all"
  hflags="$hflags -Wstack-protector --param ssp-buffer-size=1"
  AX_CHECK_COMPILE_FLAG([$hflags],
    [AX_APPEND_FLAG([$hflags])],
    [AC_MSG_ERROR([Hardening requested, but not supported by $CC])])
fi

# Enable basic warnings ...
AX_APPEND_COMPILE_FLAGS([-Wall])

# OS X Lion started deprecating the system openssl. Let's just disable
# all deprecation warnings on OS X.
case "$host_os" in darwin*)
    AX_APPEND_COMPILE_FLAGS([-Wno-deprecated-declarations])
    ;;
esac

# Add some more warnings which we use in development but not in the
# released versions.  (Some relevant gcc versions can't handle these.)
if test $enable_gcc_warnings = yes; then
  # AX_APPEND_COMPILE_FLAGS doesn't detect all of the situations where
  # using a warnings switch is unsafe.
  have_gcc4=no
  have_gcc42=no
  have_gcc45=no
  AC_PREPROC_IFELSE([AC_LANG_PROGRAM([
#if !defined __GNUC__ || __GNUC__ < 4
#error "not GCC >=4.0"
#endif
])], [
  have_gcc4=yes
  AC_PREPROC_IFELSE([AC_LANG_PROGRAM([
#if __GNUC__ == 4 && __GNUC_MINOR__ < 2
#error "not GCC >= 4.2"
#endif
])], [
  have_gcc42=yes
  AC_PREPROC_IFELSE([AC_LANG_PROGRAM([
#if __GNUC__ == 4 && __GNUC_MINOR__ < 5
#error "not GCC >= 4.5"
#endif
])], [
  have_gcc45=yes
])])])

  have_clang=no
  AC_PREPROC_IFELSE([AC_LANG_PROGRAM([
#if !defined(__clang__)
#error "not clang"
#endif
])], [
  have_clang=yes
])

  # These are all known to be unproblematic if supported at all.
  # We'd like to use -Winline but it will break the world on some 64-bit
  # architectures.
  AX_APPEND_COMPILE_FLAGS([ \
    -W \
    -Wbad-function-cast \
    -Wchar-subscripts \
    -Wcomment \
    -Wfloat-equal \
    -Wformat \
    -Wmissing-declarations \
    -Wmissing-prototypes \
    -Wnested-externs \
    -Wpointer-arith \
    -Wredundant-decls \
    -Wstrict-prototypes \
    -Wswitch-enum \
    -Wundef \
    -Wwrite-strings \
    -Wstrict-aliasing \
\
    -Wno-unused-parameter \
  ])

  # These warnings work with gcc 4.0.2 and later
  if test $have_gcc4 = yes; then
    AX_APPEND_COMPILE_FLAGS([ \
      -Winit-self \
      -Wmissing-field-initializers \
      -Wdeclaration-after-statement \
    ])
  fi

  # These warnings work with gcc 4.2 and later
  if test $have_gcc42 = yes; then
    AX_APPEND_COMPILE_FLAGS([-Waddress])
  fi

  # These warnings work with gcc 4.2 and later, but not with clang
  # (which tries to be feature-compatible with gcc).
  if test $have_gcc42 = yes && test $have_clang = no; then
    AX_APPEND_COMPILE_FLAGS([-Wnormalized=id -Woverride-init])
  fi

  # These warnings work with gcc 4.5 and later
  if test $have_gcc45 = yes; then
    AX_APPEND_COMPILE_FLAGS([-Wlogical-op])
  fi

  # Disable unused-function warnings for clang, because they trigger
  # for minheap-internal.h related code.
  if test $have_clang = yes; then
    AX_APPEND_COMPILE_FLAGS([-Wno-unused-function])
  fi
fi

# check if we should enable verbose debugging
if test x$enable_verbose_debug = xyes; then
  CFLAGS="$CFLAGS -DUSE_DEBUG"
fi

dnl Done with everything that messes with CFLAGS (except one, see the
dnl very bottom of the file).

LT_INIT

dnl Checks for libraries.
AC_SEARCH_LIBS([inet_ntoa], [nsl])
AC_SEARCH_LIBS([socket], [socket])
AC_SEARCH_LIBS([clock_gettime], [rt])
AC_SEARCH_LIBS([sendfile], [sendfile])

AC_CHECK_HEADERS([zlib.h], [], [], [AC_INCLUDES_DEFAULT()])

if test "x$ac_cv_header_zlib_h" = "xyes"; then
dnl Determine if we have zlib for regression tests
dnl Don't put this one in LIBS
save_LIBS="$LIBS"
LIBS=""
ZLIB_LIBS=""
have_zlib=no
AC_SEARCH_LIBS([inflateEnd], [z],
	[have_zlib=yes
	ZLIB_LIBS="$LIBS"
	AC_DEFINE(HAVE_LIBZ, 1, [Define if the system has zlib])])
LIBS="$save_LIBS"
AC_SUBST(ZLIB_LIBS)
fi
AM_CONDITIONAL(ZLIB_REGRESS, [test "$have_zlib" = "yes"])

dnl See if we have openssl.  This doesn't go in LIBS either.
if test "$bwin32" = true; then
  EV_LIB_WS32=-lws2_32
  EV_LIB_GDI=-lgdi32
else
  EV_LIB_WS32=
  EV_LIB_GDI=
fi
AC_SUBST(EV_LIB_WS32)
AC_SUBST(EV_LIB_GDI)
AC_SUBST(OPENSSL_LIBADD)

LIBEVENT_OPENSSL

dnl Checks for header files.
AC_CHECK_HEADERS([ \
  arpa/inet.h \
  ifaddrs.h \
  mach/mach_time.h \
  netdb.h \
  netinet/in.h \
  netinet/in6.h \
  netinet/tcp.h \
  sys/devpoll.h \
  sys/epoll.h \
  sys/event.h \
  sys/eventfd.h \
  sys/ioctl.h \
  sys/mman.h \
  sys/param.h \
  sys/queue.h \
  sys/resource.h \
  sys/select.h \
  sys/sendfile.h \
  sys/socket.h \
  sys/time.h \
  sys/timerfd.h \
  sys/uio.h \
  sys/wait.h \
], [], [], [AC_INCLUDES_DEFAULT])

AC_CHECK_HEADERS(sys/sysctl.h, [], [], [
#ifdef HAVE_SYS_PARAM_H
#include <sys/param.h>
#endif
])
if test "x$ac_cv_header_sys_queue_h" = "xyes"; then
	AC_MSG_CHECKING(for TAILQ_FOREACH in sys/queue.h)
	AC_EGREP_CPP(yes,
[
#include <sys/queue.h>
#ifdef TAILQ_FOREACH
 yes
#endif
],	[AC_MSG_RESULT(yes)
	 AC_DEFINE(HAVE_TAILQFOREACH, 1,
		[Define if TAILQ_FOREACH is defined in <sys/queue.h>])],
	AC_MSG_RESULT(no)
	)
fi

if test "x$ac_cv_header_sys_time_h" = "xyes"; then
	AC_MSG_CHECKING(for timeradd in sys/time.h)
	AC_EGREP_CPP(yes,
[
#include <sys/time.h>
#ifdef timeradd
 yes
#endif
],	[ AC_DEFINE(HAVE_TIMERADD, 1,
		[Define if timeradd is defined in <sys/time.h>])
	  AC_MSG_RESULT(yes)] ,AC_MSG_RESULT(no)
)
fi

if test "x$ac_cv_header_sys_time_h" = "xyes"; then
	AC_MSG_CHECKING(for timercmp in sys/time.h)
	AC_EGREP_CPP(yes,
[
#include <sys/time.h>
#ifdef timercmp
 yes
#endif
],	[ AC_DEFINE(HAVE_TIMERCMP, 1,
		[Define if timercmp is defined in <sys/time.h>])
	  AC_MSG_RESULT(yes)] ,AC_MSG_RESULT(no)
)
fi

if test "x$ac_cv_header_sys_time_h" = "xyes"; then
	AC_MSG_CHECKING(for timerclear in sys/time.h)
	AC_EGREP_CPP(yes,
[
#include <sys/time.h>
#ifdef timerclear
 yes
#endif
],	[ AC_DEFINE(HAVE_TIMERCLEAR, 1,
		[Define if timerclear is defined in <sys/time.h>])
	  AC_MSG_RESULT(yes)] ,AC_MSG_RESULT(no)
)
fi

if test "x$ac_cv_header_sys_time_h" = "xyes"; then
	AC_MSG_CHECKING(for timerisset in sys/time.h)
	AC_EGREP_CPP(yes,
[
#include <sys/time.h>
#ifdef timerisset
 yes
#endif
],	[ AC_DEFINE(HAVE_TIMERISSET, 1,
		[Define if timerisset is defined in <sys/time.h>])
	  AC_MSG_RESULT(yes)] ,AC_MSG_RESULT(no)
)
fi

if test "x$ac_cv_header_sys_sysctl_h" = "xyes"; then
	AC_CHECK_DECLS([CTL_KERN, KERN_RANDOM, RANDOM_UUID, KERN_ARND], [], [],
	   [[#include <sys/types.h>
	     #include <sys/sysctl.h>]]
	)
fi

if test x$bwin32 = xtrue; then
   AC_SEARCH_LIBS([getservbyname],[ws2_32])
fi

dnl Checks for typedefs, structures, and compiler characteristics.
AC_C_CONST
AC_C_INLINE
AC_HEADER_TIME

dnl Checks for library functions.
AC_CHECK_FUNCS([ \
  accept4 \
  arc4random \
  arc4random_buf \
  clock_gettime \
  eventfd \
  epoll_create1 \
  getegid \
  geteuid \
  getifaddrs \
  getnameinfo \
  getprotobynumber \
  getservbyname \
  gettimeofday \
  inet_ntop \
  inet_pton \
  issetugid \
  mach_absolute_time \
  mmap \
  nanosleep \
  pipe \
  pipe2 \
  putenv \
  sendfile \
  setenv \
  setrlimit \
  sigaction \
  strsep \
  strtok_r \
  strtoll \
  sysctl \
  timerfd_create \
  umask \
  unsetenv \
  usleep \
  vasprintf \
])

AC_REPLACE_FUNCS([strlcpy])

AC_CACHE_CHECK(
    [for getaddrinfo],
    [libevent_cv_getaddrinfo],
    [AC_LINK_IFELSE(
	[AC_LANG_PROGRAM(
	    [[
		#ifdef HAVE_NETDB_H
		#include <netdb.h>
		#endif
	    ]],
	    [[
		getaddrinfo;
	    ]]
	)],
	[libevent_cv_getaddrinfo=yes],
	[libevent_cv_getaddrinfo=no]
    )]
)
if test "$libevent_cv_getaddrinfo" = "yes" ; then
    AC_DEFINE([HAVE_GETADDRINFO], [1], [Do we have getaddrinfo()?])
else

# Check for gethostbyname_r in all its glorious incompatible versions.
#   (This is cut-and-pasted from Tor, which based its logic on
#   Python's configure.in.)

AC_CHECK_FUNC(gethostbyname_r, [
  AC_MSG_CHECKING([how many arguments gethostbyname_r() wants])
  OLD_CFLAGS=$CFLAGS
  CFLAGS="$CFLAGS $MY_CPPFLAGS $MY_THREAD_CPPFLAGS $MY_CFLAGS"
  AC_COMPILE_IFELSE([AC_LANG_PROGRAM([
#include <netdb.h>
  ], [[
    char *cp1, *cp2;
    struct hostent *h1, *h2;
    int i1, i2;
    (void)gethostbyname_r(cp1,h1,cp2,i1,&h2,&i2);
  ]])],[
    AC_DEFINE(HAVE_GETHOSTBYNAME_R_6_ARG, 1,
     [Define this if gethostbyname_r takes 6 arguments])
    AC_MSG_RESULT(6)
  ], [
    AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
#include <netdb.h>
    ]], [[
      char *cp1, *cp2;
      struct hostent *h1;
      int i1, i2;
      (void)gethostbyname_r(cp1,h1,cp2,i1,&i2);
    ]])],[
      AC_DEFINE(HAVE_GETHOSTBYNAME_R_5_ARG, 1,
        [Define this if gethostbyname_r takes 5 arguments])
      AC_MSG_RESULT(5)
   ],[
      AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
#include <netdb.h>
     ]], [[
       char *cp1;
       struct hostent *h1;
       struct hostent_data hd;
       (void) gethostbyname_r(cp1,h1,&hd);
     ]])], [
       AC_DEFINE(HAVE_GETHOSTBYNAME_R_3_ARG, 1,
         [Define this if gethostbyname_r takes 3 arguments])
       AC_MSG_RESULT(3)
     ], [
       AC_MSG_RESULT(0)
     ])
  ])
 ])
 CFLAGS=$OLD_CFLAGS
])

fi

AC_MSG_CHECKING(for F_SETFD in fcntl.h)
AC_EGREP_CPP(yes,
[
#define _GNU_SOURCE
#include <fcntl.h>
#ifdef F_SETFD
yes
#endif
],	[ AC_DEFINE(HAVE_SETFD, 1,
	      [Define if F_SETFD is defined in <fcntl.h>])
	  AC_MSG_RESULT(yes) ], AC_MSG_RESULT(no))

needsignal=no
haveselect=no
if test x$bwin32 != xtrue; then
    AC_CHECK_FUNCS(select, [haveselect=yes], )
    if test "x$haveselect" = "xyes" ; then
 	needsignal=yes
    fi
fi
AM_CONDITIONAL(SELECT_BACKEND, [test "x$haveselect" = "xyes"])

havepoll=no
AC_CHECK_FUNCS(poll, [havepoll=yes], )
if test "x$havepoll" = "xyes" ; then
	needsignal=yes
fi
AM_CONDITIONAL(POLL_BACKEND, [test "x$havepoll" = "xyes"])

havedevpoll=no
if test "x$ac_cv_header_sys_devpoll_h" = "xyes"; then
	AC_DEFINE(HAVE_DEVPOLL, 1,
		    [Define if /dev/poll is available])
fi
AM_CONDITIONAL(DEVPOLL_BACKEND, [test "x$ac_cv_header_sys_devpoll_h" = "xyes"])

havekqueue=no
if test "x$ac_cv_header_sys_event_h" = "xyes"; then
	AC_CHECK_FUNCS(kqueue, [havekqueue=yes], )
	if test "x$havekqueue" = "xyes" ; then
		AC_MSG_CHECKING(for working kqueue)
		AC_RUN_IFELSE([AC_LANG_SOURCE([[#include <sys/types.h>
#include <sys/time.h>
#include <sys/event.h>
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>

int
main(int argc, char **argv)
{
	int kq;
	int n;
	int fd[2];
	struct kevent ev;
	struct timespec ts;
	char buf[8000];

	if (pipe(fd) == -1)
		exit(1);
	if (fcntl(fd[1], F_SETFL, O_NONBLOCK) == -1)
		exit(1);

	while ((n = write(fd[1], buf, sizeof(buf))) == sizeof(buf))
		;

        if ((kq = kqueue()) == -1)
		exit(1);

	memset(&ev, 0, sizeof(ev));
	ev.ident = fd[1];
	ev.filter = EVFILT_WRITE;
	ev.flags = EV_ADD | EV_ENABLE;
	n = kevent(kq, &ev, 1, NULL, 0, NULL);
	if (n == -1)
		exit(1);

	read(fd[0], buf, sizeof(buf));

	ts.tv_sec = 0;
	ts.tv_nsec = 0;
	n = kevent(kq, NULL, 0, &ev, 1, &ts);
	if (n == -1 || n == 0)
		exit(1);

	exit(0);
}]])],[AC_MSG_RESULT(yes)
    AC_DEFINE(HAVE_WORKING_KQUEUE, 1,
		[Define if kqueue works correctly with pipes])
    havekqueue=yes
    ],[AC_MSG_RESULT(no)],[AC_MSG_RESULT(no)])
	fi
fi
AM_CONDITIONAL(KQUEUE_BACKEND, [test "x$havekqueue" = "xyes"])

haveepollsyscall=no
haveepoll=no
AC_CHECK_FUNCS(epoll_ctl, [haveepoll=yes], )
if test "x$haveepoll" = "xyes" ; then
	AC_DEFINE(HAVE_EPOLL, 1,
		[Define if your system supports the epoll system calls])
	needsignal=yes
fi
if test "x$ac_cv_header_sys_epoll_h" = "xyes"; then
	if test "x$haveepoll" = "xno" ; then
		AC_MSG_CHECKING(for epoll system call)
		AC_RUN_IFELSE([AC_LANG_SOURCE([[#include <stdint.h>
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
	exit (epfd == -1 ? 1 : 0);
}]])],[AC_MSG_RESULT(yes)
    AC_DEFINE(HAVE_EPOLL, 1,
	[Define if your system supports the epoll system calls])
    needsignal=yes
    have_epoll=yes
    AC_LIBOBJ(epoll_sub)
    ],[AC_MSG_RESULT(no)],[AC_MSG_RESULT(no)])
	fi
fi
AM_CONDITIONAL(EPOLL_BACKEND, [test "x$haveepoll" = "xyes"])

haveeventports=no
AC_CHECK_FUNCS(port_create, [haveeventports=yes], )
if test "x$haveeventports" = "xyes" ; then
	AC_DEFINE(HAVE_EVENT_PORTS, 1,
		[Define if your system supports event ports])
	needsignal=yes
fi
AM_CONDITIONAL(EVPORT_BACKEND, [test "x$haveeventports" = "xyes"])

if test "x$bwin32" = "xtrue"; then
	needsignal=yes
fi

AM_CONDITIONAL(SIGNAL_SUPPORT, [test "x$needsignal" = "xyes"])

AC_TYPE_PID_T
AC_TYPE_SIZE_T
AC_TYPE_SSIZE_T

AC_CHECK_TYPES([uint64_t, uint32_t, uint16_t, uint8_t, uintptr_t], , ,
[#ifdef HAVE_STDINT_H
#include <stdint.h>
#elif defined(HAVE_INTTYPES_H)
#include <inttypes.h>
#endif
#include <sys/types.h>])

AC_CHECK_TYPES([fd_mask], , ,
[#include <sys/types.h>
#ifdef HAVE_SYS_SELECT_H
#include <sys/select.h>
#endif])

AC_CHECK_SIZEOF(long long)
AC_CHECK_SIZEOF(long)
AC_CHECK_SIZEOF(int)
AC_CHECK_SIZEOF(short)
AC_CHECK_SIZEOF(size_t)
AC_CHECK_SIZEOF(void *)
AC_CHECK_SIZEOF(off_t)

if test $have_pthread = yes; then
  AC_CHECK_SIZEOF(pthread_t, , [
AC_INCLUDES_DEFAULT
#include <pthread.h>
])
fi

AC_CHECK_TYPES([struct in6_addr,
                struct sockaddr_in6,
                sa_family_t,
                struct addrinfo,
                struct sockaddr_storage], , ,
[#define _GNU_SOURCE
#include <sys/types.h>
#ifdef HAVE_NETINET_IN_H
#include <netinet/in.h>
#endif
#ifdef HAVE_NETINET_IN6_H
#include <netinet/in6.h>
#endif
#ifdef HAVE_SYS_SOCKET_H
#include <sys/socket.h>
#endif
#ifdef HAVE_NETDB_H
#include <netdb.h>
#endif
#ifdef _WIN32
#define WIN32_WINNT 0x400
#define _WIN32_WINNT 0x400
#define WIN32_LEAN_AND_MEAN
#if defined(_MSC_VER) && (_MSC_VER < 1300)
#include <winsock.h>
#else
#include <winsock2.h>
#include <ws2tcpip.h>
#endif
#endif
])
AC_CHECK_MEMBERS([struct sockaddr_in.sin_len,
                  struct sockaddr_in6.sin6_len,
                  struct sockaddr_storage.ss_family,
                  struct sockaddr_storage.__ss_family], , ,
[#include <sys/types.h>
#ifdef HAVE_NETINET_IN_H
#include <netinet/in.h>
#endif
#ifdef HAVE_NETINET_IN6_H
#include <netinet/in6.h>
#endif
#ifdef HAVE_SYS_SOCKET_H
#include <sys/socket.h>
#endif
#ifdef _WIN32
#define WIN32_WINNT 0x400
#define _WIN32_WINNT 0x400
#define WIN32_LEAN_AND_MEAN
#if defined(_MSC_VER) && (_MSC_VER < 1300)
#include <winsock.h>
#else
#include <winsock2.h>
#include <ws2tcpip.h>
#endif
#endif
])

AC_MSG_CHECKING([for socklen_t])
AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
 #include <sys/types.h>
 #include <sys/socket.h>
]],
 [[socklen_t x;]])],
 [AC_MSG_RESULT(yes)],
 [AC_MSG_RESULT([no])
  AC_DEFINE(socklen_t, unsigned int,
            [Define to unsigned int if you dont have it])
])

AC_MSG_CHECKING([whether our compiler supports __func__])
AC_COMPILE_IFELSE([AC_LANG_PROGRAM([],
 [[const char *cp = __func__;]])],
 [AC_MSG_RESULT([yes])],
 [AC_MSG_RESULT([no])
  AC_MSG_CHECKING([whether our compiler supports __FUNCTION__])
  AC_COMPILE_IFELSE([AC_LANG_PROGRAM([],
    [[const char *cp = __FUNCTION__;]])],
    [AC_MSG_RESULT([yes])
     AC_DEFINE(__func__, __FUNCTION__,
         [Define to appropriate substitue if compiler doesnt have __func__])],
    [AC_MSG_RESULT([no])
     AC_DEFINE(__func__, __FILE__,
         [Define to appropriate substitue if compiler doesnt have __func__])])
])

# check if we have and should use openssl
AM_CONDITIONAL(OPENSSL, [test "$enable_openssl" != "no" && test "$have_openssl" = "yes"])

LIBEVENT_GC_SECTIONS=
if test "$GCC" = yes && test "$enable_function_sections" = yes ; then
    AC_CACHE_CHECK(
	[if linker supports omitting unused code and data],
	[libevent_cv_gc_sections_runs],
	[
	    dnl  NetBSD will link but likely not run with --gc-sections
	    dnl  http://bugs.ntp.org/1844
	    dnl  http://gnats.netbsd.org/40401
	    dnl  --gc-sections causes attempt to load as linux elf, with
	    dnl  wrong syscalls in place.  Test a little gauntlet of
	    dnl  simple stdio read code checking for errors, expecting
	    dnl  enough syscall differences that the NetBSD code will
	    dnl  fail even with Linux emulation working as designed.
	    dnl  A shorter test could be refined by someone with access
	    dnl  to a NetBSD host with Linux emulation working.
	    origCFLAGS="$CFLAGS"
	    CFLAGS="$CFLAGS -Wl,--gc-sections"
	    AC_LINK_IFELSE(
		[AC_LANG_PROGRAM(
		    [[
			#include <stdlib.h>
			#include <stdio.h>
		    ]],
		    [[
			FILE *	fpC;
			char	buf[32];
			size_t	cch;
			int	read_success_once;

			fpC = fopen("conftest.c", "r");
			if (NULL == fpC)
				exit(1);
			do {
				cch = fread(buf, sizeof(buf), 1, fpC);
				read_success_once |= (0 != cch);
			} while (0 != cch);
			if (!read_success_once)
				exit(2);
			if (!feof(fpC))
				exit(3);
			if (0 != fclose(fpC))
				exit(4);

			exit(EXIT_SUCCESS);
		    ]]
		)],
		[
                    dnl We have to do this invocation manually so that we can
                    dnl get the output of conftest.err to make sure it doesn't
                    dnl mention gc-sections.
		    if test "X$cross_compiling" = "Xyes" || grep gc-sections conftest.err ; then
			libevent_cv_gc_sections_runs=no
		    else
			libevent_cv_gc_sections_runs=no
			./conftest >/dev/null 2>&1 && libevent_cv_gc_sections_runs=yes
		    fi
		],
		[libevent_cv_gc_sections_runs=no]
	    )
	    CFLAGS="$origCFLAGS"
	    AS_UNSET([origCFLAGS])
	]
    )
    case "$libevent_cv_gc_sections_runs" in
     yes)
	CFLAGS="-ffunction-sections -fdata-sections $CFLAGS"
	LIBEVENT_GC_SECTIONS="-Wl,--gc-sections"
	;;
    esac
fi
AC_SUBST([LIBEVENT_GC_SECTIONS])

# This must be done after everything else, because many of autoconf's
# test programs provoke warnings.
if test $enable_gcc_warnings_are_errors = yes; then
  CFLAGS="$CFLAGS -Werror"
  LTCFLAGS="$LTCFLAGS -Werror"
fi

AC_OUTPUT
