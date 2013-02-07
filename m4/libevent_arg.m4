# Shorthands for the way we use AC_ARG_ENABLE.
AC_DEFUN([LIBEVENT_ENABLE],
[AC_ARG_ENABLE([$1],
  [AS_HELP_STRING([--enable-$1], [enable $2])],
  [if test x$enableval != xyes && test x$enableval != xno; then
     AC_MSG_ERROR([invalid argument "$enableval" to --enable-$1])
   fi],
  [enable_[]m4_translit([$1], [-+.], [___])=no])])

AC_DEFUN([LIBEVENT_DISABLE],
[AC_ARG_ENABLE([$1],
  [AS_HELP_STRING([--disable-$1], [disable $2])],
  [if test x$enableval != xyes && test x$enableval != xno; then
     AC_MSG_ERROR([invalid argument "$enableval" to --disable-$1])
   fi],
  [enable_[]m4_translit([$1], [-+.], [___])=yes])])
