set windows-shell := ["nu", "-c"]
set shell := ["bash", "-c"]
set unstable  # [script("python")] feature - https://github.com/casey/just/issues/1479

main_name := "main.exe"

# Which linker Odin hands the object files to. `-linker:` takes exactly four values: `default` (Odin
# picks - MSVC `link.exe` on Windows), `lld` (Windows and Linux; NOT on a stock macOS, where Odin
# links through Apple's clang and clang ships no lld), `radlink` (Windows only, and bundled with the
# Odin toolchain so it needs no install - which is why it is the Windows default here) and `mold`
# (Linux only, and not bundled - `apt install mold` first). Odin has no build cache and relinks on
# every `just run`, so the link step is a cost paid on each iteration.
#
# Override for a single command without editing this file. It is an env var rather than a recipe
# argument because `odin` errors on a repeated flag, so a `-linker:` passed through a recipe's *args
# would collide with the one the recipe already adds:
#
#     ODIN_LINKER=lld just run -lto:thin   # -lto on Windows *requires* -linker:lld
#
# See the odin-lang-skeleton justfile for the full per-value notes.
linker := env_var_or_default("ODIN_LINKER", if os() == "windows" { "radlink" } else { "default" })

# odinfmt the generated bindings
format:
	odinfmt -w "yyjson.odin"

# lint checks for style and potential bugs. Accepts extra args like `--show-timings`as needed
lint *args:
	odin check . -vet -vet-cast -strict-style -vet-tabs -no-entry-point {{args}}

# ensure the build artifacts top level directory exists
[unix]
@mktarget_dirs:
	mkdir -p target/debug target/fastdebug target/release

# ensure the build artifacts top level directory exists
[windows]
@mktarget_dirs:
	mkdir target/debug target/fastdebug target/release

run-debug *args: mktarget_dirs
	odin run example -debug -microarch:native -show-timings -linker:{{linker}} -out:target/debug/{{main_name}} {{args}}

alias run := run-debug

run-fastdebug *args: mktarget_dirs
	odin run example -debug -o:speed -microarch:native -show-timings -linker:{{linker}} -out:target/fastdebug/{{main_name}} {{args}}

run-release *args: mktarget_dirs
	odin run example -o:speed -microarch:native -show-timings -linker:{{linker}} -out:target/release/{{main_name}} {{args}}

# run all tests
test *args: mktarget_dirs
	odin test . -debug -file -microarch:native -show-timings -linker:{{linker}} -out:target/debug/test-main.exe {{args}}

# run one named test
test1 name *args: mktarget_dirs
	odin test . -debug -file -microarch:native -show-timings -test-name:{{name}} -linker:{{linker}} -out:target/debug/test-main.exe {{args}}

# simple delete of all debug databases and executables in the target directory
clean:
	rm -rf target
	just mktarget_dirs
