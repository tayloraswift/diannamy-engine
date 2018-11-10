#ifndef __FREETYPE_H_SHIM
#define __FREETYPE_H_SHIM

#include <ft2build.h>

// just, don’t ask. it’s stupid. (relevant bug: SR-3999)
#define FT_ERRORDEF( e, v, s )  e = v,
#define FT_ERROR_START_LIST     enum {
#define FT_ERROR_END_LIST       FT_ERR_CAT( FT_ERR_PREFIX, Max ), \
    _swiftABIForceSignedInt32 = -1 \
} FT_ErrorCase;

#include FT_FREETYPE_H

// used for building a table of codes and associated error messages
#undef FTERRORS_H_
#define FT_ERRORDEF( e, v, s )  { e, s },
#define FT_ERROR_START_LIST     {
#define FT_ERROR_END_LIST       };

typedef struct
{
  int          code;
  const char*  message;
} FT_ErrorTableEntry;

static const FT_ErrorTableEntry FT_ErrorTable[] =

#include FT_ERRORS_H

static const long FT_ErrorTableCount = sizeof(FT_ErrorTable) / sizeof(FT_ErrorTable[0]);

#endif
