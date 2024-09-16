@echo off

if not exist "..\lib" mkdir ..\lib

rem define macro
rem /D yyjson_api_inline (no value) so the inline header functions are linkable

rem https://learn.microsoft.com/en-us/cpp/build/reference/md-mt-ld-use-run-time-library?view=msvc-170
rem /MT link with LIBCMT.LIB (multithread, static version of the run-time library)

rem /TC compile all files as .c
rem /O2 maximum optimizations (favor speed)
cl -nologo -MT -TC -O2 /D yyjson_api_inline= -c yyjson.c

rem https://learn.microsoft.com/en-us/cpp/build/reference/lib-reference?view=msvc-170
rem create static library from COFF object files
lib -nologo yyjson.obj -out:..\lib\yyjson.lib

del *.obj
