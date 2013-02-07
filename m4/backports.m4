dnl Backports of autoconf >=2.60 functionality for autoconf 2.59's sake.

dnl Even in the very latest autoconf, AC_INCLUDES_DEFAULT does a bunch
dnl of checks for pre-C89 stuff, which is now completely unnecessary.
dnl (sys/types.h and sys/stat.h are POSIX, not C89, so you might
dnl suspect them of not being ubiquitous, but in fact they are.
dnl However, regrettably, stdint.h, inttypes.h, and unistd.h still
dnl have to be checked for.)
m4_undefine([_AC_INCLUDES_DEFAULT_REQUIREMENTS])dnl
AC_DEFUN([_AC_INCLUDES_DEFAULT_REQUIREMENTS],
[m4_divert_text([DEFAULTS],
[# Factoring default headers for most tests.
dnl If ever you change this variable, please keep autoconf.texi in sync.
ac_includes_default="\
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#ifdef HAVE_INTTYPES_H
# include <inttypes.h>
#endif
#ifdef HAVE_STDINT_H
# include <stdint.h>
#endif
#ifdef HAVE_UNISTD_H
# include <unistd.h>
#endif"
])dnl
AC_CHECK_HEADERS([inttypes.h stdint.h unistd.h], [], [], [$ac_includes_default])])

dnl This has a bugfix in it that has not yet made it to autoconf mainline.
m4_undefine([AC_USE_SYSTEM_EXTENSIONS])
AC_DEFUN_ONCE([AC_USE_SYSTEM_EXTENSIONS],
[AC_BEFORE([$0], [AC_COMPILE_IFELSE])dnl
AC_BEFORE([$0], [AC_RUN_IFELSE])dnl

  AC_CHECK_HEADER([minix/config.h], [MINIX=yes], [MINIX=], [AC_INCLUDES_DEFAULT])
  if test "$MINIX" = yes; then
    AC_DEFINE([_POSIX_SOURCE], [1],
      [Define to 1 if you need to in order for `stat' and other
       things to work.])
    AC_DEFINE([_POSIX_1_SOURCE], [2],
      [Define to 2 if the system does not provide POSIX.1 features
       except with this defined.])
    AC_DEFINE([_MINIX], [1],
      [Define to 1 if on MINIX.])
  fi

dnl Use a different key than __EXTENSIONS__, as that name broke existing
dnl configure.ac when using autoheader 2.62.
  AH_VERBATIM([USE_SYSTEM_EXTENSIONS],
[/* Enable extensions on AIX 3, Interix.  */
#ifndef _ALL_SOURCE
# undef _ALL_SOURCE
#endif
/* Enable GNU extensions on systems that have them.  */
#ifndef _GNU_SOURCE
# undef _GNU_SOURCE
#endif
/* Enable threading extensions on Solaris.  */
#ifndef _POSIX_PTHREAD_SEMANTICS
# undef _POSIX_PTHREAD_SEMANTICS
#endif
/* Enable extensions on HP NonStop.  */
#ifndef _TANDEM_SOURCE
# undef _TANDEM_SOURCE
#endif
/* Enable general extensions on Solaris.  */
#ifndef __EXTENSIONS__
# undef __EXTENSIONS__
#endif
])
  AC_CACHE_CHECK([whether it is safe to define __EXTENSIONS__],
    [ac_cv_safe_to_define___extensions__],
    [AC_COMPILE_IFELSE(
       [AC_LANG_PROGRAM([[
#         define __EXTENSIONS__ 1
          ]AC_INCLUDES_DEFAULT])],
       [ac_cv_safe_to_define___extensions__=yes],
       [ac_cv_safe_to_define___extensions__=no])])
  test $ac_cv_safe_to_define___extensions__ = yes &&
    AC_DEFINE([__EXTENSIONS__])
  AC_DEFINE([_ALL_SOURCE])
  AC_DEFINE([_GNU_SOURCE])
  AC_DEFINE([_POSIX_PTHREAD_SEMANTICS])
  AC_DEFINE([_TANDEM_SOURCE])
])# AC_USE_SYSTEM_EXTENSIONS
])

m4_ifdef([AC_TYPE_SSIZE_T], , [
AN_IDENTIFIER([ssize_t], [AC_TYPE_SSIZE_T])
AC_DEFUN([AC_TYPE_SSIZE_T], [AC_CHECK_TYPE(ssize_t, int)])
])
