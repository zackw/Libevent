m4_define([m4_shvar], [m4_translit([$1], [-+.], [___])])

# Shorthands for the way we use AC_ARG_ENABLE.
AC_DEFUN([LIBEVENT_ENABLE],
[AC_ARG_ENABLE([$1],
  [AS_HELP_STRING([--enable-$1], [enable $2])],
  [if test x$enableval != xyes && test x$enableval != xno; then
     AC_MSG_ERROR([invalid argument "$enableval" to --enable-$1])
   fi],
  [m4_shvar([enable_$1])=no])])

AC_DEFUN([LIBEVENT_DISABLE],
[AC_ARG_ENABLE([$1],
  [AS_HELP_STRING([--disable-$1], [disable $2])],
  [if test x$enableval != xyes && test x$enableval != xno; then
     AC_MSG_ERROR([invalid argument "$enableval" to --disable-$1])
   fi],
  [m4_shvar([enable_$1])=yes])])

# Backend selection.

# This macro is separate from LIBEVENT_BACKEND_PREP so it can be
# invoked up top with the other option declarations (and, perhaps even
# more important, so that the AC_MSG_ERROR happens, if it's going to
# happen, *before* we spend a few seconds analyzing the system).
# It depends on data posted into the DEFAULTS diversion by
# LIBEVENT_FINALIZE_BACKENDS.

AC_DEFUN([LIBEVENT_ENABLE_BACKENDS],
[AC_ARG_ENABLE([backends],
  [AS_HELP_STRING([--enable-backends=...],
                  [comma-separated list of event backends to include in
                   the library, if supported by the target OS])],
  [for backend in `echo $enable_backends | tr ',' ' '`; do
     AS_CASE([,$all_backends,], [*,$backend,*], [],
             [AC_MSG_ERROR([backend $backend not supported by libevent])])
   done],
  [enable_backends=$all_backends])])

# This macro is invoked automatically by the first occurrence of
# LIBEVENT_BACKEND.

AC_DEFUN([LIBEVENT_BACKEND_PREP],
[backend_need_signal=no
 usable_backends=
 selected_backends=
])

# LIBEVENT_BACKEND([name], [conditional], [needs-signal])
AC_DEFUN([LIBEVENT_BACKEND],
[AC_BEFORE([LIBEVENT_FINALIZE_BACKENDS])dnl
AC_REQUIRE([LIBEVENT_BACKEND_PREP])dnl
AC_REQUIRE([LIBEVENT_ENABLE_BACKENDS])dnl just in case
m4_set_add([libevent_backend_set], [$1], , [m4_fatal([duplicate backend: $1])])
m4_shvar([backend_$1])=no
AS_IF([$2],
  [usable_backends="$usable_backends $1"
   AS_CASE([,$enable_backends,], [*,$1,*],
    [selected_backends="$selected_backends $1"
     m4_shvar([backend_$1])=yes
     m4_ifvaln([$3], [backend_need_signal=yes])dnl
     AC_DEFINE(BACKEND_[]m4_toupper($1), [1],
               [Define to enable the $1 backend.])])])
AM_CONDITIONAL(BACKEND_[]m4_toupper($1), [test $[]m4_shvar([backend_$1]) = yes])
])

# This macro must appear after all LIBEVENT_BACKEND macros.
AC_DEFUN([LIBEVENT_FINALIZE_BACKENDS],
[m4_divert_text([DEFAULTS],
  [all_backends=m4_set_contents([libevent_backend_set],[,])])
m4_divert_text([HELP_ENABLE],
  [    (choose from: m4_set_contents([libevent_backend_set],[ ]))])
AM_CONDITIONAL(BACKEND_NEED_SIGNAL, [test $backend_need_signal = yes])
AS_IF([test $backend_need_signal = yes],
 [AC_DEFINE([BACKEND_NEED_SIGNAL], [1],
            [Define if any backends need the generic signal helpers.])
])
AS_IF([test "x$selected_backends" != x],
  [AC_MSG_NOTICE([libevent will include these backends:$selected_backends])],
  [enable_backends_s=`echo $enable_backends | tr ',' ' '`
   AC_MSG_NOTICE([Event backends enabled: $enable_backends_s])
   AC_MSG_NOTICE([Event backends supported by $host_os:$usable_backends])
   AC_MSG_ERROR([No OS-supported event backends are enabled])])
])
