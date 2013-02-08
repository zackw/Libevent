# originally embedded in configure

AC_DEFUN([LIBEVENT_CURRENT_FUNCTION_NAME],
[AC_CACHE_CHECK([how to get the name of the current function],
               [ac_cv_var_function_name],
  [ac_cv_var_function_name="not available"
   AC_COMPILE_IFELSE(
    [AC_LANG_PROGRAM([], [[const char *cp = __func__;]])],
    [ac_cv_var_function_name=__func__])
   if test "$ac_cv_var_function_name" = "not available"; then
   AC_COMPILE_IFELSE(
      [AC_LANG_PROGRAM([], [[const char *cp = __FUNCTION__;]])],
      [ac_cv_var_function_name=__FUNCTION__])
   fi
])
AH_TEMPLATE([__func__],
   [Define to an appropriate substitute if not supported by your compiler.])
AS_CASE([$ac_cv_var_function_name],
  [__func__],        [],
  ["not available"], [AC_DEFINE([__func__], [__FILE__])],
                     [AC_DEFINE_UNQUOTED([__func__],
                                         [$ac_cv_var_function_name])])
])
