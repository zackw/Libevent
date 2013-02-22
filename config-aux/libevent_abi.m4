# -*- autoconf -*-
# Copyright 2013 Zack Weinberg <zackw@panix.com>
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# LIBEVENT_MATCH_INTEGER_TYPE(type, size, unsigned,
#                             headers = AC_INCLUDES_DEFAULT,
#                             if-found, if-not-found)
#
#   Identify a built-in integer type compatible with |type|, which is
#   expected to be defined in one of the |headers|.  If a match is
#   found, define the macro TYPEOF_|TYPE| (that is, |type| converted
#   to uppercase) to a suitable 'typedef' definition of |type|, and
#   execute |if-found|.  Within |if-found|, the type chosen is available
#   as ${chosentype}.  Otherwise, execute |if-not-found|.
#
#   If |size| is not empty, it must be a number giving the expected
#   size of the type (in units of |char|).  Only built-in integer
#   types which are known to be that size will be tested.
#
#   If |unsigned| is "yes" or "unsigned", only unsigned types will be
#   tested.  If it is "no" or "signed", only signed types will be
#   tested.  Otherwise, both signed and unsigned types will be tested.

AC_DEFUN([LIBEVENT_MATCH_INTEGER_TYPE],
[AC_REQUIRE([LIBEVENT__MATCH_TYPE_COMMON])dnl
AS_LITERAL_IF(m4_translit([[$1]], [*], [p]), [],
               [m4_fatal([$0: requires literal argument 1])])dnl
dnl Note: deliberate non-quotation of calls to m4_* here so they are
dnl expanded before LIBEVENT_MATCH_INTEGER_TYPE is.
LIBEVENT__MATCH_INTEGER_TYPE([$1],
  m4_default([$2],[X]),
  m4_case([$3], [yes], [u], [unsigned], [u],
                 [no],  [s], [signed],   [s],
                 [],    [X],
     [m4_fatal([$0: invalid argument 3: $3])]),
  m4_default([$4],[AC_INCLUDES_DEFAULT]),
  [$5], [$6])])

AC_DEFUN([LIBEVENT__MATCH_INTEGER_TYPE],
[AS_VAR_PUSHDEF([ev_cv_Type], [libevent_cv_typeof_$1])dnl
AC_CACHE_CHECK([for a built-in type matching $1], [ev_cv_Type], [dnl
  AS_VAR_SET([ev_cv_Type], ["not found"])
  for type in $[]libevent_mi_[]$2[]_[]$3; do
    # $adjtype is $type with underscores replaced by spaces.
    # We have to take care not to mess up __int64 or __int64_t.
    adjtype=`echo $type | sed 's/signed_/signed /g; s/long_long/long long/g'`
    AC_COMPILE_IFELSE([AC_LANG_SOURCE([[
/* Define a typedef for the candidate first.  */
typedef ${adjtype} candidate;
/* These headers should define $1.  */
$4
/* Provoke a compilation error if $1 and ${adjtype} are
   incompatible types.  Declare pointers-to-T rather than T in case
   T happens to be incomplete.  */
extern candidate *var;
$1 *var;
]])], [AS_VAR_SET([ev_cv_Type], [${adjtype}])])
  done])
AS_VAR_IF([ev_cv_Type], ["not found"], [$6], [dnl
  AS_VAR_COPY([chosentype], [ev_cv_Type])
  dnl The AS_TR_CPP on the next line must be unquoted or autoheader will barf.
  AC_DEFINE_UNQUOTED(AS_TR_CPP(TYPEOF_$1), [${chosentype}],
    [Define to a built-in integer type compatible with $1.])
$5])
AS_VAR_POPDEF([ev_cv_Type])dnl
])

# LIBEVENT__MATCH_TYPE_COMMON
# Subroutine of LIBEVENT_MATCH_*_TYPE.  Do not use directly, but
# you may rely on it doing the checks you see here.

AC_DEFUN([LIBEVENT__MATCH_TYPE_COMMON],
[AC_CHECK_SIZEOF([short])
AC_CHECK_SIZEOF([int])
AC_CHECK_SIZEOF([long])
AC_CHECK_SIZEOF([long long])
dnl Possible alternative spellings of a 64-bit type.  AC_CHECK_SIZEOF
dnl will set SIZEOF_whatever to zero if the type is invalid.
AC_CHECK_SIZEOF([__int64_t])
AC_CHECK_SIZEOF([__int64])
dnl It is useful to be able to compare sizes to these.
AC_CHECK_SIZEOF([void *])
AC_CHECK_SIZEOF([size_t], [#include <stddef.h>])
AC_CHECK_SIZEOF([ptrdiff_t], [#include <stddef.h>])

# Rumor has it that some openbsd autoconf versions get the name of
# this macro wrong.
if test x"$ac_cv_sizeof_void_p" = x &&
   test x"$ac_cv_sizeof_void__" != x; then
  ac_cv_sizeof_void_p=$ac_cv_sizeof_void__
  AC_DEFINE_UNQUOTED(SIZEOF_VOID_P, $ac_cv_sizeof_void_p,
    [The size of `void *', as computed by sizeof.])
fi

# sizeof(char) is 1 by definition
libevent_mi_1_X="char unsigned_char signed_char"
libevent_mi_1_s="char signed_char"
libevent_mi_1_u="unsigned_char char"

libevent_mi_X_X="${libevent_mi_1_X}"
libevent_mi_X_s="${libevent_mi_1_s}"
libevent_mi_X_u="${libevent_mi_1_u}"

for type in short int long long_long; do
  AS_VAR_IF([ac_cv_sizeof_${type}], [0], , [
    AS_VAR_COPY([size], [ac_cv_sizeof_${type}])
    AS_VAR_APPEND([libevent_mi_${size}_X], [" ${type}"])
    AS_VAR_APPEND([libevent_mi_${size}_s], [" ${type}"])
    AS_VAR_APPEND([libevent_mi_${size}_u], [" unsigned_${type}"])
    AS_VAR_APPEND([libevent_mi_X_X], [" ${type} unsigned_${type}"])
    AS_VAR_APPEND([libevent_mi_X_s], [" ${type}"])
    AS_VAR_APPEND([libevent_mi_X_u], [" unsigned_${type}"])
  ])
done
# Log results of all the above.
for size in 1 2 3 4 5 6 7 8 X; do
  for sign in s u X; do
    AS_VAR_SET_IF([libevent_mi_${size}_${sign}], [
      AS_VAR_COPY([temp], [libevent_mi_${size}_${sign}])
      AS_ECHO(["$as_me: libevent_mi_${size}_${sign}=$temp"]) >&AS_MESSAGE_LOG_FD
    ])
  done
done
])
