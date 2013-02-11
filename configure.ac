dnl Copyright 2000-2007 Niels Provos
dnl Copyright 2007-2012 Niels Provos and Nick Mathewson
dnl
dnl See LICENSE for copying information.
dnl
dnl Original version Dug Song <dugsong@monkey.org>

dnl we use lots of custom macros beginning with this prefix
m4_pattern_forbid([LIBEVENT_])dnl

AC_INIT([libevent],[2.1.2-alpha-dev])
AC_DEFINE(NUMERIC_VERSION, 0x02010201, [Numeric representation of the version])

AC_PREREQ([2.59])
AC_CONFIG_SRCDIR(event.c)
AC_CONFIG_AUX_DIR([config-aux])
AC_CONFIG_MACRO_DIR([config-aux])
AC_CONFIG_HEADERS([config.h  evconfig-private.h:evconfig-private.h.in])
AC_CONFIG_FILES([libevent.pc libevent_openssl.pc libevent_pthreads.pc
                 Makefile])

# Additional configure option processing.
LIBEVENT_DISABLE([extra-warnings],
                 [additional warnings from GCC])
LIBEVENT_ENABLE( [warnings-are-errors],
                 [making warnings into errors])
LIBEVENT_ENABLE( [hardening],
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

LIBEVENT_ENABLE_BACKENDS

# Further initialization.  AM_INIT_AUTOMAKE has to go before any
# use of AM_CONDITIONAL, but does slow tests and therefore should go
# after all command line validation.
AM_INIT_AUTOMAKE
dnl AM_SILENT_RULES req. automake 1.11.  [no] defaults V=1
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

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

AC_CACHE_CHECK([for Cygwin], [ac_cv_sys_cygwin],
  [AC_PREPROC_IFELSE([AC_LANG_PROGRAM([[
#ifndef __CYGWIN__
#error "not Cygwin"
#endif
  ]])], [ac_cv_sys_cygwin=yes], [ac_cv_sys_cygwin=no])])

AM_CONDITIONAL(BUILD_WIN32, test $ac_cv_sys_win32 = yes)
AM_CONDITIONAL(BUILD_CYGWIN, test $ac_cv_sys_cygwin = yes)
AM_CONDITIONAL(BUILD_WITH_NO_UNDEFINED,
 [test $ac_cv_sys_cygwin = yes || test $ac_cv_sys_cygwin = yes])

# check if we can compile with pthreads
have_pthread=no
if test $ac_cv_sys_win32 != yes && test $enable_thread_support = yes; then
  AX_PTHREAD
  if test x$ax_pthread_ok = xyes; then
    have_pthread=yes
    CFLAGS="$CFLAGS $PTHREAD_CFLAGS"
  fi
fi
AM_CONDITIONAL(PTHREAD, [test "$have_pthread" != "no"])

# At least some versions of gcc >=2.95 miscompile the sockaddr code
# with strict aliasing optimizations on.
LIBEVENT_ADD_CFLAGS([-fno-strict-aliasing])

# GCC's "hardening" options (which defend against various overflows)
LIBEVENT_HARDENING_CFLAGS([enable_hardening])

# Warnings, and lots of them.
LIBEVENT_WARNING_CFLAGS([enable_extra_warnings])

# Verbose debugging
if test x$enable_verbose_debug = xyes; then
  CFLAGS="$CFLAGS -DUSE_DEBUG"
fi

# Section-per-function for smaller static builds
LIBEVENT_FUNCTION_SECTIONS([enable_function_sections])

dnl Done with everything that messes with CFLAGS (except one, see the
dnl very bottom of the file).
LT_INIT

# Checks for characteristics of the compiler.
AC_C_INLINE
LIBEVENT_CURRENT_FUNCTION_NAME

# Checks for header files.
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
  sys/resource.h \
  sys/select.h \
  sys/sendfile.h \
  sys/socket.h \
  sys/time.h \
  sys/timerfd.h \
  sys/uio.h \
  sys/wait.h \
  zlib.h \
], [], [], [AC_INCLUDES_DEFAULT])

# sys/sysctl.h may need prior inclusion of sys/param.h.
AC_CHECK_HEADERS(sys/sysctl.h, [], [], [
#ifdef HAVE_SYS_PARAM_H
#include <sys/param.h>
#endif
])

# Checks for contents of header files.
if test "x$ac_cv_header_sys_time_h" = xyes; then
  AC_CHECK_DECLS([timeradd, timerclear, timerisset], [], [],
                 [#include <sys/time.h>])
fi

if test "x$ac_cv_header_sys_sysctl_h" = xyes; then
  AC_CHECK_DECLS([CTL_KERN, KERN_RANDOM, RANDOM_UUID, KERN_ARND], [], [], [
  #include <sys/types.h>
  #ifdef HAVE_SYS_PARAM_H
  #include <sys/param.h>
  #endif
  #include <sys/sysctl.h>
])
fi

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

AC_CHECK_TYPES([sa_family_t,
                socklen_t,
                struct addrinfo,
                struct in6_addr,
                struct sockaddr_in6,
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

# Checks for library functions.
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
  poll \
  port_create \
  putenv \
  select \
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

LIBEVENT_FUNC_GETADDRINFO
LIBEVENT_FUNC_GETHOSTBYNAME_R
LIBEVENT_FUNC_KQUEUE_WORKS
LIBEVENT_FUNC_EPOLL

# Checks for libraries.
AC_SEARCH_LIBS([inet_ntoa], [nsl])
AC_SEARCH_LIBS([socket], [socket])
AC_SEARCH_LIBS([clock_gettime], [rt])
AC_SEARCH_LIBS([sendfile], [sendfile])

if test $ac_cv_sys_win32 = yes; then
  AC_SEARCH_LIBS([getservbyname],[ws2_32])
fi

LIBEVENT_ZLIB
LIBEVENT_OPENSSL

# Backend selection.  Done after all probes, since it depends on the
# results of many probes.

LIBEVENT_BACKEND([select],
  [test $ac_cv_sys_win32 = no && test $ac_cv_func_select = yes],
  [needsignal])

LIBEVENT_BACKEND([poll],    [test $ac_cv_func_poll = yes], [needsignal])
LIBEVENT_BACKEND([devpoll], [test $ac_cv_header_sys_devpoll_h = yes])
LIBEVENT_BACKEND([evport],  [test $ac_cv_func_port_create = yes])
LIBEVENT_BACKEND([kqueue],  [test $libevent_cv_func_kqueue_works = yes], [needsignal])
LIBEVENT_BACKEND([epoll],   [test $libevent_have_epoll = yes], [needsignal])
LIBEVENT_BACKEND([win32],   [test $ac_cv_sys_win32 = yes], [needsignal])

LIBEVENT_FINALIZE_BACKENDS

# This must be done after everything else, because many of autoconf's
# test programs provoke warnings.
LIBEVENT_WARNINGS_ARE_ERRORS([enable_warnings_are_errors])

AC_OUTPUT
