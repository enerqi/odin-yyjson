# Build the static yyjson library for the Odin bindings (Unix / macOS).
# Windows is built separately with build.bat (MSVC). Run via `make -C src`.
#
# --- flag rationale (kept in sync with build.bat where it makes sense) -------
#
# -O2            Optimize for speed. NOTE: the previous version passed `-O2 -Os`
#                together; with GCC/Clang the LAST -O wins, so -Os (size) silently
#                won and the lib was built for size, contradicting build.bat's
#                speed goal. Use -O2 alone.
#
# -Dyyjson_api_inline=''
#                Define the inline-API macro to empty so yyjson's header inline
#                functions become real external symbols the bindings can link.
#
# -fPIC          Position-independent code: required for the .a to fold into a
#                modern PIE executable (Odin default) or a future shared object.
#
# -ffunction-sections -fdata-sections
#                Put each function and global in its own section. This is the
#                GCC/Clang analog of build.bat's /Gy /Gw: it lets the CONSUMER's
#                linker dead-strip unused yyjson symbols with --gc-sections (Odin
#                links with lld, which honors it) instead of pulling whole objects.
#                Pure link-time/size win; no runtime effect.
#
# CRT: nothing to do here. Unlike Windows (static libcmt vs dynamic msvcrt, which
# MUST match the Odin host - see build.bat), Linux/BSD have no static/dynamic CRT
# split: Odin and yyjson.a both link the system glibc DYNAMICALLY. Do not try to
# statically link the C library; it gains nothing here and breaks dlopen/NSS.
#
# No -march/-mavx2: kept OFF for portability so the prebuilt .a runs on any x86_64
# (build.bat deliberately assumes AVX2 on Windows; the Unix prebuilt does not).
# yyjson has no runtime SIMD dispatch, so -mavx2 would #UD on older CPUs. If you
# build for your own machine and want it, append -march=native (or -mavx2).
#
# No -flto: same trap as MSVC /GL. An LTO .a carries GIMPLE/bitcode that needs the
# matching compiler's LTO plugin at final link; a foreign linker (Odin's lld) may
# not invoke it -> link breakage. yyjson is also a single translation unit, so LTO
# buys ~nothing. Ship plain object code.

CFLAGS_COMMON = -O2 -fPIC -ffunction-sections -fdata-sections -Dyyjson_api_inline=''
MACOS_MIN     = -mmacosx-version-min=10.12

OS = $(shell uname)

ifeq ($(OS), Darwin)
all: darwin
else
all: unix
endif

unix:
	mkdir -p ../lib
	$(CC) -c $(CFLAGS_COMMON) yyjson.c -o yyjson.o
	$(AR) rcs ../lib/yyjson.a yyjson.o
	rm -f yyjson.o

darwin:
	mkdir -p ../lib/darwin
	$(CC) -arch x86_64 -c $(CFLAGS_COMMON) $(MACOS_MIN) yyjson.c -o yyjson-x86_64.o
	$(CC) -arch arm64  -c $(CFLAGS_COMMON) $(MACOS_MIN) yyjson.c -o yyjson-arm64.o
	lipo -create yyjson-x86_64.o yyjson-arm64.o -output ../lib/darwin/yyjson.a
	rm -f yyjson-x86_64.o yyjson-arm64.o

.PHONY: all unix darwin
