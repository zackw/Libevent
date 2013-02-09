AC_DEFUN([LIBEVENT_HARDENING_CFLAGS], [
AS_VAR_IF([$1], [yes],
  [LIBEVENT_ADD_CFLAGS([hardening],
    [-D_FORTIFY_SOURCE=2 -fwrapv -fPIE -fstack-protector-all \
     -Wstack-protector '--param ssp-buffer-size=1'])
])])

AC_DEFUN([LIBEVENT_WARNING_CFLAGS], [
AS_VAR_IF([GCC], [yes], [
  warnings_flags="-Wall"

  # OS X Lion started deprecating the system openssl. Let's just disable
  # all deprecation warnings on OS X.
  AS_CASE([$host_os], [darwin*],
      [warnings_flags="$warnings_flags -Wno-deprecated-declarations"])

  # Add some more warnings which we use in development but not in the
  # released versions.  (Some relevant gcc versions can't handle these.)
  AS_VAR_IF([$1], [yes], [
    # These are all known to be unproblematic if supported at all.
    # We'd like to use -Winline but it will break the world on some 64-bit
    # architectures.
    warnings_flags="$warnings_flags \
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
      -Wno-unused-parameter"

    # LIBEVENT_ADD_CFLAGS doesn't detect all of the situations where
    # using a warnings switch is unsafe.
    # gcc has supported -dumpversion since 1.x, and clang knows it too.
    gcc_version=`$CC -dumpversion`

    have_gcc4=yes
    AS_VERSION_COMPARE([$gcc_version], [4.0], [have_gcc4=no])

    have_gcc42=yes
    AS_VERSION_COMPARE([$gcc_version], [4.2], [have_gcc42=no])

    have_gcc45=yes
    AS_VERSION_COMPARE([$gcc_version], [4.5], [have_gcc45=no])

    have_clang=no
    AC_PREPROC_IFELSE([AC_LANG_PROGRAM([
#if !defined(__clang__)
#error "not clang"
#endif
])], [
    have_clang=yes
])

    # These warnings work with gcc 4.0.2 and later
    if test $have_gcc4 = yes; then
      warnings_flags="$warnings_flags \
        -Winit-self \
        -Wmissing-field-initializers \
        -Wdeclaration-after-statement"
    fi

    # These warnings work with gcc 4.2 and later
    if test $have_gcc42 = yes; then
      warnings_flags="$warnings_flags -Waddress"
    fi

    # These warnings work with gcc 4.2 and later, but not with clang
    # (which tries to be feature-compatible with gcc).
    if test $have_gcc42 = yes && test $have_clang = no; then
      warnings_flags="$warnings_flags -Wnormalized=id -Woverride-init"
    fi

    # These warnings work with gcc 4.5 and later
    if test $have_gcc45 = yes; then
      warnings_flags="$warnings_flags -Wlogical-op"
    fi

    # Disable unused-function warnings for clang, because they trigger
    # for minheap-internal.h related code.
    if test $have_clang = yes; then
      warnings_flags="$warnings_flags -Wno-unused-function"
    fi
  LIBEVENT_ADD_CFLAGS([warnings], [$warnings_flags])
])])])

AC_DEFUN([LIBEVENT_WARNINGS_ARE_ERRORS], [
AS_VAR_IF([$1], [yes], [
  CFLAGS="$CFLAGS -Werror"
  LTCFLAGS="$LTCFLAGS -Werror"
])])
