# -*- autoconf -*-
# Copyright 2013 Zack Weinberg <zackw@panix.com>
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# LIBEVENT_MATCH_INTEGER_TYPE(type, size, signedness,
#                             headers = AC_INCLUDES_DEFAULT,
#                             [description])
#
#   Identify a built-in integer type compatible with |type|, which is
#   expected to be defined in one of the |headers|.  If a match is
#   found, define the macro TYPEOF_|TYPE| (that is, |type| converted
#   to uppercase) to a suitable 'typedef' definition of |type|.
#
#   |size| and |signedness| describe your expectations of the type:
#   its size in units of `char`, and its signedness, respectively.
#   |size| must be a positive integer or a shell construct that
#   expands to a positive integer, and |signedness| must be one of the
#   keywords "signed" or "unsigned", or a shell construct that expands
#   to one of those keywords.  Only types which conform to those
#   expectations will be tested.  Further, if a match is not found
#   (for instance, if |type| was not declared as expected),
#   TYPEOF_|TYPE| will be set to some type which meets those
#   expectations.  If no such type is known, `configure` will fail.
#
#   The optional final argument |description| is used to describe the
#   fallback type in config.h.in.  If you don't provide it, the
#   default is "a |size|-byte |signedness| integer type"; if either
#   |size| or |signedness| is a shell construct, this is probably not
#   what you want.

AC_DEFUN([LIBEVENT_MATCH_INTEGER_TYPE],
[AC_REQUIRE([LIBEVENT__MATCH_TYPE_COMMON])dnl
AS_LITERAL_IF(m4_translit([[$1]], [*], [p]), [],
               [m4_fatal([$0: requires literal argument 1])])dnl
dnl Note deliberate non-quotation of call to m4_default here, so it is
dnl expanded before LIBEVENT_MATCH_INTEGER_TYPE is.
LIBEVENT__MATCH_INTEGER_TYPE([$1], [$2], [$3],
                     m4_default_nblank([$4], [AC_INCLUDES_DEFAULT]),
                     m4_default_nblank([$5], [a $2-byte $3 integer type]))dnl
])

AC_DEFUN([LIBEVENT__MATCH_INTEGER_TYPE], [dnl
AS_VAR_PUSHDEF([ev_cv_Type], [libevent_cv_typeof_$1])dnl
ev_size=$2
ev_sign=$3
AS_CASE([$ev_sign], [signed], [ev_sign=s],
                    [unsigned], [ev_sign=u], [dnl
  # This error message requires unusual quotation, since we wish to
  # show both the literal and the evaluated forms of argument 3.
  ev_errmsg=["invalid argument 3: '"'$3'"' = $ev_sign"]
  AC_MSG_ERROR([$ev_errmsg])])
AS_VAR_PUSHDEF([ev_Candidates], [libevent_mi_${ev_size}_${ev_sign}])
AS_VAR_IF([ev_Candidates], [], [dnl
  { AS_ECHO(["$as_me:${as_lineno-$LINENO}: libevent_mi_${ev_size}_${ev_sign} not set"])
    AS_ECHO(["$as_me:${as_lineno-$LINENO}: see above for known integer types"])
  } >&AS_MESSAGE_LOG_FD
  AC_MSG_FAILURE([no known integer types are $2 bytes wide and $3])])
AC_CACHE_CHECK([for a built-in type matching $1], [ev_cv_Type], [dnl
  ev_first_adjtype=
  AS_VAR_COPY([ev_candidates], [ev_Candidates])
  for ev_type in $ev_candidates; do
    # $ev_adjtype is $ev_type with underscores replaced by spaces.
    # We have to take care not to mess up __int64 or __int64_t.
    ev_adjtype=`echo $ev_type |
      sed 's/signed_/signed /g; s/long_long/long long/g'`
    if test "x$ev_first_adjtype" = x; then
      ev_first_adjtype="$ev_adjtype"
    fi
    AS_ECHO(["$as_me:${as_lineno-$LINENO}: trying $ev_adjtype"]) >&AS_MESSAGE_LOG_FD
    AC_COMPILE_IFELSE([AC_LANG_SOURCE([[
/* Define a typedef for the candidate first.  */
typedef ${ev_adjtype} candidate;
/* These headers should define $1.  */
$4
/* Provoke a compilation error if $1 and ${adjtype} are
   incompatible types.  Declare pointers-to-T rather than T in case
   T happens to be incomplete.  */
extern candidate *var;
$1 *var;
]])], [AS_VAR_SET([ev_cv_Type], [${ev_adjtype}])
       break])
  done
  AS_VAR_SET_IF([ev_cv_Type], [],
    [AS_VAR_SET([ev_cv_Type], ["$ev_first_adjtype (default)"])])
])
AS_VAR_COPY([ev_chosentype], [ev_cv_Type])
AS_CASE([${ev_chosentype}], [*\ \(default\)],
        [ev_chosentype=`echo "$ev_chosentype" | sed 's/ (default)//'`])
dnl The AS_TR_CPP on the next line must be unquoted or autoheader will barf.
AC_DEFINE_UNQUOTED(AS_TR_CPP(TYPEOF_$1), [$ev_chosentype],
  [A built-in integer type compatible with `$1'.
   If this system's headers do not define `$1', $5.])
AS_VAR_POPDEF([ev_cv_Type])dnl
AS_VAR_POPDEF([ev_Candidates])dnl
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

# Rumor has it that some openbsd autoconf versions get the name of
# this macro wrong.
if test x"$ac_cv_sizeof_void_p" = x &&
   test x"$ac_cv_sizeof_void__" != x; then
  ac_cv_sizeof_void_p=$ac_cv_sizeof_void__
  AC_DEFINE_UNQUOTED(SIZEOF_VOID_P, $ac_cv_sizeof_void_p,
    [The size of `void *', as computed by sizeof.])
fi

# sizeof(char) is 1 by definition
# plain char is more likely to be signed than unsigned
libevent_mi_1_s="char signed_char"
libevent_mi_1_u="unsigned_char char"

for type in short int long long_long; do
  AS_VAR_IF([ac_cv_sizeof_${type}], [0], , [
    AS_VAR_COPY([size], [ac_cv_sizeof_${type}])
    AS_VAR_APPEND([libevent_mi_${size}_s], [" ${type}"])
    AS_VAR_APPEND([libevent_mi_${size}_u], [" unsigned_${type}"])
  ])
done
# Log results of all the above.
AS_ECHO(["$as_me:${as_lineno-$LINENO}: known integer types are:"]) >&AS_MESSAGE_LOG_FD
for size in 1 2 3 4 5 6 7 8; do
  for sign in s u; do
    AS_VAR_SET_IF([libevent_mi_${size}_${sign}], [
      AS_VAR_COPY([temp], [libevent_mi_${size}_${sign}])
      AS_ECHO(["| libevent_mi_${size}_${sign}=$temp"]) >&AS_MESSAGE_LOG_FD
    ])
  done
done
])
