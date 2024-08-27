# odin-yyjson

[Odin](http://odin-lang.org/) bindings for the [yyjson](https://github.com/ibireme/yyjson) C language libary.

Yyjson appears to be the fastest JSON library written in pure C. Some alternatives are
[jansson](https://github.com/akheron/jansson), [json-c](https://github.com/json-c/json-c) and
[c-json](https://github.com/DaveGamble/cJSON).

Yyjson and other low level C libraries do not come with an easy way to encode/decode json to Odin structs. The Odin
package [core:encoding/json](https://pkg.odin-lang.org/core/encoding/json/) does provide struct marshalling, but it
maybe much slower than yyjson for some purposes.

Note, for C++ programmers [simdjson](https://github.com/simdjson/simdjson) maybe a bit faster. However, it only *reads*
JSON and does not have a C wrapper.


## API structure

The bindings are essentially a 1-to-1 port so that the original yyjson docs are easy to follow.

- symbols named `yyjson_something` in the [C API](https://ibireme.github.io/yyjson/doc/doxygen/html/) are presented
  as `yyjson.something` in the bindings
- Odin `bit_set`s are used where a number is passed as a flag
- default parameters maybe provided where valid `NULL` (`nil`) parameters can be used in the C API

## yyjson version

- 0.10.0

## Building the yyjson static library

- The static library `yyjson.lib` for Windows is shipped with the bindings in `./lib`. On a Posix OS it can be compiled
  with the `Makefile`
- The static library is built with a custom define, so it's likely more convenient to use our tiny scripts to compile
  the library on Linux!
- The yyjson source is vendored in [./src](./src) along with the build scripts (`build.bat` for Windows, `Makefile` for
  Linux)

We cannot easily use the system package manager on Linux, or a C/C++ build system such as [vcpkg](https://vcpkg.io/) or
[conan](https://conan.io/). `yyjson` exposes a lot of functionality as inline functions that default to being
statically linked (normally you are expected to build against their source by including `yyjson.h` in your C/C++
program). Our `build.bat` and `Makefile` adds the custom define `yyjson_api_inline` so that the symbols have external
linkage.

