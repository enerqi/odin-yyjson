@echo off

if not exist "..\lib" mkdir ..\lib

rem customisations:
rem /D yyjson_api_inline (no value) so the inline header functions are linkable

cl -nologo -MT -TC -O2 /D yyjson_api_inline= -c yyjson.c
lib -nologo yyjson.obj -out:..\lib\yyjson.lib

del *.obj
