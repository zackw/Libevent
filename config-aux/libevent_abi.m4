# -*- autoconf -*-
# Copyright 2013 Zack Weinberg <zackw@panix.com>
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

### Generic checks

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

### Checks for particular types and related requirements.

# Figure out whether or not this is Windows.
# Only sets cache variables.
AC_DEFUN([LIBEVENT_SYS_WINDOWS],
[AC_CACHE_CHECK([for Windows], [ac_cv_sys_win32],
  [AC_PREPROC_IFELSE([AC_LANG_PROGRAM([[
#ifndef _WIN32
#error "not WIN32"
#endif
  ]])], [ac_cv_sys_win32=yes], [ac_cv_sys_win32=no])])

AC_CACHE_CHECK([for Cygwin], [ac_cv_sys_cygwin],
  [AC_PREPROC_IFELSE([AC_LANG_PROGRAM([[
#ifndef __CYGWIN__
#error "not Cygwin"
#endif
  ]])], [ac_cv_sys_cygwin=yes], [ac_cv_sys_cygwin=no])])
])

# LIBEVENT_TYPE_SOCKET_STRUCTS
#
#  Set up a shorthand variable for the socket headers, and probe for some
#  generic socket-related structures.
AC_DEFUN([LIBEVENT_TYPE_SOCKET_STRUCTS],
[ev_socket_headers="#include <sys/types.h>
#ifdef HAVE_NETINET_IN_H
#include <netinet/in.h>
#endif
#ifdef HAVE_NETINET_IN6_H
#include <netinet/in6.h>
#endif
#ifdef HAVE_SYS_SOCKET_H
#include <sys/socket.h>
#endif
#ifdef HAVE_NETDB_H
#include <netdb.h>
#endif
#ifdef _WIN32
#define WIN32_WINNT 0x400
#define _WIN32_WINNT 0x400
#define WIN32_LEAN_AND_MEAN
#if defined(_MSC_VER) && (_MSC_VER < 1300)
#include <winsock.h>
#else
#include <winsock2.h>
#include <ws2tcpip.h>
#endif
#endif"

AC_CHECK_TYPES([sa_family_t,
                socklen_t,
                struct addrinfo,
                struct in6_addr,
                struct sockaddr_in6,
                struct sockaddr_storage], , ,
               [$ev_socket_headers])
AC_CHECK_MEMBERS([struct sockaddr_in.sin_len,
                  struct sockaddr_in6.sin6_len], , ,
                 [$ev_socket_headers])
])

# LIBEVENT_TYPE_SOCKET_T
#
#  Determine the appropriate type to use for socket descriptors,
#  e.g. the return type of 'socket' and the first argument to 'connect'.
AC_DEFUN([LIBEVENT_TYPE_SOCKET_T],
[AC_REQUIRE([LIBEVENT_SYS_WINDOWS])dnl
AC_REQUIRE([LIBEVENT__MATCH_TYPE_COMMON])dnl
AC_REQUIRE([LIBEVENT_TYPE_SOCKET_STRUCTS])dnl
# Either we are on a Windows system and we need to match the type
# SOCKET (from winsock2.h), which should be the same as uintptr_t,
# or we aren't, and socket descriptors are
# just file descriptors, which should be regular old 'int'.
# We don't bother with the full-blown MATCH_INTEGER_TYPE logic here.
if test $ac_cv_sys_win32 = yes; then
  LIBEVENT_MATCH_INTEGER_TYPE([SOCKET], [$ac_cv_sizeof_void_p], [unsigned],
                              [$ev_socket_headers],
   [a type that can hold socket descriptors (e.g. as returned from the
    'socket' system call)])
else
  libevent_cv_typeof_SOCKET=int
  AC_DEFINE([TYPEOF_SOCKET], [int])
fi
# This doesn't get its own 'checking ...' message because it'd just
# confuse people.
AC_CACHE_VAL([libevent_cv_verify_socket_t],
[AC_COMPILE_IFELSE([AC_LANG_SOURCE([[
${ev_socket_headers}
/* Provoke a compilation error if TYPEOF_SOCKET is wrong.
   'listen' is the most convenient function to redeclare, as it takes only
   one non-socket argument which is guaranteed to be an 'int'. */
extern int listen(TYPEOF_SOCKET, int);
]])], [libevent_cv_verify_socket_t=yes], [libevent_cv_verify_socket_t=no])])
if test $libevent_cv_verify_socket_t = no; then
  AC_MSG_FAILURE([could not determine type to use for socket descriptors])
fi
])

