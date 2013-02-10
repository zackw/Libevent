# Complicated checks for libraries -- anything that can't be handled with
# AC_SEARCH_LIBS.

# zlib support (only used for regression tests)
AC_DEFUN([LIBEVENT_ZLIB], [
if test "${ac_cv_header_zlib_h+set}" != set; then
  AC_CHECK_HEADERS([zlib.h])
fi
if test $ac_cv_header_zlib_h = yes; then
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
])

# OpenSSL support
AC_DEFUN([LIBEVENT_OPENSSL], [
AC_REQUIRE([PKG_PROG_PKG_CONFIG])dnl
AC_ARG_VAR([OPENSSL_LIBADD])
have_openssl=no
OPENSSL_LIBS=
OPENSSL_INCS=
if test $enable_openssl = yes; then
  if test $ac_cv_sys_win32 = yes; then
    OPENSSL_WIN32=" -lgdi32 -lws2_32"
  else
    OPENSSL_WIN32=
  fi
  AS_VAR_SET_IF([PKG_CONFIG],
   [OPENSSL_INCS=`$PKG_CONFIG --cflags openssl 2>/dev/null | $SED -e 's/^ *//; s/ *$//'`
    OPENSSL_LIBS=`$PKG_CONFIG --libs openssl 2>/dev/null | $SED -e 's/^ *//; s/ *$//'`
     AS_VAR_SET_IF([OPENSSL_LIBS],
      [OPENSSL_LIBS="$OPENSSL_LIBS$OPENSSL_WIN32${OPENSSL_LIBADD:+ }$OPENSSL_LIBADD"
       have_openssl=yes])])
  if test $have_openssl = no; then
    save_LIBS="$LIBS"
    LIBS=
    AC_SEARCH_LIBS([SSL_new], [ssl],
     [have_openssl=yes
      OPENSSL_LIBS="$LIBS${LIBS:+ }-lcrypto$OPENSSL_WIN32${OPENSSL_LIBADD:+ }$OPENSSL_LIBADD"],
     [have_openssl=no],
     [-lcrypto $OPENSSL_WIN32 $OPENSSL_LIBADD])
    LIBS="$save_LIBS"
  fi
  dnl This is down here so it doesn't get interrupted by AC_SEARCH_LIBS.
  AC_MSG_CHECKING([for openssl])
  if test $have_openssl = yes; then
    AC_MSG_RESULT([$OPENSSL_INCS${OPENSSL_INCS:+ }$OPENSSL_LIBS])
    AC_DEFINE(HAVE_OPENSSL, 1, [Define if the system has openssl])
  else
    AC_MSG_RESULT([no])
  fi
fi
AM_CONDITIONAL(OPENSSL, [test $have_openssl = yes])
AC_SUBST(OPENSSL_LIBS)
AC_SUBST(OPENSSL_INCS)
])
