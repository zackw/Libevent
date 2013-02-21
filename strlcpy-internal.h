#ifndef STRLCPY_INTERNAL_H_INCLUDED_
#define STRLCPY_INTERNAL_H_INCLUDED_

/* Including strlcpy-internal.h should always bring in string.h,
   regardless of whether we need to define our own strlcpy.  */
#include <string.h>

#ifdef HAVE_STRLCPY
#define event_strlcpy(dst_, src_, siz_) \
              strlcpy(dst_, src_, siz_)
#else
size_t event_strlcpy_(char *dst, const char *src, size_t siz);
#define event_strlcpy(dst_, src_, siz_)         \
       event_strlcpy_(dst_, src_, siz_)
#endif

/* We want all of our code to use 'event_strlcpy', not either of the
   things it might be defined as.  This makes it somewhat more likely
   that people will not add uses of bare strlcpy on a platform that
   provides it, thus breaking the build on platforms that don't.
   (The #pragma does not trigger on the expansion of the macro above.)
   FIXME: maybe this should be in util-internal.h or some other
   universally-included header, instead?  */
#pragma GCC poison strlcpy event_strlcpy_

#endif
