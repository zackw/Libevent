# originally embedded in configure

AC_DEFUN([LIBEVENT_CHECK_GC_SECTIONS],
[AC_LANG_ASSERT([C])
AC_REQUIRE([AC_PROG_GREP])
AC_REQUIRE([AC_PROG_CC])
AC_CACHE_CHECK([whether omitting unused code and data is supported],
                [libevent_cv_gc_sections_runs],
 [#  NetBSD will link but likely not run with --gc-sections
  #  http://bugs.ntp.org/1844
  #  http://gnats.netbsd.org/40401
  #  --gc-sections causes attempt to load as linux elf, with
  #  wrong syscalls in place.  Test a little gauntlet of
  #  simple stdio read code checking for errors, expecting
  #  enough syscall differences that the NetBSD code will
  #  fail even with Linux emulation working as designed.
  #  A shorter test could be refined by someone with access
  #  to a NetBSD host with Linux emulation working.
  libevent_cv_gc_sections_runs="no (cross compiling)"
  AS_IF([test "x$cross_compiling" != xyes], [
    libevent_cv_gc_sections_runs=no
    save_CFLAGS="$CFLAGS"
    CFLAGS="$CFLAGS -ffunction-sections -fdata-sections -Wl,--gc-sections"
    AC_LINK_IFELSE([AC_LANG_PROGRAM([[
      #include <stdio.h>
    ]], [[
      FILE *fpC;
      char buf[32];
      size_t cch;
      int read_success_once = 0;

      fpC = fopen("conftest.c", "r");
      if (!fpC)
        return 1;
      do {
        cch = fread(buf, sizeof(buf), 1, fpC);
        read_success_once |= (cch != 0);
      } while (cch);
      if (!read_success_once)
        return 2;
      if (!feof(fpC))
        return 3;
      if (fclose(fpC))
        return 4;
      return 0;
    ]])], [
      # We have to do this invocation manually so that we can
      # get the output of conftest.err to make sure it doesn't
      # mention sections.
      AS_IF([$GREP sections conftest.err >/dev/null 2>&1],
              [],
            [_AC_DO_TOKENS([./conftest$ac_exeext])],
              [libevent_cv_gc_sections_runs=yes])
    ])
    CFLAGS="$save_CFLAGS"
    AS_UNSET([save_CFLAGS])
])])
LIBEVENT_GC_SECTIONS=
AS_IF([test "$libevent_cv_gc_sections_runs" = yes], [
  CFLAGS="-ffunction-sections -fdata-sections $CFLAGS"
  LIBEVENT_GC_SECTIONS="-Wl,--gc-sections"
])
AC_SUBST([LIBEVENT_GC_SECTIONS])
])
