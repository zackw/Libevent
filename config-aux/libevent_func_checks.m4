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
