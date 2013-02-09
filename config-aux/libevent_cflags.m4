# SYNOPSIS
#
#   LIBEVENT_ADD_CFLAGS(flag1 flag2 ..., [label])
#
# DESCRIPTION
#
#   Test each FLAG individually to see if the compiler accepts it.  The
#   test is done with AC_COMPILE_IFELSE([AC_LANG_PROGRAM]).  All of the
#   acceptable flags are appended to the current language's default flags
#   variable (e.g. CFLAGS).
#
#   LABEL, if present, is used in the "checking ..." message.  Only one
#   message is printed per invocation of LIBEVENT_ADD_CFLAGS.
#
# LICENSE
#
#   Based on AX_APPEND_COMPILE_FLAGS, AX_CHECK_COMPILE_FLAG, and
#   AX_APPEND_FLAG, by Maarten Bosnans.  Therefore:
#
#   Copyright (c) 2011 Maarten Bosmans <mkbosmans@gmail.com>
#   Copyright (c) 2013 Zack Weinberg <zackw@panix.com>
#
#   This program is free software: you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the
#   Free Software Foundation, either version 3 of the License, or (at your
#   option) any later version.
#
#   This program is distributed in the hope that it will be useful, but
#   WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
#   Public License for more details.
#
#   You should have received a copy of the GNU General Public License along
#   with this program. If not, see <http://www.gnu.org/licenses/>.
#
#   As a special exception, the respective Autoconf Macro's copyright owner
#   gives unlimited permission to copy, distribute and modify the configure
#   scripts that are the output of Autoconf when processing the Macro. You
#   need not follow the terms of the GNU General Public License when using
#   or distributing such scripts, even though portions of the text of the
#   Macro appear in them. The GNU General Public License (GPL) does govern
#   all other use of the material that constitutes the Autoconf Macro.
#
#   This special exception to the GPL applies to versions of the Autoconf
#   Macro released by the Autoconf Archive. When you make and distribute a
#   modified version of the Autoconf Macro, you may extend this special
#   exception to the GPL to apply to your modified version as well.

#serial 1

AC_DEFUN([LIBEVENT_ADD_CFLAGS],
[m4_ifnblank($2,
 [AC_MSG_CHECKING([$1 flags supported by $[]_AC_CC])],
 [m4_bmatch($1, [ ],
   [AC_MSG_CHECKING([flags supported by $[]_AC_CC])],
   [AC_MSG_CHECKING([whether $[]_AC_CC supports $1])])])
_save_flags="$[]_AC_LANG_PREFIX[]FLAGS"
_good_flags=
for flag in m4_ifnblank($2, $2, $1); do
  # for clang, need -Werror to catch unsupported flags
  _AC_LANG_PREFIX[]FLAGS="-Werror $flag"
  AC_COMPILE_IFELSE([AC_LANG_PROGRAM()],
    [_good_flags="$_good_flags${_good_flags:+ }$flag"])
done
_AC_LANG_PREFIX[]FLAGS="$_save_flags"
AS_IF([test x"$_good_flags" = x""],
  [m4_ifnblank($2,
    [AC_MSG_RESULT([none])],
    [m4_bmatch($1, [ ],
      [AC_MSG_RESULT([none])],
      [AC_MSG_RESULT([no])])])],
  [m4_ifnblank($2,
    [AC_MSG_RESULT([$_good_flags])],
    [m4_bmatch($1, [ ],
      [AC_MSG_RESULT([$_good_flags])],
      [AC_MSG_RESULT([yes])])])
   _AC_LANG_PREFIX[]FLAGS="$[]_AC_LANG_PREFIX[]FLAGS${[]_AC_LANG_PREFIX[]FLAGS[]:+ }$_good_flags"])
AS_UNSET([_save_flags])
AS_UNSET([_good_flags])
])
