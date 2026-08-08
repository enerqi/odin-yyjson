# `cmd.exe` for one reason: it starts in ~9ms. just launches a shell per recipe LINE, so shell startup
# is a fixed tax on every recipe. Bare `<shell> exit` under hyperfine: cmd ~9ms, `nu -c` ~41ms (what
# this file used to set), `powershell -NoLogo -NoProfile -Command` ~143ms. cmd is also more portable
# than either: on every Windows and on GitHub's windows runners, no install, and no profile to make a
# recipe unreproducible. The cost is that it is a poor language for a multi-line recipe - which does
# not bite, because every Windows body below is a single command; anything with logic would use
# `[script("python")]` instead.
set windows-shell := ["cmd.exe", "/c"]
set shell := ["bash", "-c"]
set unstable  # [script("python")] feature - https://github.com/casey/just/issues/1479
set lazy

# Set by the newest just feature used below - user-defined functions (1.49), for `target_path`.
# Older features also needed: `join()` 1.37, `set lazy` 1.47. Without this an old just reports a plain
# syntax error at the offending line, which reads like a corrupt justfile rather than an old tool.
set minimum-version := "1.49.0"

main_name := "main.exe"
test_main_name := "test-main.exe"

# `join`, not the `/` operator: `/` always emits a forward slash, and cmd.exe rejects a forward-slash
# path in *command* position ("'target' is not recognized") even quoted. Odin takes either in an
# `-out:` argument, but the `rerun-*` recipes invoke the binary directly, so they need the native
# separator `join` gives. bash needs no `./` prefix - a path containing a slash is already a path.
target_path(dir, name) := join("target", dir, name)

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
# Caution for a bindings project that statically links a C library: radlink has been seen to link a
# binary cleanly and then have it die at startup with `0xc000001d` (STATUS_ILLEGAL_INSTRUCTION) - see
# odin-num-format's justfile (Rust staticlib + `+crt-static`) and odin-sims (the DDS static lib), both
# of which had to pin `default`. If a yyjson binary ever fails that way, try `ODIN_LINKER=default`
# before suspecting your own code; a successful link proves nothing, only running it does.
#
# See the odin-lang-skeleton justfile for the full per-value notes.
linker := env_var_or_default("ODIN_LINKER", if os() == "windows" { "radlink" } else { "default" })

# odinfmt the generated bindings
format:
	odinfmt -w yyjson.odin

# lint checks for style and potential bugs. Accepts extra args like `--show-timings` as needed
lint *args:
	odin check . -vet -vet-cast -strict-style -vet-tabs -no-entry-point {{args}}

# Every `run-*` and `test*` recipe depends on this, so it runs before every build - which makes its
# cost a tax on every iteration. The directories are created all at once rather than one per line
# because just starts a new shell per recipe line and on Windows the shell launch dwarfs the work.
# odin does not create the output directory (the linker fails with LNK1104), so this cannot be dropped.
# ---
# ensure the build artifacts top level directory exists
[unix]
@mktarget_dirs:
	mkdir -p target/debug target/fastdebug target/release

# `if not exist` rather than swallowing md's "already exists" with `2>nul`, so a genuine failure still
# sets a non-zero exit. The loop variable is a single `%d`, NOT the `%%d` a .bat file would use:
# doubling is escaping for batch *files*, and `cmd /c` takes a command *line*.
# ---
# ensure the build artifacts top level directory exists
[windows]
@mktarget_dirs:
	for %d in (debug fastdebug release) do @if not exist target\%d md target\%d || exit /b 1

# `-keep-executable` leaves the binary in place (odin run deletes it by default) so `rerun-debug` can
# execute it again - Odin has no build cache, so a plain `just run` always recompiles and relinks.
# ---
# run the example (debug)
run-debug *args: mktarget_dirs
	odin run example -debug -microarch:native -show-timings -keep-executable -linker:{{linker}} -out:{{ target_path("debug", main_name) }} {{args}}

alias run := run-debug

# run the example with debug info and optimizations
run-fastdebug *args: mktarget_dirs
	odin run example -debug -o:speed -microarch:native -show-timings -keep-executable -linker:{{linker}} -out:{{ target_path("fastdebug", main_name) }} {{args}}

# run the example with optimizations
run-release *args: mktarget_dirs
	odin run example -o:speed -microarch:native -show-timings -keep-executable -linker:{{linker}} -out:{{ target_path("release", main_name) }} {{args}}

# re-run the last debug example binary WITHOUT recompiling. Requires a prior `run-debug`/`run`.
rerun-debug *args:
	{{ target_path("debug", main_name) }} {{args}}

alias rerun := rerun-debug

# re-run the last fastdebug example binary without recompiling. Requires a prior `run-fastdebug`.
rerun-fastdebug *args:
	{{ target_path("fastdebug", main_name) }} {{args}}

# re-run the last release example binary without recompiling. Requires a prior `run-release`.
rerun-release *args:
	{{ target_path("release", main_name) }} {{args}}

# run all tests
test *args: mktarget_dirs
	odin test . -debug -file -microarch:native -show-timings -linker:{{linker}} -out:{{ target_path("debug", test_main_name) }} {{args}}

# Filtering is a `core:testing` define rather than a compiler flag - there is no `-test-name:`, and the
# stale spelling this recipe used to carry failed with `Unknown flag: 'test-name'` before anything
# built, so `just test1` could never have worked. NAME takes a comma-separated list and the package
# prefix is optional, so `yyjson.my_test`, `my_test` and `one,two` all work.
# ---
# run one named test (comma-separated for several)
test1 name *args: mktarget_dirs
	odin test . -debug -file -microarch:native -show-timings -define:ODIN_TEST_NAMES={{name}} -linker:{{linker}} -out:{{ target_path("debug", test_main_name) }} {{args}}

# simple delete of all debug databases and executables in the target directory
[unix]
clean:
	rm -rf target
	just mktarget_dirs

# cmd's equivalent of `rm -rf` is `rmdir /s /q`. Guarded by `if exist` because rmdir prints "The system
# cannot find the file specified" and exits non-zero on a missing path, which would fail the recipe on
# an already-clean tree. (The old single `rm -rf target` recipe was nu-only and had no Windows path.)
# ---
# simple delete of all debug databases and executables in the target directory
[windows]
clean:
	if exist target rmdir /s /q target
	just mktarget_dirs