# LIBEVENT_TYPE_SOCKLEN_T
#
#  Determine the appropriate type to use for the length of a sockaddr
#  object, e.g. the third argument to 'connect' and many others.
AC_DEFUN([LIBEVENT_TYPE_SOCKLEN_T],
[AC_REQUIRE([LIBEVENT_TYPE_SOCKET_T])
# socklen_t is definitely either 'int' or 'unsigned int', but we don't
# know which, and it may or may not be available as a typedef.  The
# easiest way to probe it is to attempt to redeclare 'getsockopt',
# whose fifth argument is supposed to be a 'socklen_t *', and which
# does *not* have any nominally-'struct sockaddr *' arguments (some
# C libraries have strange things instead).  However, the fourth
# argument may be 'void *' or 'char *'.
AC_CACHE_CHECK([for a built-in type matching socklen_t],
               [libevent_cv_typeof_socklen_t], [dnl
  libevent_cv_typeof_socklen_t="not found"
  for ev_arg4 in 'void *' 'char *'; do
    for ev_candidate in 'int' 'unsigned int'; do
      AC_COMPILE_IFELSE([AC_LANG_SOURCE([[
${ev_socket_headers}
/* Provoke a compilation error if socklen_t and ${ev_candidate} are
   incompatible types. */
extern int getsockopt(TYPEOF_SOCKET, int, int, ${ev_arg4}, ${ev_candidate} *);
]])],
      [libevent_cv_typeof_socklen_t="$ev_candidate"
       break 2])
    done
  done])
if test "$libevent_cv_typeof_socklen_t" = "not found"; then
  AC_MSG_FAILURE([could not determine type to use for socklen_t])
fi
AC_DEFINE_UNQUOTED([TYPEOF_SOCKLEN_T], [$libevent_cv_typeof_socklen_t],
  [A built-in integer type compatible with compatible with `socklen_t'.
   If this system's headers do not define `socklen_t', a type suitable
   for the lengths of socket addresses.])
])

# LIBEVENT_SIZE_SOCKADDR
#
#  Determine how much space to allocate for socket addresses of
#  arbitrary (but not AF_UNIX) family.  Will always be at least
#  as large as the larger of 'struct sockaddr_in' and
#  'struct sockaddr_in6'; will additionally be as large as
#  'struct sockaddr_storage' if the system defines that type.

AC_DEFUN([LIBEVENT_SIZE_SOCKADDR],
[AC_REQUIRE([LIBEVENT_TYPE_SOCKET_STRUCTS])dnl
ev_sockaddr_space_test="$ev_socket_headers
#define EV_MAX(a,b) ((a)>(b)?(a):(b))
#define EV_S_SA   sizeof(struct sockaddr)
#define EV_S_SIN  sizeof(struct sockaddr_in)
#define EV_S_SIN6 sizeof(struct sockaddr_in6)
#define EV_S_SS   sizeof(struct sockaddr_storage)
#define EV_S      EV_MAX(EV_S_SA, EV_MAX(EV_S_SIN, "
ev_sockaddr_space_cparens="))"

AS_VAR_IF([ac_cv_type_struct_sockaddr_in6], [yes], [dnl
  AS_VAR_APPEND([ev_sockaddr_space_test],
                ["EV_MAX(EV_S_SIN6, "])
  AS_VAR_APPEND([ev_sockaddr_space_cparens], [")"])
])
AS_VAR_IF([ac_cv_type_struct_sockaddr_storage], [yes], [dnl
  AS_VAR_APPEND([ev_sockaddr_space_test],
                ["EV_MAX(EV_S_SS, "])
  AS_VAR_APPEND([ev_sockaddr_space_cparens], [")"])
])
AS_VAR_APPEND([ev_sockaddr_space_test], ["0$ev_sockaddr_space_cparens"])

AC_CACHE_CHECK([how many bytes to use for sockaddr storage],
               [libevent_cv_space_sockaddr_storage], [dnl
  AC_COMPUTE_INT([libevent_cv_space_sockaddr_storage],
                 [EV_S],
                 [$ev_sockaddr_space_test], [dnl
    AC_MSG_FAILURE([failed to compute required space for sockaddr storage])
])])
AC_DEFINE_UNQUOTED([SOCKADDR_SPACE], [${libevent_cv_space_sockaddr_storage}U],
  [Define as the size (in bytes) of a block of memory that can hold
   socket addresses of arbitrary family.  This must be at least as large
   as the larger of `struct sockaddr_in' and `struct sockaddr_in6', and
   should be as large as `struct sockaddr_storage', if you have that.
   It is not, however, necessary for this to be big enough for AF_UNIX
   addresses.])
])
