@echo off
rem setlocal so the env changes vcvars64 makes below don't leak into the caller's
rem shell; it is auto-restored when the script exits.
setlocal

rem --- ensure cl (the MSVC compiler) is available ------------------------------
rem Lets this run from a plain cmd shell, not only an "x64 Native Tools" prompt:
rem if cl is missing we locate Visual Studio via vswhere and load the x64 env.
where cl >nul 2>nul
if %errorlevel%==0 goto have_cl

set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" (
    echo [build] cl not on PATH and vswhere not found.
    echo [build] Open an "x64 Native Tools Command Prompt for VS" and re-run.
    exit /b 1
)
rem -prerelease so VS preview / future channels are found too.
for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -prerelease -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VSINSTALL=%%i"
if not defined VSINSTALL (
    echo [build] No VS install with C++ tools found via vswhere.
    exit /b 1
)
if not exist "%VSINSTALL%\VC\Auxiliary\Build\vcvars64.bat" (
    echo [build] vcvars64.bat missing under "%VSINSTALL%".
    exit /b 1
)
echo [build] Loading x64 toolchain from "%VSINSTALL%"
rem 2>nul silences benign stderr from vcvars' own internal vswhere lookup; the
rem `where cl` check on the next line is the real guard that it actually worked.
call "%VSINSTALL%\VC\Auxiliary\Build\vcvars64.bat" >nul 2>nul
where cl >nul 2>nul || (echo [build] cl still not on PATH after vcvars64. & exit /b 1)
:have_cl

rem Run from anywhere (repo root, src\, or elsewhere). %~dp0 is this script's own
rem dir (...\src\). pushd AFTER loading vcvars64 (which can change the cwd), so we
rem land in src\ regardless of where we were called or where vcvars left us. All
rem paths below stay relative to src\; popd restores the cwd at the end.
pushd "%~dp0"

if not exist "..\lib" mkdir ..\lib

rem define macro
rem /D yyjson_api_inline (no value) so the inline header functions are linkable

rem --- C runtime: /MT is REQUIRED here, not a preference -----------------------
rem https://learn.microsoft.com/en-us/cpp/build/reference/md-mt-ld-use-run-time-library
rem /MT links the static CRT (LIBCMT.lib); /MD would link the dynamic CRT (MSVCRT).
rem
rem We build this .lib to be consumed by Odin programs. Odin's Windows backend
rem emits `/defaultlib:libcmt` for any non-static-library build (see Odin
rem src/linker.cpp: no_crt ? /nodefaultlib : /defaultlib:libcmt). i.e. the Odin
rem host links the STATIC CRT. There is no Odin flag to pick the dynamic CRT;
rem only -no-crt turns it off entirely.
rem
rem MSVC rule: "All modules passed to a given invocation of the linker must have
rem been compiled with the same runtime library compiler option (/MD, /MT, /LD)."
rem So yyjson MUST be /MT to match Odin's libcmt. If it were /MD you'd get a
rem /MD (MSVCRT) vs /MT (libcmt) mismatch -> LNK4098 + two CRT copies -> two
rem heaps. yyjson_*_write returns a malloc'd buffer the caller frees (see
rem example.odin: libc.free of mut_write's result); with mismatched CRTs that
rem free crosses heaps -> heap corruption. With /MT both sides resolve to the
rem single statically-linked libcmt the linker folds in -> one heap -> safe.
rem
rem Linker-independent: Odin's default Windows linker is MS link.exe, switchable
rem to lld-link (-linker:lld) or rad-link (-linker:radlink). All three are
rem MSVC-family COFF linkers that honor the /defaultlib directive /MT bakes into
rem the .obj, so the /MT match holds whichever is used.

rem /TC compile all files as .c
rem /O2 maximum optimizations (favor speed). Already implies /Oi (intrinsics) and
rem /Ot (favor speed), so those are not listed separately.
rem -arch:AVX2 assumes an AVX2-capable CPU (Intel Haswell 2013+); yyjson has no
rem runtime SIMD dispatch, so this binary will #UD on older CPUs. Deliberate.
rem
rem /Gy (function COMDATs) + /Gw (data COMDATs): put each function and global in
rem its own section. yyjson exports hundreds of functions plus static lookup
rem tables; an Odin program uses only a fraction. These flags let the CONSUMER's
rem linker dead-strip the unused ones individually (Odin release links default to
rem /OPT:REF + /OPT:ICF) instead of pulling the whole .obj -> smaller exe, faster
rem link. Pure link-time/size win; does not change runtime throughput.
rem
rem NOT used: /GL (LTCG) - its objects hold MSVC proprietary IL, not COFF, so
rem lld-link / rad-link cannot read them; and yyjson is a single amalgamated TU
rem that /O2 has already inlined internally, so /GL would add ~nothing anyway.
rem NOT used: /MP - parallelizes across translation units; there is only one here.
rem NOT used: /fp:fast - yyjson has exact dtoa/strtod for correct float round-trip;
rem fast-math reordering can corrupt number output. /GS stays on: parser eats
rem untrusted input, keep the buffer checks.
cl -nologo -MT -TC -O2 -arch:AVX2 /Gy /Gw /D yyjson_api_inline= -c yyjson.c

rem https://learn.microsoft.com/en-us/cpp/build/reference/lib-reference?view=msvc-170
rem create static library from COFF object files
lib -nologo yyjson.obj -out:..\lib\yyjson.lib

rem remove only our intermediate, not every .obj that happens to be in src\
del yyjson.obj

popd
endlocal
