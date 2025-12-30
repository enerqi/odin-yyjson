package yyjson

import "core:c"

import "core:c/libc"

when ODIN_OS == .Windows {
	// yyjson.lib is shipped with these bindings, but can be rebuilt manually with ./src/build.bat
	foreign import lib "lib/yyjson.lib"
} else when ODIN_OS == .Linux || ODIN_OS == .FreeBSD || ODIN_OS == .OpenBSD || ODIN_OS == .NetBSD {
	when !#exists("lib/yyjson.a") {
		#panic("Cannot find compiled yyjson libraries ./lib/yyjson.a. Compile by running `make -C src`")
	}
	foreign import lib "lib/yyjson.a"
} else when ODIN_OS == .Darwin {
	when !#exists("lib/darwin/yyjson.a") {
		#panic(
			"Cannot find compiled yyjson libraries ./lib/darwin/yyjson.a for ODIN_OS.Darwin. Compile by running `make -C src`",
		)
	}
	foreign import lib "lib/darwin/yyjson.a"
} else {
	// Unknown OS. Fallback to searching for a global system installed library (also c.f. LD_LIBRARY_PATH)
	foreign import lib "system:yyjson"
}

// Hand-written enum for yyjson_read_code, as it's defined as static const values in C
Read_Code :: enum c.uint32_t {
	/** Success, no error. */
	SUCCESS                    = 0,
	/** Invalid parameter, such as NULL input string or 0 input length. */
	ERROR_INVALID_PARAMETER    = 1,
	/** Memory allocation failed. */
	ERROR_MEMORY_ALLOCATION    = 2,
	/** Input JSON string is empty. */
	ERROR_EMPTY_CONTENT        = 3,
	/** Unexpected content after document, such as `[123]abc`. */
	ERROR_UNEXPECTED_CONTENT   = 4,
	/** Unexpected end of input, the parsed part is valid, such as `[123`. */
	ERROR_UNEXPECTED_END       = 5,
	/** Unexpected character inside the document, such as `[abc]`. */
	ERROR_UNEXPECTED_CHARACTER = 6,
	/** Invalid JSON structure, such as `[1,]`. */
	ERROR_JSON_STRUCTURE       = 7,
	/** Invalid comment, deprecated, use `ERROR_UNEXPECTED_END` for unclosed comment. */
	ERROR_INVALID_COMMENT      = 8,
	/** Invalid number, such as `123.e12`, `000`. */
	ERROR_INVALID_NUMBER       = 9,
	/** Invalid string, such as invalid escaped character inside a string. */
	ERROR_INVALID_STRING       = 10,
	/** Invalid JSON literal, such as `truu`. */
	ERROR_LITERAL              = 11,
	/** Failed to open a file. */
	ERROR_FILE_OPEN            = 12,
	/** Failed to read a file. */
	ERROR_FILE_READ            = 13,
	/** Incomplete input during incremental parsing; parsing state is preserved. */
	ERROR_MORE                 = 14,
	/** Read depth limit exceeded. */
	ERROR_DEPTH                = 15,
}

// Hand-written enum for yyjson_patch_code, as it's defined as static const values in C
Patch_Code :: enum c.uint32_t {
	/** Success, no error. */
	SUCCESS                 = 0,
	/** Invalid parameter, such as NULL input or non-array patch. */
	ERROR_INVALID_PARAMETER = 1,
	/** Memory allocation failure occurs. */
	ERROR_MEMORY_ALLOCATION = 2,
	/** JSON patch operation is not object type. */
	ERROR_INVALID_OPERATION = 3,
	/** JSON patch operation is missing a required key. */
	ERROR_MISSING_KEY       = 4,
	/** JSON patch operation member is invalid. */
	ERROR_INVALID_MEMBER    = 5,
	/** JSON patch operation `test` not equal. */
	ERROR_EQUAL             = 6,
	/** JSON patch operation failed on JSON pointer. */
	ERROR_POINTER           = 7,
}

// Hand-written enum for yyjson_ptr_code, as it's defined as static const values in C
Ptr_Code :: enum c.uint32_t {
	/** No JSON pointer error. */
	ERR_NONE              = 0,
	/** Invalid input parameter, such as NULL input. */
	ERR_PARAMETER         = 1,
	/** JSON pointer syntax error, such as invalid escape, token no prefix. */
	ERR_SYNTAX            = 2,
	/** JSON pointer resolve failed, such as index out of range, key not found. */
	ERR_RESOLVE           = 3,
	/** Document's root is NULL, but it is required for the function call. */
	ERR_NULL_ROOT         = 4,
	/** Cannot set root as the target is not a document. */
	ERR_SET_ROOT          = 5,
	/** The memory allocation failed and a new value could not be created. */
	ERR_MEMORY_ALLOCATION = 6,
}

// Hand-written enum for yyjson_read_flag, as it's defined as bit flags in C
Read_Flag :: enum c.uint32_t {
	/** Read the input data in-situ. */
	INSITU                  = 0,
	/** Stop when done instead of issuing an error if there's additional content after a JSON document. */
	STOP_WHEN_DONE          = 1,
	/** Allow single trailing comma at the end of an object or array (non-standard). */
	ALLOW_TRAILING_COMMAS   = 2,
	/** Allow C-style single-line and mult-line comments (non-standard). */
	ALLOW_COMMENTS          = 3,
	/** Allow inf/nan number and literal, case-insensitive (non-standard). */
	ALLOW_INF_AND_NAN       = 4,
	/** Read all numbers as raw strings. */
	NUMBER_AS_RAW           = 5,
	/** Allow reading invalid unicode when parsing string values (non-standard). */
	ALLOW_INVALID_UNICODE   = 6,
	/** Read big numbers as raw strings (non-standard). */
	BIGNUM_AS_RAW           = 7,
	/** Allow UTF-8 BOM and skip it before parsing if any (non-standard). */
	ALLOW_BOM               = 8,
	/** Allow extended number formats (non-standard). */
	ALLOW_EXT_NUMBER        = 9,
	/** Allow extended escape sequences in strings (non-standard). */
	ALLOW_EXT_ESCAPE        = 10,
	/** Allow extended whitespace characters (non-standard). */
	ALLOW_EXT_WHITESPACE    = 11,
	/** Allow strings enclosed in single quotes (non-standard). */
	ALLOW_SINGLE_QUOTED_STR = 12,
	/** Allow object keys without quotes (non-standard). */
	ALLOW_UNQUOTED_KEY      = 13,
}

Read_Flags :: bit_set[Read_Flag;c.uint32_t]

/** Preset: Allow JSON5 format.
    This combines flags for:
    - Allow trailing commas
    - Allow comments
    - Allow inf/nan
    - Allow extended number formats
    - Allow extended escape sequences
    - Allow extended whitespace
    - Allow single-quoted strings
    - Allow unquoted keys */
JSON5 :: Read_Flags {
	.ALLOW_TRAILING_COMMAS,
	.ALLOW_COMMENTS,
	.ALLOW_INF_AND_NAN,
	.ALLOW_EXT_NUMBER,
	.ALLOW_EXT_ESCAPE,
	.ALLOW_EXT_WHITESPACE,
	.ALLOW_SINGLE_QUOTED_STR,
	.ALLOW_UNQUOTED_KEY,
}

// Hand-written enum for yyjson_write_flag, as it's defined as bit flags in C
Write_Flag :: enum c.uint32_t {
	/** Write JSON pretty with 4 space indent. */
	PRETTY                = 0,
	/** Escape unicode as `uXXXX`, make the output ASCII only. */
	ESCAPE_UNICODE        = 1,
	/** Escape '/' as '\/'. */
	ESCAPE_SLASHES        = 2,
	/** Write inf and nan number as 'Infinity' and 'NaN' literal (non-standard). */
	ALLOW_INF_AND_NAN     = 3,
	/** Write inf and nan number as null literal.
	    This flag will override `ALLOW_INF_AND_NAN` flag. */
	INF_AND_NAN_AS_NULL   = 4,
	/** Allow invalid unicode when encoding string values (non-standard).
	    Invalid characters in string value will be copied byte by byte.
	    If `ESCAPE_UNICODE` flag is also set, invalid character will be
	    escaped as `U+FFFD` (replacement character).
	    This flag does not affect the performance of correctly encoded strings. */
	ALLOW_INVALID_UNICODE = 5,
	/** Write JSON pretty with 2 space indent.
	    This flag will override `PRETTY` flag. */
	PRETTY_TWO_SPACES     = 6,
	/** Adds a newline character `\n` at the end of the JSON.
	    This can be helpful for text editors or NDJSON. */
	NEWLINE_AT_END        = 7,
	/** Write floating-point numbers using single-precision (float).
	    This casts `double` to `float` before serialization.
	    This will produce shorter output, but may lose some precision.
	    This flag is ignored if `FP_TO_FIXED(prec)` is also used. */
	FP_TO_FLOAT           = 27,
}

Write_Flags :: bit_set[Write_Flag;u32]

// Hand-written enum for yyjson_write_code, as it's defined as static const values in C
Write_Code :: enum c.uint32_t {
	/** Success, no error. */
	SUCCESS                  = 0,
	/** Invalid parameter, such as NULL document. */
	ERROR_INVALID_PARAMETER  = 1,
	/** Memory allocation failure occurs. */
	ERROR_MEMORY_ALLOCATION  = 2,
	/** Invalid value type in JSON document. */
	ERROR_INVALID_VALUE_TYPE = 3,
	/** NaN or Infinity number occurs. */
	ERROR_NAN_OR_INF         = 4,
	/** Failed to open a file. */
	ERROR_FILE_OPEN          = 5,
	/** Failed to write a file. */
	ERROR_FILE_WRITE         = 6,
	/** Invalid unicode in string. */
	ERROR_INVALID_STRING     = 7,
}

// Hand-written enum for yyjson_type, as it's defined as #define constants in C
Type :: enum u8 {
	/** No type, invalid. */
	NONE = 0,
	/** Raw string type, no subtype. */
	RAW  = 1,
	/** Null type: `null` literal, no subtype. */
	NULL = 2,
	/** Boolean type, subtype: TRUE, FALSE. */
	BOOL = 3,
	/** Number type, subtype: UINT, SINT, REAL. */
	NUM  = 4,
	/** String type, subtype: NONE, NOESC. */
	STR  = 5,
	/** Array type, no subtype. */
	ARR  = 6,
	/** Object type, no subtype. */
	OBJ  = 7,
}

// Hand-written enum for yyjson_subtype, as it's defined as #define constants in C
Subtype :: enum u8 {
	/** No subtype. */
	NONE  = 0,
	/** False subtype: `false` literal. */
	FALSE = 0,
	/** Unsigned integer subtype: `uint64_t`. */
	UINT  = 0,
	/** True subtype: `true` literal. */
	TRUE  = 8,
	/** Signed integer subtype: `int64_t`. */
	SINT  = 8,
	/** String that does not need to be escaped for writing (internal use). */
	NOESC = 8,
	/** Real number subtype: `double`. */
	REAL  = 16,
}


YYJSON_GCC_VER :: 0
YYJSON_IS_REAL_GCC :: 0
YYJSON_STDC_VER :: 0
YYJSON_CPP_VER :: 0
YYJSON_HAS_CONSTANT_P :: 1
YYJSON_U64_TO_F64_NO_IMPL :: 0

/*==============================================================================
* MARK: - Version
*============================================================================*/

/** The major version of yyjson. */
YYJSON_VERSION_MAJOR :: 0

/** The minor version of yyjson. */
YYJSON_VERSION_MINOR :: 12

/** The patch version of yyjson. */
YYJSON_VERSION_PATCH :: 0

/** The version of yyjson in hex: `(major << 16) | (minor << 8) | (patch)`. */
YYJSON_VERSION_HEX :: 0x000C00

/** The version string of yyjson. */
YYJSON_VERSION_STRING :: "0.12.0"

/** Padding size for JSON reader. */
YYJSON_PADDING_SIZE :: 4

/**
A memory allocator.

Typically you don't need to use it, unless you want to customize your own
memory allocator.
*/
Alc :: struct {
	/** Same as libc's malloc(size), should not be NULL. */
	malloc:  proc "c" (ctx: rawptr, size: c.size_t) -> rawptr,

	/** Same as libc's realloc(ptr, size), should not be NULL. */
	realloc: proc "c" (ctx: rawptr, ptr: rawptr, old_size: c.size_t, size: c.size_t) -> rawptr,

	/** Same as libc's free(ptr), should not be NULL. */
	free:    proc "c" (ctx: rawptr, ptr: rawptr),

	/** A context for malloc/realloc/free, can be NULL. */
	ctx:     rawptr,
}

/** Error information for JSON reader. */
Read_Err :: struct {
	/** Error code, see `yyjson_read_code` for all possible values. */
	code: Read_Code,

	/** Error message, constant, no need to free (NULL if success). */
	msg:  cstring,

	/** Error byte position for input data (0 if success). */
	pos:  c.size_t,
}

Incr_State :: struct {}

/** The highest 8 bits of `yyjson_write_flag` and real number value's `tag`
are reserved for controlling the output format of floating-point numbers. */
YYJSON_WRITE_FP_FLAG_BITS :: 8

/** The highest 4 bits of flag are reserved for precision value. */
YYJSON_WRITE_FP_PREC_BITS :: 4

/** Error information for JSON writer. */
Write_Err :: struct {
	/** Error code, see `yyjson_write_code` for all possible values. */
	code: Write_Code,

	/** Error message, constant, no need to free (NULL if success). */
	msg:  cstring,
}

/**
A JSON array iterator.

@b Example
@code
yyjson_val *val;
yyjson_arr_iter iter = yyjson_arr_iter_with(arr);
while ((val = yyjson_arr_iter_next(&iter))) {
your_func(val);
}
@endcode
*/
Arr_Iter :: struct {
	idx: c.size_t, /**< next value's index */
	max: c.size_t, /**< maximum index (arr.size) */
	cur: ^Val, /**< next value */
}

/**
A JSON object iterator.

@b Example
@code
yyjson_val *key, *val;
yyjson_obj_iter iter = yyjson_obj_iter_with(obj);
while ((key = yyjson_obj_iter_next(&iter))) {
val = yyjson_obj_iter_get_val(key);
your_func(key, val);
}
@endcode

If the ordering of the keys is known at compile-time, you can use this method
to speed up value lookups:
@code
// {"k1":1, "k2": 3, "k3": 3}
yyjson_val *key, *val;
yyjson_obj_iter iter = yyjson_obj_iter_with(obj);
yyjson_val *v1 = yyjson_obj_iter_get(&iter, "k1");
yyjson_val *v3 = yyjson_obj_iter_get(&iter, "k3");
@endcode
@see yyjson_obj_iter_get() and yyjson_obj_iter_getn()
*/
Obj_Iter :: struct {
	idx: c.size_t, /**< next key's index */
	max: c.size_t, /**< maximum key index (obj.size) */
	cur: ^Val, /**< next key */
	obj: ^Val, /**< the object being iterated */
}

/**
A mutable JSON array iterator.

@warning You should not modify the array while iterating over it, but you can
use `yyjson_mut_arr_iter_remove()` to remove current value.

@b Example
@code
yyjson_mut_val *val;
yyjson_mut_arr_iter iter = yyjson_mut_arr_iter_with(arr);
while ((val = yyjson_mut_arr_iter_next(&iter))) {
your_func(val);
if (your_val_is_unused(val)) {
yyjson_mut_arr_iter_remove(&iter);
}
}
@endcode
*/
Mut_Arr_Iter :: struct {
	idx: c.size_t, /**< next value's index */
	max: c.size_t, /**< maximum index (arr.size) */
	cur: ^Mut_Val, /**< current value */
	pre: ^Mut_Val, /**< previous value */
	arr: ^Mut_Val, /**< the array being iterated */
}

/**
A mutable JSON object iterator.

@warning You should not modify the object while iterating over it, but you can
use `yyjson_mut_obj_iter_remove()` to remove current value.

@b Example
@code
yyjson_mut_val *key, *val;
yyjson_mut_obj_iter iter = yyjson_mut_obj_iter_with(obj);
while ((key = yyjson_mut_obj_iter_next(&iter))) {
val = yyjson_mut_obj_iter_get_val(key);
your_func(key, val);
if (your_val_is_unused(key, val)) {
yyjson_mut_obj_iter_remove(&iter);
}
}
@endcode

If the ordering of the keys is known at compile-time, you can use this method
to speed up value lookups:
@code
// {"k1":1, "k2": 3, "k3": 3}
yyjson_mut_val *key, *val;
yyjson_mut_obj_iter iter = yyjson_mut_obj_iter_with(obj);
yyjson_mut_val *v1 = yyjson_mut_obj_iter_get(&iter, "k1");
yyjson_mut_val *v3 = yyjson_mut_obj_iter_get(&iter, "k3");
@endcode
@see `yyjson_mut_obj_iter_get()` and `yyjson_mut_obj_iter_getn()`
*/
Mut_Obj_Iter :: struct {
	idx: c.size_t, /**< next key's index */
	max: c.size_t, /**< maximum key index (obj.size) */
	cur: ^Mut_Val, /**< current key */
	pre: ^Mut_Val, /**< previous key */
	obj: ^Mut_Val, /**< the object being iterated */
}

/** Error information for JSON pointer. */
Ptr_Err :: struct {
	/** Error code, see `yyjson_ptr_code` for all possible values. */
	code: Ptr_Code,

	/** Error message, constant, no need to free (NULL if no error). */
	msg:  cstring,

	/** Error byte position for input JSON pointer (0 if no error). */
	pos:  c.size_t,
}

/**
A context for JSON pointer operation.

This struct stores the context of JSON Pointer operation result. The struct
can be used with three helper functions: `ctx_append()`, `ctx_replace()`, and
`ctx_remove()`, which perform the corresponding operations on the container
without re-parsing the JSON Pointer.

For example:
@code
// doc before: {"a":[0,1,null]}
// ptr: "/a/2"
val = yyjson_mut_doc_ptr_getx(doc, ptr, strlen(ptr), &ctx, &err);
if (yyjson_is_null(val)) {
yyjson_ptr_ctx_remove(&ctx);
}
// doc after: {"a":[0,1]}
@endcode
*/
Ptr_Ctx :: struct {
	/**
	The container (parent) of the target value. It can be either an array or
	an object. If the target location has no value, but all its parent
	containers exist, and the target location can be used to insert a new
	value, then `ctn` is the parent container of the target location.
	Otherwise, `ctn` is NULL.
	*/
	ctn: ^Mut_Val,

	/**
	The previous sibling of the target value. It can be either a value in an
	array or a key in an object. As the container is a `circular linked list`
	of elements, `pre` is the previous node of the target value. If the
	operation is `add` or `set`, then `pre` is the previous node of the new
	value, not the original target value. If the target value does not exist,
	`pre` is NULL.
	*/
	pre: ^Mut_Val,

	/**
	The removed value if the operation is `set`, `replace` or `remove`. It can
	be used to restore the original state of the document if needed.
	*/
	old: ^Mut_Val,
}

/** Error information for JSON patch. */
Patch_Err :: struct {
	/** Error code, see `yyjson_patch_code` for all possible values. */
	code: Patch_Code,

	/** Index of the error operation (0 if no error). */
	idx:  c.size_t,

	/** Error message, constant, no need to free (NULL if no error). */
	msg:  cstring,

	/** JSON pointer error if `code == YYJSON_PATCH_ERROR_POINTER`. */
	ptr:  Ptr_Err,
}

/** Payload of a JSON value (8 bytes). */
Val_Uni :: struct #raw_union {
	_u64: u64,
	_i64: i64,
	_f64: f64,
	str:  cstring,
	ptr:  rawptr,
	ofs:  c.size_t,
}

/**
Immutable JSON value, 16 bytes.
*/
Val :: struct {
	tag: u64, /**< type, subtype and length */
	uni: Val_Uni, /**< payload */
}

Doc :: struct {
	/** Root value of the document (nonnull). */
	root:     ^Val,

	/** Allocator used by document (nonnull). */
	alc:      Alc,

	/** The total number of bytes read when parsing JSON (nonzero). */
	dat_read: c.size_t,

	/** The total number of value read when parsing JSON (nonzero). */
	val_read: c.size_t,

	/** The string pool used by JSON values (nullable). */
	str_pool: cstring,
}

/**
Mutable JSON value, 24 bytes.
The 'tag' and 'uni' field is same as immutable value.
The 'next' field links all elements inside the container to be a cycle.
*/
Mut_Val :: struct {
	tag:  u64, /**< type, subtype and length */
	uni:  Val_Uni, /**< payload */
	next: ^Mut_Val, /**< the next value in circular linked list */
}

/**
A memory chunk in string memory pool.
*/
Str_Chunk :: struct {
	next:       ^Str_Chunk, /* next chunk linked list */
	chunk_size: c.size_t, /* chunk size in bytes */
}

/**
A memory pool to hold all strings in a mutable document.
*/
Str_Pool :: struct {
	cur:            cstring, /* cursor inside current chunk */
	end:            cstring, /* the end of current chunk */
	chunk_size:     c.size_t, /* chunk size in bytes while creating new chunk */
	chunk_size_max: c.size_t, /* maximum chunk size in bytes */
	chunks:         ^Str_Chunk, /* a linked list of chunks, nullable */
}

/**
A memory chunk in value memory pool.
`sizeof(yyjson_val_chunk)` should not larger than `sizeof(yyjson_mut_val)`.
*/
Val_Chunk :: struct {
	next:       ^Val_Chunk, /* next chunk linked list */
	chunk_size: c.size_t, /* chunk size in bytes */
}

/**
A memory pool to hold all values in a mutable document.
*/
Val_Pool :: struct {
	cur:            ^Mut_Val, /* cursor inside current chunk */
	end:            ^Mut_Val, /* the end of current chunk */
	chunk_size:     c.size_t, /* chunk size in bytes while creating new chunk */
	chunk_size_max: c.size_t, /* maximum chunk size in bytes */
	chunks:         ^Val_Chunk, /* a linked list of chunks, nullable */
}

Mut_Doc :: struct {
	root:     ^Mut_Val, /**< root value of the JSON document, nullable */
	alc:      Alc, /**< a valid allocator, nonnull */
	str_pool: Str_Pool, /**< string memory pool */
	val_pool: Val_Pool, /**< value memory pool */
}

@(default_calling_convention = "c", link_prefix = "yyjson_")
foreign lib {
	/** The version of yyjson in hex, same as `YYJSON_VERSION_HEX`. */
	version :: proc() -> u32 ---

	/**
	A pool allocator uses fixed length pre-allocated memory.

	This allocator may be used to avoid malloc/realloc calls. The pre-allocated
	memory should be held by the caller. The maximum amount of memory required to
	read a JSON can be calculated using the `yyjson_read_max_memory_usage()`
	function, but the amount of memory required to write a JSON cannot be directly
	calculated.

	This is not a general-purpose allocator. It is designed to handle a single JSON
	data at a time. If it is used for overly complex memory tasks, such as parsing
	multiple JSON documents using the same allocator but releasing only a few of
	them, it may cause memory fragmentation, resulting in performance degradation
	and memory waste.

	@param alc The allocator to be initialized.
	If this parameter is NULL, the function will fail and return false.
	If `buf` or `size` is invalid, this will be set to an empty allocator.
	@param buf The buffer memory for this allocator.
	If this parameter is NULL, the function will fail and return false.
	@param size The size of `buf`, in bytes.
	If this parameter is less than 8 words (32/64 bytes on 32/64-bit OS), the
	function will fail and return false.
	@return true if the `alc` has been successfully initialized.

	@b Example
	@code
	// parse JSON with stack memory
	char buf[1024];
	yyjson_alc alc;
	yyjson_alc_pool_init(&alc, buf, 1024);

	const char *json = "{\"name\":\"Helvetica\",\"size\":16}"
	yyjson_doc *doc = yyjson_read_opts(json, strlen(json), 0, &alc, NULL);
	// the memory of `doc` is on the stack
	@endcode

	@warning This Allocator is not thread-safe.
	*/
	alc_pool_init :: proc(alc: ^Alc = nil, buf: rawptr, size: c.size_t) -> bool ---

	/**
	A dynamic allocator.

	This allocator has a similar usage to the pool allocator above. However, when
	there is not enough memory, this allocator will dynamically request more memory
	using libc's `malloc` function, and frees it all at once when it is destroyed.

	@return A new dynamic allocator, or NULL if memory allocation failed.
	@note The returned value should be freed with `yyjson_alc_dyn_free()`.

	@warning This Allocator is not thread-safe.
	*/
	alc_dyn_new :: proc() -> ^Alc ---

	/**
	Free a dynamic allocator which is created by `yyjson_alc_dyn_new()`.
	@param alc The dynamic allocator to be destroyed.
	*/
	alc_dyn_free :: proc(alc: ^Alc = nil) ---

	/**
	Locate the line and column number for a byte position in a string.
	This can be used to get better description for error position.

	@param str The input string.
	@param len The byte length of the input string.
	@param pos The byte position within the input string.
	@param line A pointer to receive the line number, starting from 1.
	@param col  A pointer to receive the column number, starting from 1.
	@param chr  A pointer to receive the character index, starting from 0.
	@return true on success, false if `str` is NULL or `pos` is out of bounds.
	@note Line/column/character are calculated based on Unicode characters for
	compatibility with text editors. For multi-byte UTF-8 characters,
	the returned value may not directly correspond to the byte position.
	*/
	locate_pos :: proc(str: cstring, len: c.size_t, pos: c.size_t, line: ^c.size_t, col: ^c.size_t, chr: ^c.size_t) -> bool ---

	/**
	Read JSON with options.

	This function is thread-safe when:
	1. The `dat` is not modified by other threads.
	2. The `alc` is thread-safe or NULL.

	@param dat The JSON data (UTF-8 without BOM), null-terminator is not required.
	If this parameter is NULL, the function will fail and return NULL.
	The `dat` will not be modified without the flag `YYJSON_READ_INSITU`, so you
	can pass a `const char *` string and case it to `char *` if you don't use
	the `YYJSON_READ_INSITU` flag.
	@param len The length of JSON data in bytes.
	If this parameter is 0, the function will fail and return NULL.
	@param flg The JSON read options.
	Multiple options can be combined with `|` operator. 0 means no options.
	@param alc The memory allocator used by JSON reader.
	Pass NULL to use the libc's default allocator.
	@param err A pointer to receive error information.
	Pass NULL if you don't need error information.
	@return A new JSON document, or NULL if an error occurs.
	When it's no longer needed, it should be freed with `yyjson_doc_free()`.
	*/
	read_opts :: proc(dat: cstring, len: c.size_t, flg: Read_Flags, alc: ^Alc = nil, err: ^Read_Err = nil) -> ^Doc ---

	/**
	Read a JSON file.

	This function is thread-safe when:
	1. The file is not modified by other threads.
	2. The `alc` is thread-safe or NULL.

	@param path The JSON file's path.
	This should be a null-terminated string using the system's native encoding.
	If this path is NULL or invalid, the function will fail and return NULL.
	@param flg The JSON read options.
	Multiple options can be combined with `|` operator. 0 means no options.
	@param alc The memory allocator used by JSON reader.
	Pass NULL to use the libc's default allocator.
	@param err A pointer to receive error information.
	Pass NULL if you don't need error information.
	@return A new JSON document, or NULL if an error occurs.
	When it's no longer needed, it should be freed with `yyjson_doc_free()`.

	@warning On 32-bit operating system, files larger than 2GB may fail to read.
	*/
	read_file :: proc(path: cstring, flg: Read_Flags, alc: ^Alc = nil, err: ^Read_Err = nil) -> ^Doc ---

	/**
	Read JSON from a file pointer.

	@param fp The file pointer.
	The data will be read from the current position of the FILE to the end.
	If this fp is NULL or invalid, the function will fail and return NULL.
	@param flg The JSON read options.
	Multiple options can be combined with `|` operator. 0 means no options.
	@param alc The memory allocator used by JSON reader.
	Pass NULL to use the libc's default allocator.
	@param err A pointer to receive error information.
	Pass NULL if you don't need error information.
	@return A new JSON document, or NULL if an error occurs.
	When it's no longer needed, it should be freed with `yyjson_doc_free()`.

	@warning On 32-bit operating system, files larger than 2GB may fail to read.
	*/
	read_fp :: proc(fp: ^libc.FILE, flg: Read_Flags, alc: ^Alc = nil, err: ^Read_Err = nil) -> ^Doc ---

	/**
	Read a JSON string.

	This function is thread-safe.

	@param dat The JSON data (UTF-8 without BOM), null-terminator is not required.
	If this parameter is NULL, the function will fail and return NULL.
	@param len The length of JSON data in bytes.
	If this parameter is 0, the function will fail and return NULL.
	@param flg The JSON read options.
	Multiple options can be combined with `|` operator. 0 means no options.
	@return A new JSON document, or NULL if an error occurs.
	When it's no longer needed, it should be freed with `yyjson_doc_free()`.
	*/
	read :: proc(dat: cstring, len: c.size_t, flg: Read_Flags) -> ^Doc ---

	/**
	Initialize state for incremental read.

	To read a large JSON document incrementally:
	1. Call `yyjson_incr_new()` to create the state for incremental reading.
	2. Call `yyjson_incr_read()` repeatedly.
	3. Call `yyjson_incr_free()` to free the state.

	Note: The incremental JSON reader only supports standard JSON.
	Flags for non-standard features (e.g. comments, trailing commas) are ignored.

	@param buf The JSON data, null-terminator is not required.
	If this parameter is NULL, the function will fail and return NULL.
	@param buf_len The length of the JSON data in `buf`.
	If use `YYJSON_READ_INSITU`, `buf_len` should not include the padding size.
	@param flg The JSON read options.
	Multiple options can be combined with `|` operator.
	@param alc The memory allocator used by JSON reader.
	Pass NULL to use the libc's default allocator.
	@return A state for incremental reading.
	It should be freed with `yyjson_incr_free()`.
	NULL is returned if memory allocation fails.
	*/
	incr_new :: proc(buf: cstring, buf_len: c.size_t, flg: Read_Flags, alc: ^Alc = nil) -> ^Incr_State ---

	/**
	Performs incremental read of up to `len` bytes.

	If NULL is returned and `err->code` is set to `YYJSON_READ_ERROR_MORE`, it
	indicates that more data is required to continue parsing. Then, call this
	function again with incremented `len`. Continue until a document is returned or
	an error other than `YYJSON_READ_ERROR_MORE` is returned.

	Note: Parsing in very small increments is not efficient. An increment of
	several kilobytes or megabytes is recommended.

	@param state The state for incremental reading, created using
	`yyjson_incr_new()`.
	@param len The number of bytes of JSON data available to parse.
	If this parameter is 0, the function will fail and return NULL.
	@param err A pointer to receive error information.
	@return A new JSON document, or NULL if an error occurs.
	When the document is no longer needed, it should be freed with
	`yyjson_doc_free()`.
	*/
	incr_read :: proc(state: ^Incr_State, len: c.size_t, err: ^Read_Err = nil) -> ^Doc ---

	/** Release the incremental read state and free the memory. */
	incr_free :: proc(state: ^Incr_State) ---

	/**
	Returns the size of maximum memory usage to read a JSON data.

	You may use this value to avoid malloc() or calloc() call inside the reader
	to get better performance, or read multiple JSON with one piece of memory.

	@param len The length of JSON data in bytes.
	@param flg The JSON read options.
	@return The maximum memory size to read this JSON, or 0 if overflow.

	@b Example
	@code
	// read multiple JSON with same pre-allocated memory

	char *dat1, *dat2, *dat3; // JSON data
	size_t len1, len2, len3; // JSON length
	size_t max_len = MAX(len1, MAX(len2, len3));
	yyjson_doc *doc;

	// use one allocator for multiple JSON
	size_t size = yyjson_read_max_memory_usage(max_len, 0);
	void *buf = malloc(size);
	yyjson_alc alc;
	yyjson_alc_pool_init(&alc, buf, size);

	// no more alloc() or realloc() call during reading
	doc = yyjson_read_opts(dat1, len1, 0, &alc, NULL);
	yyjson_doc_free(doc);
	doc = yyjson_read_opts(dat2, len2, 0, &alc, NULL);
	yyjson_doc_free(doc);
	doc = yyjson_read_opts(dat3, len3, 0, &alc, NULL);
	yyjson_doc_free(doc);

	free(buf);
	@endcode
	@see yyjson_alc_pool_init()
	*/
	read_max_memory_usage :: proc(len: c.size_t, flg: Read_Flags) -> c.size_t ---

	/**
	Read a JSON number.

	This function is thread-safe when data is not modified by other threads.

	@param dat The JSON data (UTF-8 without BOM), null-terminator is required.
	If this parameter is NULL, the function will fail and return NULL.
	@param val The output value where result is stored.
	If this parameter is NULL, the function will fail and return NULL.
	The value will hold either UINT or SINT or REAL number;
	@param flg The JSON read options.
	Multiple options can be combined with `|` operator. 0 means no options.
	Supports `YYJSON_READ_NUMBER_AS_RAW` and `YYJSON_READ_ALLOW_INF_AND_NAN`.
	@param alc The memory allocator used for long number.
	It is only used when the built-in floating point reader is disabled.
	Pass NULL to use the libc's default allocator.
	@param err A pointer to receive error information.
	Pass NULL if you don't need error information.
	@return If successful, a pointer to the character after the last character
	used in the conversion, NULL if an error occurs.
	*/
	read_number :: proc(dat: cstring, val: ^Val, flg: Read_Flags, alc: ^Alc = nil, err: ^Read_Err = nil) -> cstring ---

	/** Same as `yyjson_read_number()`. */
	mut_read_number :: proc(dat: cstring, val: ^Mut_Val, flg: Read_Flags, alc: ^Alc = nil, err: ^Read_Err = nil) -> cstring ---

	/**
	Write a document to JSON string with options.

	This function is thread-safe when:
	The `alc` is thread-safe or NULL.

	@param doc The JSON document.
	If this doc is NULL or has no root, the function will fail and return false.
	@param flg The JSON write options.
	Multiple options can be combined with `|` operator. 0 means no options.
	@param alc The memory allocator used by JSON writer.
	Pass NULL to use the libc's default allocator.
	@param len A pointer to receive output length in bytes (not including the
	null-terminator). Pass NULL if you don't need length information.
	@param err A pointer to receive error information.
	Pass NULL if you don't need error information.
	@return A new JSON string, or NULL if an error occurs.
	This string is encoded as UTF-8 with a null-terminator.
	When it's no longer needed, it should be freed with free() or alc->free().
	*/
	write_opts :: proc(doc: ^Doc, flg: Write_Flags, alc: ^Alc = nil, len: ^c.size_t = nil, err: ^Write_Err = nil) -> cstring ---

	/**
	Write a document to JSON file with options.

	This function is thread-safe when:
	1. The file is not accessed by other threads.
	2. The `alc` is thread-safe or NULL.

	@param path The JSON file's path.
	This should be a null-terminated string using the system's native encoding.
	If this path is NULL or invalid, the function will fail and return false.
	If this file is not empty, the content will be discarded.
	@param doc The JSON document.
	If this doc is NULL or has no root, the function will fail and return false.
	@param flg The JSON write options.
	Multiple options can be combined with `|` operator. 0 means no options.
	@param alc The memory allocator used by JSON writer.
	Pass NULL to use the libc's default allocator.
	@param err A pointer to receive error information.
	Pass NULL if you don't need error information.
	@return true if successful, false if an error occurs.

	@warning On 32-bit operating system, files larger than 2GB may fail to write.
	*/
	write_file :: proc(path: cstring, doc: ^Doc, flg: Write_Flags, alc: ^Alc = nil, err: ^Write_Err = nil) -> bool ---

	/**
	Write a document to file pointer with options.

	@param fp The file pointer.
	The data will be written to the current position of the file.
	If this fp is NULL or invalid, the function will fail and return false.
	@param doc The JSON document.
	If this doc is NULL or has no root, the function will fail and return false.
	@param flg The JSON write options.
	Multiple options can be combined with `|` operator. 0 means no options.
	@param alc The memory allocator used by JSON writer.
	Pass NULL to use the libc's default allocator.
	@param err A pointer to receive error information.
	Pass NULL if you don't need error information.
	@return true if successful, false if an error occurs.

	@warning On 32-bit operating system, files larger than 2GB may fail to write.
	*/
	write_fp :: proc(fp: ^libc.FILE, doc: ^Doc, flg: Write_Flags, alc: ^Alc = nil, err: ^Write_Err = nil) -> bool ---

	/**
	Write a document into a buffer.

	This function does not allocate memory, but the buffer must be larger than the
	final JSON size to allow temporary space. See `API.md` for details.

	@param buf The output buffer.
	If the buffer is NULL, the function will fail and return 0.
	@param buf_len The buffer length.
	If the buf_len is too small, the function will fail and return 0.
	@param doc doc The JSON document.
	If this doc is NULL or has no root, the function will fail and return 0.
	@param flg flg The JSON write options.
	Multiple options can be combined with `|` operator. 0 means no options.
	@param err err A pointer to receive error information.
	Pass NULL if you don't need error information.
	@return The number of bytes written (excluding the null terminator),
	or 0 on failure.
	*/
	write_buf :: proc(buf: cstring, buf_len: c.size_t, doc: ^Doc, flg: Write_Flags, err: ^Write_Err = nil) -> c.size_t ---

	/**
	Write a document to JSON string.

	This function is thread-safe.

	@param doc The JSON document.
	If this doc is NULL or has no root, the function will fail and return false.
	@param flg The JSON write options.
	Multiple options can be combined with `|` operator. 0 means no options.
	@param len A pointer to receive output length in bytes (not including the
	null-terminator). Pass NULL if you don't need length information.
	@return A new JSON string, or NULL if an error occurs.
	This string is encoded as UTF-8 with a null-terminator.
	When it's no longer needed, it should be freed with free().
	*/
	write :: proc(doc: ^Doc, flg: Write_Flags, len: ^c.size_t) -> cstring ---

	/**
	Write a document to JSON string with options.

	This function is thread-safe when:
	1. The `doc` is not modified by other threads.
	2. The `alc` is thread-safe or NULL.

	@param doc The mutable JSON document.
	If this doc is NULL or has no root, the function will fail and return false.
	@param flg The JSON write options.
	Multiple options can be combined with `|` operator. 0 means no options.
	@param alc The memory allocator used by JSON writer.
	Pass NULL to use the libc's default allocator.
	@param len A pointer to receive output length in bytes (not including the
	null-terminator). Pass NULL if you don't need length information.
	@param err A pointer to receive error information.
	Pass NULL if you don't need error information.
	@return A new JSON string, or NULL if an error occurs.
	This string is encoded as UTF-8 with a null-terminator.
	When it's no longer needed, it should be freed with free() or alc->free().
	*/
	mut_write_opts :: proc(doc: ^Mut_Doc, flg: Write_Flags, alc: ^Alc = nil, len: ^c.size_t = nil, err: ^Write_Err = nil) -> cstring ---

	/**
	Write a document to JSON file with options.

	This function is thread-safe when:
	1. The file is not accessed by other threads.
	2. The `doc` is not modified by other threads.
	3. The `alc` is thread-safe or NULL.

	@param path The JSON file's path.
	This should be a null-terminated string using the system's native encoding.
	If this path is NULL or invalid, the function will fail and return false.
	If this file is not empty, the content will be discarded.
	@param doc The mutable JSON document.
	If this doc is NULL or has no root, the function will fail and return false.
	@param flg The JSON write options.
	Multiple options can be combined with `|` operator. 0 means no options.
	@param alc The memory allocator used by JSON writer.
	Pass NULL to use the libc's default allocator.
	@param err A pointer to receive error information.
	Pass NULL if you don't need error information.
	@return true if successful, false if an error occurs.

	@warning On 32-bit operating system, files larger than 2GB may fail to write.
	*/
	mut_write_file :: proc(path: cstring, doc: ^Mut_Doc, flg: Write_Flags, alc: ^Alc = nil, err: ^Write_Err = nil) -> bool ---

	/**
	Write a document to file pointer with options.

	@param fp The file pointer.
	The data will be written to the current position of the file.
	If this fp is NULL or invalid, the function will fail and return false.
	@param doc The mutable JSON document.
	If this doc is NULL or has no root, the function will fail and return false.
	@param flg The JSON write options.
	Multiple options can be combined with `|` operator. 0 means no options.
	@param alc The memory allocator used by JSON writer.
	Pass NULL to use the libc's default allocator.
	@param err A pointer to receive error information.
	Pass NULL if you don't need error information.
	@return true if successful, false if an error occurs.

	@warning On 32-bit operating system, files larger than 2GB may fail to write.
	*/
	mut_write_fp :: proc(fp: ^libc.FILE, doc: ^Mut_Doc, flg: Write_Flags, alc: ^Alc = nil, err: ^Write_Err = nil) -> bool ---

	/**
	Write a document into a buffer.

	This function does not allocate memory, but the buffer must be larger than the
	final JSON size to allow temporary space. See `API.md` for details.

	@param buf The output buffer.
	If the buffer is NULL, the function will fail and return 0.
	@param buf_len The buffer length.
	If the buf_len is too small, the function will fail and return 0.
	@param doc doc The JSON document.
	If this doc is NULL or has no root, the function will fail and return 0.
	@param flg flg The JSON write options.
	Multiple options can be combined with `|` operator. 0 means no options.
	@param err err A pointer to receive error information.
	Pass NULL if you don't need error information.
	@return The number of bytes written (excluding the null terminator),
	or 0 on failure.
	*/
	mut_write_buf :: proc(buf: cstring, buf_len: c.size_t, doc: ^Mut_Doc, flg: Write_Flags, err: ^Write_Err = nil) -> c.size_t ---

	/**
	Write a document to JSON string.

	This function is thread-safe when:
	The `doc` is not modified by other threads.

	@param doc The JSON document.
	If this doc is NULL or has no root, the function will fail and return false.
	@param flg The JSON write options.
	Multiple options can be combined with `|` operator. 0 means no options.
	@param len A pointer to receive output length in bytes (not including the
	null-terminator). Pass NULL if you don't need length information.
	@return A new JSON string, or NULL if an error occurs.
	This string is encoded as UTF-8 with a null-terminator.
	When it's no longer needed, it should be freed with free().
	*/
	mut_write :: proc(doc: ^Mut_Doc, flg: Write_Flags, len: ^c.size_t) -> cstring ---

	/**
	Write a value to JSON string with options.

	This function is thread-safe when:
	The `alc` is thread-safe or NULL.

	@param val The JSON root value.
	If this parameter is NULL, the function will fail and return NULL.
	@param flg The JSON write options.
	Multiple options can be combined with `|` operator. 0 means no options.
	@param alc The memory allocator used by JSON writer.
	Pass NULL to use the libc's default allocator.
	@param len A pointer to receive output length in bytes (not including the
	null-terminator). Pass NULL if you don't need length information.
	@param err A pointer to receive error information.
	Pass NULL if you don't need error information.
	@return A new JSON string, or NULL if an error occurs.
	This string is encoded as UTF-8 with a null-terminator.
	When it's no longer needed, it should be freed with free() or alc->free().
	*/
	val_write_opts :: proc(val: ^Val, flg: Write_Flags, alc: ^Alc = nil, len: ^c.size_t = nil, err: ^Write_Err = nil) -> cstring ---

	/**
	Write a value to JSON file with options.

	This function is thread-safe when:
	1. The file is not accessed by other threads.
	2. The `alc` is thread-safe or NULL.

	@param path The JSON file's path.
	This should be a null-terminated string using the system's native encoding.
	If this path is NULL or invalid, the function will fail and return false.
	If this file is not empty, the content will be discarded.
	@param val The JSON root value.
	If this parameter is NULL, the function will fail and return NULL.
	@param flg The JSON write options.
	Multiple options can be combined with `|` operator. 0 means no options.
	@param alc The memory allocator used by JSON writer.
	Pass NULL to use the libc's default allocator.
	@param err A pointer to receive error information.
	Pass NULL if you don't need error information.
	@return true if successful, false if an error occurs.

	@warning On 32-bit operating system, files larger than 2GB may fail to write.
	*/
	val_write_file :: proc(path: cstring, val: ^Val, flg: Write_Flags, alc: ^Alc = nil, err: ^Write_Err = nil) -> bool ---

	/**
	Write a value to file pointer with options.

	@param fp The file pointer.
	The data will be written to the current position of the file.
	If this path is NULL or invalid, the function will fail and return false.
	@param val The JSON root value.
	If this parameter is NULL, the function will fail and return NULL.
	@param flg The JSON write options.
	Multiple options can be combined with `|` operator. 0 means no options.
	@param alc The memory allocator used by JSON writer.
	Pass NULL to use the libc's default allocator.
	@param err A pointer to receive error information.
	Pass NULL if you don't need error information.
	@return true if successful, false if an error occurs.

	@warning On 32-bit operating system, files larger than 2GB may fail to write.
	*/
	val_write_fp :: proc(fp: ^libc.FILE, val: ^Val, flg: Write_Flags, alc: ^Alc = nil, err: ^Write_Err = nil) -> bool ---

	/**
	Write a value into a buffer.

	This function does not allocate memory, but the buffer must be larger than the
	final JSON size to allow temporary space. See `API.md` for details.

	@param buf The output buffer.
	If the buffer is NULL, the function will fail and return 0.
	@param buf_len The buffer length.
	If the buf_len is too small, the function will fail and return 0.
	@param val The JSON root value.
	If this parameter is NULL, the function will fail and return NULL.
	@param flg flg The JSON write options.
	Multiple options can be combined with `|` operator. 0 means no options.
	@param err err A pointer to receive error information.
	Pass NULL if you don't need error information.
	@return The number of bytes written (excluding the null terminator),
	or 0 on failure.
	*/
	val_write_buf :: proc(buf: cstring, buf_len: c.size_t, val: ^Val, flg: Write_Flags, err: ^Write_Err = nil) -> c.size_t ---

	/**
	Write a value to JSON string.

	This function is thread-safe.

	@param val The JSON root value.
	If this parameter is NULL, the function will fail and return NULL.
	@param flg The JSON write options.
	Multiple options can be combined with `|` operator. 0 means no options.
	@param len A pointer to receive output length in bytes (not including the
	null-terminator). Pass NULL if you don't need length information.
	@return A new JSON string, or NULL if an error occurs.
	This string is encoded as UTF-8 with a null-terminator.
	When it's no longer needed, it should be freed with free().
	*/
	val_write :: proc(val: ^Val, flg: Write_Flags, len: ^c.size_t) -> cstring ---

	/**
	Write a value to JSON string with options.

	This function is thread-safe when:
	1. The `val` is not modified by other threads.
	2. The `alc` is thread-safe or NULL.

	@param val The mutable JSON root value.
	If this parameter is NULL, the function will fail and return NULL.
	@param flg The JSON write options.
	Multiple options can be combined with `|` operator. 0 means no options.
	@param alc The memory allocator used by JSON writer.
	Pass NULL to use the libc's default allocator.
	@param len A pointer to receive output length in bytes (not including the
	null-terminator). Pass NULL if you don't need length information.
	@param err A pointer to receive error information.
	Pass NULL if you don't need error information.
	@return  A new JSON string, or NULL if an error occurs.
	This string is encoded as UTF-8 with a null-terminator.
	When it's no longer needed, it should be freed with free() or alc->free().
	*/
	mut_val_write_opts :: proc(val: ^Mut_Val, flg: Write_Flags, alc: ^Alc = nil, len: ^c.size_t = nil, err: ^Write_Err = nil) -> cstring ---

	/**
	Write a value to JSON file with options.

	This function is thread-safe when:
	1. The file is not accessed by other threads.
	2. The `val` is not modified by other threads.
	3. The `alc` is thread-safe or NULL.

	@param path The JSON file's path.
	This should be a null-terminated string using the system's native encoding.
	If this path is NULL or invalid, the function will fail and return false.
	If this file is not empty, the content will be discarded.
	@param val The mutable JSON root value.
	If this parameter is NULL, the function will fail and return NULL.
	@param flg The JSON write options.
	Multiple options can be combined with `|` operator. 0 means no options.
	@param alc The memory allocator used by JSON writer.
	Pass NULL to use the libc's default allocator.
	@param err A pointer to receive error information.
	Pass NULL if you don't need error information.
	@return true if successful, false if an error occurs.

	@warning On 32-bit operating system, files larger than 2GB may fail to write.
	*/
	mut_val_write_file :: proc(path: cstring, val: ^Mut_Val, flg: Write_Flags, alc: ^Alc = nil, err: ^Write_Err = nil) -> bool ---

	/**
	Write a value to JSON file with options.

	@param fp The file pointer.
	The data will be written to the current position of the file.
	If this path is NULL or invalid, the function will fail and return false.
	@param val The mutable JSON root value.
	If this parameter is NULL, the function will fail and return NULL.
	@param flg The JSON write options.
	Multiple options can be combined with `|` operator. 0 means no options.
	@param alc The memory allocator used by JSON writer.
	Pass NULL to use the libc's default allocator.
	@param err A pointer to receive error information.
	Pass NULL if you don't need error information.
	@return true if successful, false if an error occurs.

	@warning On 32-bit operating system, files larger than 2GB may fail to write.
	*/
	mut_val_write_fp :: proc(fp: ^libc.FILE, val: ^Mut_Val, flg: Write_Flags, alc: ^Alc = nil, err: ^Write_Err = nil) -> bool ---

	/**
	Write a value into a buffer.

	This function does not allocate memory, but the buffer must be larger than the
	final JSON size to allow temporary space. See `API.md` for details.

	@param buf The output buffer.
	If the buffer is NULL, the function will fail and return 0.
	@param buf_len The buffer length.
	If the buf_len is too small, the function will fail and return 0.
	@param val The JSON root value.
	If this parameter is NULL, the function will fail and return NULL.
	@param flg flg The JSON write options.
	Multiple options can be combined with `|` operator. 0 means no options.
	@param err err A pointer to receive error information.
	Pass NULL if you don't need error information.
	@return The number of bytes written (excluding the null terminator),
	or 0 on failure.
	*/
	mut_val_write_buf :: proc(buf: cstring, buf_len: c.size_t, val: ^Mut_Val, flg: Write_Flags, err: ^Write_Err = nil) -> c.size_t ---

	/**
	Write a value to JSON string.

	This function is thread-safe when:
	The `val` is not modified by other threads.

	@param val The JSON root value.
	If this parameter is NULL, the function will fail and return NULL.
	@param flg The JSON write options.
	Multiple options can be combined with `|` operator. 0 means no options.
	@param len A pointer to receive output length in bytes (not including the
	null-terminator). Pass NULL if you don't need length information.
	@return A new JSON string, or NULL if an error occurs.
	This string is encoded as UTF-8 with a null-terminator.
	When it's no longer needed, it should be freed with free().
	*/
	mut_val_write :: proc(val: ^Mut_Val, flg: Write_Flags, len: ^c.size_t) -> cstring ---

	/**
	Write a JSON number.

	@param val A JSON number value to be converted to a string.
	If this parameter is invalid, the function will fail and return NULL.
	@param buf A buffer to store the resulting null-terminated string.
	If this parameter is NULL, the function will fail and return NULL.
	For integer values, the buffer must be at least 21 bytes.
	For floating-point values, the buffer must be at least 40 bytes.
	@return On success, returns a pointer to the character after the last
	written character. On failure, returns NULL.
	@note
	- This function is thread-safe and does not allocate memory
	(when `YYJSON_DISABLE_FAST_FP_CONV` is not defined).
	- This function will fail and return NULL only in the following cases:
	1) `val` or `buf` is NULL;
	2) `val` is not a number type;
	3) `val` is `inf` or `nan`, and non-standard JSON is explicitly disabled
	via the `YYJSON_DISABLE_NON_STANDARD` flag.
	*/
	write_number :: proc(val: ^Val, buf: cstring) -> cstring ---

	/** Same as `yyjson_write_number()`. */
	mut_write_number :: proc(val: ^Mut_Val, buf: cstring) -> cstring ---

	/** Returns the root value of this JSON document.
	Returns NULL if `doc` is NULL. */
	doc_get_root :: proc(doc: ^Doc) -> ^Val ---

	/** Returns read size of input JSON data.
	Returns 0 if `doc` is NULL.
	For example: the read size of `[1,2,3]` is 7 bytes.  */
	doc_get_read_size :: proc(doc: ^Doc) -> c.size_t ---

	/** Returns total value count in this JSON document.
	Returns 0 if `doc` is NULL.
	For example: the value count of `[1,2,3]` is 4. */
	doc_get_val_count :: proc(doc: ^Doc) -> c.size_t ---

	/** Release the JSON document and free the memory.
	After calling this function, the `doc` and all values from the `doc` are no
	longer available. This function will do nothing if the `doc` is NULL. */
	doc_free :: proc(doc: ^Doc) ---

	/** Returns whether the JSON value is raw.
	Returns false if `val` is NULL. */
	is_raw :: proc(val: ^Val) -> bool ---

	/** Returns whether the JSON value is `null`.
	Returns false if `val` is NULL. */
	is_null :: proc(val: ^Val) -> bool ---

	/** Returns whether the JSON value is `true`.
	Returns false if `val` is NULL. */
	is_true :: proc(val: ^Val) -> bool ---

	/** Returns whether the JSON value is `false`.
	Returns false if `val` is NULL. */
	is_false :: proc(val: ^Val) -> bool ---

	/** Returns whether the JSON value is bool (true/false).
	Returns false if `val` is NULL. */
	is_bool :: proc(val: ^Val) -> bool ---

	/** Returns whether the JSON value is unsigned integer (uint64_t).
	Returns false if `val` is NULL. */
	is_uint :: proc(val: ^Val) -> bool ---

	/** Returns whether the JSON value is signed integer (int64_t).
	Returns false if `val` is NULL. */
	is_sint :: proc(val: ^Val) -> bool ---

	/** Returns whether the JSON value is integer (uint64_t/int64_t).
	Returns false if `val` is NULL. */
	is_int :: proc(val: ^Val) -> bool ---

	/** Returns whether the JSON value is real number (double).
	Returns false if `val` is NULL. */
	is_real :: proc(val: ^Val) -> bool ---

	/** Returns whether the JSON value is number (uint64_t/int64_t/double).
	Returns false if `val` is NULL. */
	is_num :: proc(val: ^Val) -> bool ---

	/** Returns whether the JSON value is string.
	Returns false if `val` is NULL. */
	is_str :: proc(val: ^Val) -> bool ---

	/** Returns whether the JSON value is array.
	Returns false if `val` is NULL. */
	is_arr :: proc(val: ^Val) -> bool ---

	/** Returns whether the JSON value is object.
	Returns false if `val` is NULL. */
	is_obj :: proc(val: ^Val) -> bool ---

	/** Returns whether the JSON value is container (array/object).
	Returns false if `val` is NULL. */
	is_ctn :: proc(val: ^Val) -> bool ---

	/** Returns the JSON value's type.
	Returns YYJSON_TYPE_NONE if `val` is NULL. */
	get_type :: proc(val: ^Val) -> Type ---

	/** Returns the JSON value's subtype.
	Returns YYJSON_SUBTYPE_NONE if `val` is NULL. */
	get_subtype :: proc(val: ^Val) -> Subtype ---

	/** Returns the JSON value's tag.
	Returns 0 if `val` is NULL. */
	get_tag :: proc(val: ^Val) -> u8 ---

	/** Returns the JSON value's type description.
	The return value should be one of these strings: "raw", "null", "string",
	"array", "object", "true", "false", "uint", "sint", "real", "unknown". */
	get_type_desc :: proc(val: ^Val) -> cstring ---

	/** Returns the content if the value is raw.
	Returns NULL if `val` is NULL or type is not raw. */
	get_raw :: proc(val: ^Val) -> cstring ---

	/** Returns the content if the value is bool.
	Returns false if `val` is NULL or type is not bool. */
	get_bool :: proc(val: ^Val) -> bool ---

	/** Returns the content and cast to uint64_t.
	Returns 0 if `val` is NULL or type is not integer(sint/uint). */
	get_uint :: proc(val: ^Val) -> u64 ---

	/** Returns the content and cast to int64_t.
	Returns 0 if `val` is NULL or type is not integer(sint/uint). */
	get_sint :: proc(val: ^Val) -> i64 ---

	/** Returns the content and cast to int.
	Returns 0 if `val` is NULL or type is not integer(sint/uint). */
	get_int :: proc(val: ^Val) -> i32 ---

	/** Returns the content if the value is real number, or 0.0 on error.
	Returns 0.0 if `val` is NULL or type is not real(double). */
	get_real :: proc(val: ^Val) -> f64 ---

	/** Returns the content and typecast to `double` if the value is number.
	Returns 0.0 if `val` is NULL or type is not number(uint/sint/real). */
	get_num :: proc(val: ^Val) -> f64 ---

	/** Returns the content if the value is string.
	Returns NULL if `val` is NULL or type is not string. */
	get_str :: proc(val: ^Val) -> cstring ---

	/** Returns the content length (string length, array size, object size.
	Returns 0 if `val` is NULL or type is not string/array/object. */
	get_len :: proc(val: ^Val) -> c.size_t ---

	/** Returns whether the JSON value is equals to a string.
	Returns false if input is NULL or type is not string. */
	equals_str :: proc(val: ^Val, str: cstring) -> bool ---

	/** Returns whether the JSON value is equals to a string.
	The `str` should be a UTF-8 string, null-terminator is not required.
	Returns false if input is NULL or type is not string. */
	equals_strn :: proc(val: ^Val, str: cstring, len: c.size_t) -> bool ---

	/** Returns whether two JSON values are equal (deep compare).
	Returns false if input is NULL.
	@note the result may be inaccurate if object has duplicate keys.
	@warning This function is recursive and may cause a stack overflow
	if the object level is too deep. */
	equals :: proc(lhs: ^Val, rhs: ^Val) -> bool ---

	/** Set the value to raw.
	Returns false if input is NULL or `val` is object or array.
	@warning This will modify the `immutable` value, use with caution. */
	set_raw :: proc(val: ^Val, raw: cstring, len: c.size_t) -> bool ---

	/** Set the value to null.
	Returns false if input is NULL or `val` is object or array.
	@warning This will modify the `immutable` value, use with caution. */
	set_null :: proc(val: ^Val) -> bool ---

	/** Set the value to bool.
	Returns false if input is NULL or `val` is object or array.
	@warning This will modify the `immutable` value, use with caution. */
	set_bool :: proc(val: ^Val, num: bool) -> bool ---

	/** Set the value to uint.
	Returns false if input is NULL or `val` is object or array.
	@warning This will modify the `immutable` value, use with caution. */
	set_uint :: proc(val: ^Val, num: u64) -> bool ---

	/** Set the value to sint.
	Returns false if input is NULL or `val` is object or array.
	@warning This will modify the `immutable` value, use with caution. */
	set_sint :: proc(val: ^Val, num: i64) -> bool ---

	/** Set the value to int.
	Returns false if input is NULL or `val` is object or array.
	@warning This will modify the `immutable` value, use with caution. */
	set_int :: proc(val: ^Val, num: i64) -> bool ---

	/** Set the value to float.
	Returns false if input is NULL or `val` is object or array.
	@warning This will modify the `immutable` value, use with caution. */
	set_float :: proc(val: ^Val, num: f32) -> bool ---

	/** Set the value to double.
	Returns false if input is NULL or `val` is object or array.
	@warning This will modify the `immutable` value, use with caution. */
	set_double :: proc(val: ^Val, num: f64) -> bool ---

	/** Set the value to real.
	Returns false if input is NULL or `val` is object or array.
	@warning This will modify the `immutable` value, use with caution. */
	set_real :: proc(val: ^Val, num: f64) -> bool ---

	/** Set the floating-point number's output format to fixed-point notation.
	Returns false if input is NULL or `val` is not real type.
	@see YYJSON_WRITE_FP_TO_FIXED flag.
	@warning This will modify the `immutable` value, use with caution. */
	set_fp_to_fixed :: proc(val: ^Val, prec: i32) -> bool ---

	/** Set the floating-point number's output format to single-precision.
	Returns false if input is NULL or `val` is not real type.
	@see YYJSON_WRITE_FP_TO_FLOAT flag.
	@warning This will modify the `immutable` value, use with caution. */
	set_fp_to_float :: proc(val: ^Val, flt: bool) -> bool ---

	/** Set the value to string (null-terminated).
	Returns false if input is NULL or `val` is object or array.
	@warning This will modify the `immutable` value, use with caution. */
	set_str :: proc(val: ^Val, str: cstring) -> bool ---

	/** Set the value to string (with length).
	Returns false if input is NULL or `val` is object or array.
	@warning This will modify the `immutable` value, use with caution. */
	set_strn :: proc(val: ^Val, str: cstring, len: c.size_t) -> bool ---

	/** Marks this string as not needing to be escaped during JSON writing.
	This can be used to avoid the overhead of escaping if the string contains
	only characters that do not require escaping.
	Returns false if input is NULL or `val` is not string.
	@see YYJSON_SUBTYPE_NOESC subtype.
	@warning This will modify the `immutable` value, use with caution. */
	set_str_noesc :: proc(val: ^Val, noesc: bool) -> bool ---

	/** Returns the number of elements in this array.
	Returns 0 if `arr` is NULL or type is not array. */
	arr_size :: proc(arr: ^Val) -> c.size_t ---

	/** Returns the element at the specified position in this array.
	Returns NULL if array is NULL/empty or the index is out of bounds.
	@warning This function takes a linear search time if array is not flat.
	For example: `[1,{},3]` is flat, `[1,[2],3]` is not flat. */
	arr_get :: proc(arr: ^Val, idx: c.size_t) -> ^Val ---

	/** Returns the first element of this array.
	Returns NULL if `arr` is NULL/empty or type is not array. */
	arr_get_first :: proc(arr: ^Val) -> ^Val ---

	/** Returns the last element of this array.
	Returns NULL if `arr` is NULL/empty or type is not array.
	@warning This function takes a linear search time if array is not flat.
	For example: `[1,{},3]` is flat, `[1,[2],3]` is not flat.*/
	arr_get_last :: proc(arr: ^Val) -> ^Val ---

	/**
	Initialize an iterator for this array.

	@param arr The array to be iterated over.
	If this parameter is NULL or not an array, `iter` will be set to empty.
	@param iter The iterator to be initialized.
	If this parameter is NULL, the function will fail and return false.
	@return true if the `iter` has been successfully initialized.

	@note The iterator does not need to be destroyed.
	*/
	arr_iter_init :: proc(arr: ^Val, iter: ^Arr_Iter) -> bool ---

	/**
	Create an iterator with an array , same as `yyjson_arr_iter_init()`.

	@param arr The array to be iterated over.
	If this parameter is NULL or not an array, an empty iterator will returned.
	@return A new iterator for the array.

	@note The iterator does not need to be destroyed.
	*/
	arr_iter_with :: proc(arr: ^Val) -> Arr_Iter ---

	/**
	Returns whether the iteration has more elements.
	If `iter` is NULL, this function will return false.
	*/
	arr_iter_has_next :: proc(iter: ^Arr_Iter) -> bool ---

	/**
	Returns the next element in the iteration, or NULL on end.
	If `iter` is NULL, this function will return NULL.
	*/
	arr_iter_next :: proc(iter: ^Arr_Iter) -> ^Val ---

	/** Returns the number of key-value pairs in this object.
	Returns 0 if `obj` is NULL or type is not object. */
	obj_size :: proc(obj: ^Val) -> c.size_t ---

	/** Returns the value to which the specified key is mapped.
	Returns NULL if this object contains no mapping for the key.
	Returns NULL if `obj/key` is NULL, or type is not object.

	The `key` should be a null-terminated UTF-8 string.

	@warning This function takes a linear search time. */
	obj_get :: proc(obj: ^Val, key: cstring) -> ^Val ---

	/** Returns the value to which the specified key is mapped.
	Returns NULL if this object contains no mapping for the key.
	Returns NULL if `obj/key` is NULL, or type is not object.

	The `key` should be a UTF-8 string, null-terminator is not required.
	The `key_len` should be the length of the key, in bytes.

	@warning This function takes a linear search time. */
	obj_getn :: proc(obj: ^Val, key: cstring, key_len: c.size_t) -> ^Val ---

	/**
	Initialize an iterator for this object.

	@param obj The object to be iterated over.
	If this parameter is NULL or not an object, `iter` will be set to empty.
	@param iter The iterator to be initialized.
	If this parameter is NULL, the function will fail and return false.
	@return true if the `iter` has been successfully initialized.

	@note The iterator does not need to be destroyed.
	*/
	obj_iter_init :: proc(obj: ^Val, iter: ^Obj_Iter) -> bool ---

	/**
	Create an iterator with an object, same as `yyjson_obj_iter_init()`.

	@param obj The object to be iterated over.
	If this parameter is NULL or not an object, an empty iterator will returned.
	@return A new iterator for the object.

	@note The iterator does not need to be destroyed.
	*/
	obj_iter_with :: proc(obj: ^Val) -> Obj_Iter ---

	/**
	Returns whether the iteration has more elements.
	If `iter` is NULL, this function will return false.
	*/
	obj_iter_has_next :: proc(iter: ^Obj_Iter) -> bool ---

	/**
	Returns the next key in the iteration, or NULL on end.
	If `iter` is NULL, this function will return NULL.
	*/
	obj_iter_next :: proc(iter: ^Obj_Iter) -> ^Val ---

	/**
	Returns the value for key inside the iteration.
	If `iter` is NULL, this function will return NULL.
	*/
	obj_iter_get_val :: proc(key: ^Val) -> ^Val ---

	/**
	Iterates to a specified key and returns the value.

	This function does the same thing as `yyjson_obj_get()`, but is much faster
	if the ordering of the keys is known at compile-time and you are using the same
	order to look up the values. If the key exists in this object, then the
	iterator will stop at the next key, otherwise the iterator will not change and
	NULL is returned.

	@param iter The object iterator, should not be NULL.
	@param key The key, should be a UTF-8 string with null-terminator.
	@return The value to which the specified key is mapped.
	NULL if this object contains no mapping for the key or input is invalid.

	@warning This function takes a linear search time if the key is not nearby.
	*/
	obj_iter_get :: proc(iter: ^Obj_Iter, key: cstring) -> ^Val ---

	/**
	Iterates to a specified key and returns the value.

	This function does the same thing as `yyjson_obj_getn()`, but is much faster
	if the ordering of the keys is known at compile-time and you are using the same
	order to look up the values. If the key exists in this object, then the
	iterator will stop at the next key, otherwise the iterator will not change and
	NULL is returned.

	@param iter The object iterator, should not be NULL.
	@param key The key, should be a UTF-8 string, null-terminator is not required.
	@param key_len The the length of `key`, in bytes.
	@return The value to which the specified key is mapped.
	NULL if this object contains no mapping for the key or input is invalid.

	@warning This function takes a linear search time if the key is not nearby.
	*/
	obj_iter_getn :: proc(iter: ^Obj_Iter, key: cstring, key_len: c.size_t) -> ^Val ---

	/** Returns the root value of this JSON document.
	Returns NULL if `doc` is NULL. */
	mut_doc_get_root :: proc(doc: ^Mut_Doc) -> ^Mut_Val ---

	/** Sets the root value of this JSON document.
	Pass NULL to clear root value of the document. */
	mut_doc_set_root :: proc(doc: ^Mut_Doc, root: ^Mut_Val) ---

	/**
	Set the string pool size for a mutable document.
	This function does not allocate memory immediately, but uses the size when
	the next memory allocation is needed.

	If the caller knows the approximate bytes of strings that the document needs to
	store (e.g. copy string with `yyjson_mut_strcpy` function), setting a larger
	size can avoid multiple memory allocations and improve performance.

	@param doc The mutable document.
	@param len The desired string pool size in bytes (total string length).
	@return true if successful, false if size is 0 or overflow.
	*/
	mut_doc_set_str_pool_size :: proc(doc: ^Mut_Doc, len: c.size_t) -> bool ---

	/**
	Set the value pool size for a mutable document.
	This function does not allocate memory immediately, but uses the size when
	the next memory allocation is needed.

	If the caller knows the approximate number of values that the document needs to
	store (e.g. create new value with `yyjson_mut_xxx` functions), setting a larger
	size can avoid multiple memory allocations and improve performance.

	@param doc The mutable document.
	@param count The desired value pool size (number of `yyjson_mut_val`).
	@return true if successful, false if size is 0 or overflow.
	*/
	mut_doc_set_val_pool_size :: proc(doc: ^Mut_Doc, count: c.size_t) -> bool ---

	/** Release the JSON document and free the memory.
	After calling this function, the `doc` and all values from the `doc` are no
	longer available. This function will do nothing if the `doc` is NULL.  */
	mut_doc_free :: proc(doc: ^Mut_Doc) ---

	/** Creates and returns a new mutable JSON document, returns NULL on error.
	If allocator is NULL, the default allocator will be used. */
	mut_doc_new :: proc(alc: ^Alc = nil) -> ^Mut_Doc ---

	/** Copies and returns a new mutable document from input, returns NULL on error.
	This makes a `deep-copy` on the immutable document.
	If allocator is NULL, the default allocator will be used.
	@note `imut_doc` -> `mut_doc`. */
	doc_mut_copy :: proc(doc: ^Doc, alc: ^Alc = nil) -> ^Mut_Doc ---

	/** Copies and returns a new mutable document from input, returns NULL on error.
	This makes a `deep-copy` on the mutable document.
	If allocator is NULL, the default allocator will be used.
	@note `mut_doc` -> `mut_doc`. */
	mut_doc_mut_copy :: proc(doc: ^Mut_Doc, alc: ^Alc = nil) -> ^Mut_Doc ---

	/** Copies and returns a new mutable value from input, returns NULL on error.
	This makes a `deep-copy` on the immutable value.
	The memory was managed by mutable document.
	@note `imut_val` -> `mut_val`. */
	val_mut_copy :: proc(doc: ^Mut_Doc, val: ^Val) -> ^Mut_Val ---

	/** Copies and returns a new mutable value from input, returns NULL on error.
	This makes a `deep-copy` on the mutable value.
	The memory was managed by mutable document.
	@note `mut_val` -> `mut_val`.
	@warning This function is recursive and may cause a stack overflow
	if the object level is too deep. */
	mut_val_mut_copy :: proc(doc: ^Mut_Doc, val: ^Mut_Val) -> ^Mut_Val ---

	/** Copies and returns a new immutable document from input,
	returns NULL on error. This makes a `deep-copy` on the mutable document.
	The returned document should be freed with `yyjson_doc_free()`.
	@note `mut_doc` -> `imut_doc`.
	@warning This function is recursive and may cause a stack overflow
	if the object level is too deep. */
	mut_doc_imut_copy :: proc(doc: ^Mut_Doc, alc: ^Alc = nil) -> ^Doc ---

	/** Copies and returns a new immutable document from input,
	returns NULL on error. This makes a `deep-copy` on the mutable value.
	The returned document should be freed with `yyjson_doc_free()`.
	@note `mut_val` -> `imut_doc`.
	@warning This function is recursive and may cause a stack overflow
	if the object level is too deep. */
	mut_val_imut_copy :: proc(val: ^Mut_Val, alc: ^Alc = nil) -> ^Doc ---

	/** Returns whether the JSON value is raw.
	Returns false if `val` is NULL. */
	mut_is_raw :: proc(val: ^Mut_Val) -> bool ---

	/** Returns whether the JSON value is `null`.
	Returns false if `val` is NULL. */
	mut_is_null :: proc(val: ^Mut_Val) -> bool ---

	/** Returns whether the JSON value is `true`.
	Returns false if `val` is NULL. */
	mut_is_true :: proc(val: ^Mut_Val) -> bool ---

	/** Returns whether the JSON value is `false`.
	Returns false if `val` is NULL. */
	mut_is_false :: proc(val: ^Mut_Val) -> bool ---

	/** Returns whether the JSON value is bool (true/false).
	Returns false if `val` is NULL. */
	mut_is_bool :: proc(val: ^Mut_Val) -> bool ---

	/** Returns whether the JSON value is unsigned integer (uint64_t).
	Returns false if `val` is NULL. */
	mut_is_uint :: proc(val: ^Mut_Val) -> bool ---

	/** Returns whether the JSON value is signed integer (int64_t).
	Returns false if `val` is NULL. */
	mut_is_sint :: proc(val: ^Mut_Val) -> bool ---

	/** Returns whether the JSON value is integer (uint64_t/int64_t).
	Returns false if `val` is NULL. */
	mut_is_int :: proc(val: ^Mut_Val) -> bool ---

	/** Returns whether the JSON value is real number (double).
	Returns false if `val` is NULL. */
	mut_is_real :: proc(val: ^Mut_Val) -> bool ---

	/** Returns whether the JSON value is number (uint/sint/real).
	Returns false if `val` is NULL. */
	mut_is_num :: proc(val: ^Mut_Val) -> bool ---

	/** Returns whether the JSON value is string.
	Returns false if `val` is NULL. */
	mut_is_str :: proc(val: ^Mut_Val) -> bool ---

	/** Returns whether the JSON value is array.
	Returns false if `val` is NULL. */
	mut_is_arr :: proc(val: ^Mut_Val) -> bool ---

	/** Returns whether the JSON value is object.
	Returns false if `val` is NULL. */
	mut_is_obj :: proc(val: ^Mut_Val) -> bool ---

	/** Returns whether the JSON value is container (array/object).
	Returns false if `val` is NULL. */
	mut_is_ctn :: proc(val: ^Mut_Val) -> bool ---

	/** Returns the JSON value's type.
	Returns `YYJSON_TYPE_NONE` if `val` is NULL. */
	mut_get_type :: proc(val: ^Mut_Val) -> Type ---

	/** Returns the JSON value's subtype.
	Returns `YYJSON_SUBTYPE_NONE` if `val` is NULL. */
	mut_get_subtype :: proc(val: ^Mut_Val) -> Subtype ---

	/** Returns the JSON value's tag.
	Returns 0 if `val` is NULL. */
	mut_get_tag :: proc(val: ^Mut_Val) -> u8 ---

	/** Returns the JSON value's type description.
	The return value should be one of these strings: "raw", "null", "string",
	"array", "object", "true", "false", "uint", "sint", "real", "unknown". */
	mut_get_type_desc :: proc(val: ^Mut_Val) -> cstring ---

	/** Returns the content if the value is raw.
	Returns NULL if `val` is NULL or type is not raw. */
	mut_get_raw :: proc(val: ^Mut_Val) -> cstring ---

	/** Returns the content if the value is bool.
	Returns NULL if `val` is NULL or type is not bool. */
	mut_get_bool :: proc(val: ^Mut_Val) -> bool ---

	/** Returns the content and cast to uint64_t.
	Returns 0 if `val` is NULL or type is not integer(sint/uint). */
	mut_get_uint :: proc(val: ^Mut_Val) -> u64 ---

	/** Returns the content and cast to int64_t.
	Returns 0 if `val` is NULL or type is not integer(sint/uint). */
	mut_get_sint :: proc(val: ^Mut_Val) -> i64 ---

	/** Returns the content and cast to int.
	Returns 0 if `val` is NULL or type is not integer(sint/uint). */
	mut_get_int :: proc(val: ^Mut_Val) -> i32 ---

	/** Returns the content if the value is real number.
	Returns 0.0 if `val` is NULL or type is not real(double). */
	mut_get_real :: proc(val: ^Mut_Val) -> f64 ---

	/** Returns the content and typecast to `double` if the value is number.
	Returns 0.0 if `val` is NULL or type is not number(uint/sint/real). */
	mut_get_num :: proc(val: ^Mut_Val) -> f64 ---

	/** Returns the content if the value is string.
	Returns NULL if `val` is NULL or type is not string. */
	mut_get_str :: proc(val: ^Mut_Val) -> cstring ---

	/** Returns the content length (string length, array size, object size.
	Returns 0 if `val` is NULL or type is not string/array/object. */
	mut_get_len :: proc(val: ^Mut_Val) -> c.size_t ---

	/** Returns whether the JSON value is equals to a string.
	The `str` should be a null-terminated UTF-8 string.
	Returns false if input is NULL or type is not string. */
	mut_equals_str :: proc(val: ^Mut_Val, str: cstring) -> bool ---

	/** Returns whether the JSON value is equals to a string.
	The `str` should be a UTF-8 string, null-terminator is not required.
	Returns false if input is NULL or type is not string. */
	mut_equals_strn :: proc(val: ^Mut_Val, str: cstring, len: c.size_t) -> bool ---

	/** Returns whether two JSON values are equal (deep compare).
	Returns false if input is NULL.
	@note the result may be inaccurate if object has duplicate keys.
	@warning This function is recursive and may cause a stack overflow
	if the object level is too deep. */
	mut_equals :: proc(lhs: ^Mut_Val, rhs: ^Mut_Val) -> bool ---

	/** Set the value to raw.
	Returns false if input is NULL.
	@warning This function should not be used on an existing object or array. */
	mut_set_raw :: proc(val: ^Mut_Val, raw: cstring, len: c.size_t) -> bool ---

	/** Set the value to null.
	Returns false if input is NULL.
	@warning This function should not be used on an existing object or array. */
	mut_set_null :: proc(val: ^Mut_Val) -> bool ---

	/** Set the value to bool.
	Returns false if input is NULL.
	@warning This function should not be used on an existing object or array. */
	mut_set_bool :: proc(val: ^Mut_Val, num: bool) -> bool ---

	/** Set the value to uint.
	Returns false if input is NULL.
	@warning This function should not be used on an existing object or array. */
	mut_set_uint :: proc(val: ^Mut_Val, num: u64) -> bool ---

	/** Set the value to sint.
	Returns false if input is NULL.
	@warning This function should not be used on an existing object or array. */
	mut_set_sint :: proc(val: ^Mut_Val, num: i64) -> bool ---

	/** Set the value to int.
	Returns false if input is NULL.
	@warning This function should not be used on an existing object or array. */
	mut_set_int :: proc(val: ^Mut_Val, num: i64) -> bool ---

	/** Set the value to float.
	Returns false if input is NULL.
	@warning This function should not be used on an existing object or array. */
	mut_set_float :: proc(val: ^Mut_Val, num: f32) -> bool ---

	/** Set the value to double.
	Returns false if input is NULL.
	@warning This function should not be used on an existing object or array. */
	mut_set_double :: proc(val: ^Mut_Val, num: f64) -> bool ---

	/** Set the value to real.
	Returns false if input is NULL.
	@warning This function should not be used on an existing object or array. */
	mut_set_real :: proc(val: ^Mut_Val, num: f64) -> bool ---

	/** Set the floating-point number's output format to fixed-point notation.
	Returns false if input is NULL or `val` is not real type.
	@see YYJSON_WRITE_FP_TO_FIXED flag.
	@warning This will modify the `immutable` value, use with caution. */
	mut_set_fp_to_fixed :: proc(val: ^Mut_Val, prec: i32) -> bool ---

	/** Set the floating-point number's output format to single-precision.
	Returns false if input is NULL or `val` is not real type.
	@see YYJSON_WRITE_FP_TO_FLOAT flag.
	@warning This will modify the `immutable` value, use with caution. */
	mut_set_fp_to_float :: proc(val: ^Mut_Val, flt: bool) -> bool ---

	/** Set the value to string (null-terminated).
	Returns false if input is NULL.
	@warning This function should not be used on an existing object or array. */
	mut_set_str :: proc(val: ^Mut_Val, str: cstring) -> bool ---

	/** Set the value to string (with length).
	Returns false if input is NULL.
	@warning This function should not be used on an existing object or array. */
	mut_set_strn :: proc(val: ^Mut_Val, str: cstring, len: c.size_t) -> bool ---

	/** Marks this string as not needing to be escaped during JSON writing.
	This can be used to avoid the overhead of escaping if the string contains
	only characters that do not require escaping.
	Returns false if input is NULL or `val` is not string.
	@see YYJSON_SUBTYPE_NOESC subtype.
	@warning This will modify the `immutable` value, use with caution. */
	mut_set_str_noesc :: proc(val: ^Mut_Val, noesc: bool) -> bool ---

	/** Set the value to array.
	Returns false if input is NULL.
	@warning This function should not be used on an existing object or array. */
	mut_set_arr :: proc(val: ^Mut_Val) -> bool ---

	/** Set the value to array.
	Returns false if input is NULL.
	@warning This function should not be used on an existing object or array. */
	mut_set_obj :: proc(val: ^Mut_Val) -> bool ---

	/** Creates and returns a raw value, returns NULL on error.
	The `str` should be a null-terminated UTF-8 string.

	@warning The input string is not copied, you should keep this string
	unmodified for the lifetime of this JSON document. */
	mut_raw :: proc(doc: ^Mut_Doc, str: cstring) -> ^Mut_Val ---

	/** Creates and returns a raw value, returns NULL on error.
	The `str` should be a UTF-8 string, null-terminator is not required.

	@warning The input string is not copied, you should keep this string
	unmodified for the lifetime of this JSON document. */
	mut_rawn :: proc(doc: ^Mut_Doc, str: cstring, len: c.size_t) -> ^Mut_Val ---

	/** Creates and returns a raw value, returns NULL on error.
	The `str` should be a null-terminated UTF-8 string.
	The input string is copied and held by the document. */
	mut_rawcpy :: proc(doc: ^Mut_Doc, str: cstring) -> ^Mut_Val ---

	/** Creates and returns a raw value, returns NULL on error.
	The `str` should be a UTF-8 string, null-terminator is not required.
	The input string is copied and held by the document. */
	mut_rawncpy :: proc(doc: ^Mut_Doc, str: cstring, len: c.size_t) -> ^Mut_Val ---

	/** Creates and returns a null value, returns NULL on error. */
	mut_null :: proc(doc: ^Mut_Doc) -> ^Mut_Val ---

	/** Creates and returns a true value, returns NULL on error. */
	mut_true :: proc(doc: ^Mut_Doc) -> ^Mut_Val ---

	/** Creates and returns a false value, returns NULL on error. */
	mut_false :: proc(doc: ^Mut_Doc) -> ^Mut_Val ---

	/** Creates and returns a bool value, returns NULL on error. */
	mut_bool :: proc(doc: ^Mut_Doc, val: bool) -> ^Mut_Val ---

	/** Creates and returns an unsigned integer value, returns NULL on error. */
	mut_uint :: proc(doc: ^Mut_Doc, num: u64) -> ^Mut_Val ---

	/** Creates and returns a signed integer value, returns NULL on error. */
	mut_sint :: proc(doc: ^Mut_Doc, num: i64) -> ^Mut_Val ---

	/** Creates and returns a signed integer value, returns NULL on error. */
	mut_int :: proc(doc: ^Mut_Doc, num: i64) -> ^Mut_Val ---

	/** Creates and returns a float number value, returns NULL on error. */
	mut_float :: proc(doc: ^Mut_Doc, num: f32) -> ^Mut_Val ---

	/** Creates and returns a double number value, returns NULL on error. */
	mut_double :: proc(doc: ^Mut_Doc, num: f64) -> ^Mut_Val ---

	/** Creates and returns a real number value, returns NULL on error. */
	mut_real :: proc(doc: ^Mut_Doc, num: f64) -> ^Mut_Val ---

	/** Creates and returns a string value, returns NULL on error.
	The `str` should be a null-terminated UTF-8 string.
	@warning The input string is not copied, you should keep this string
	unmodified for the lifetime of this JSON document. */
	mut_str :: proc(doc: ^Mut_Doc, str: cstring) -> ^Mut_Val ---

	/** Creates and returns a string value, returns NULL on error.
	The `str` should be a UTF-8 string, null-terminator is not required.
	@warning The input string is not copied, you should keep this string
	unmodified for the lifetime of this JSON document. */
	mut_strn :: proc(doc: ^Mut_Doc, str: cstring, len: c.size_t) -> ^Mut_Val ---

	/** Creates and returns a string value, returns NULL on error.
	The `str` should be a null-terminated UTF-8 string.
	The input string is copied and held by the document. */
	mut_strcpy :: proc(doc: ^Mut_Doc, str: cstring) -> ^Mut_Val ---

	/** Creates and returns a string value, returns NULL on error.
	The `str` should be a UTF-8 string, null-terminator is not required.
	The input string is copied and held by the document. */
	mut_strncpy :: proc(doc: ^Mut_Doc, str: cstring, len: c.size_t) -> ^Mut_Val ---

	/** Returns the number of elements in this array.
	Returns 0 if `arr` is NULL or type is not array. */
	mut_arr_size :: proc(arr: ^Mut_Val) -> c.size_t ---

	/** Returns the element at the specified position in this array.
	Returns NULL if array is NULL/empty or the index is out of bounds.
	@warning This function takes a linear search time. */
	mut_arr_get :: proc(arr: ^Mut_Val, idx: c.size_t) -> ^Mut_Val ---

	/** Returns the first element of this array.
	Returns NULL if `arr` is NULL/empty or type is not array. */
	mut_arr_get_first :: proc(arr: ^Mut_Val) -> ^Mut_Val ---

	/** Returns the last element of this array.
	Returns NULL if `arr` is NULL/empty or type is not array. */
	mut_arr_get_last :: proc(arr: ^Mut_Val) -> ^Mut_Val ---

	/**
	Initialize an iterator for this array.

	@param arr The array to be iterated over.
	If this parameter is NULL or not an array, `iter` will be set to empty.
	@param iter The iterator to be initialized.
	If this parameter is NULL, the function will fail and return false.
	@return true if the `iter` has been successfully initialized.

	@note The iterator does not need to be destroyed.
	*/
	mut_arr_iter_init :: proc(arr: ^Mut_Val, iter: ^Mut_Arr_Iter) -> bool ---

	/**
	Create an iterator with an array , same as `yyjson_mut_arr_iter_init()`.

	@param arr The array to be iterated over.
	If this parameter is NULL or not an array, an empty iterator will returned.
	@return A new iterator for the array.

	@note The iterator does not need to be destroyed.
	*/
	mut_arr_iter_with :: proc(arr: ^Mut_Val) -> Mut_Arr_Iter ---

	/**
	Returns whether the iteration has more elements.
	If `iter` is NULL, this function will return false.
	*/
	mut_arr_iter_has_next :: proc(iter: ^Mut_Arr_Iter) -> bool ---

	/**
	Returns the next element in the iteration, or NULL on end.
	If `iter` is NULL, this function will return NULL.
	*/
	mut_arr_iter_next :: proc(iter: ^Mut_Arr_Iter) -> ^Mut_Val ---

	/**
	Removes and returns current element in the iteration.
	If `iter` is NULL, this function will return NULL.
	*/
	mut_arr_iter_remove :: proc(iter: ^Mut_Arr_Iter) -> ^Mut_Val ---

	/**
	Creates and returns an empty mutable array.
	@param doc A mutable document, used for memory allocation only.
	@return The new array. NULL if input is NULL or memory allocation failed.
	*/
	mut_arr :: proc(doc: ^Mut_Doc) -> ^Mut_Val ---

	/**
	Creates and returns a new mutable array with the given boolean values.

	@param doc A mutable document, used for memory allocation only.
	If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of boolean values.
	@param count The value count. If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@b Example
	@code
	const bool vals[3] = { true, false, true };
	yyjson_mut_val *arr = yyjson_mut_arr_with_bool(doc, vals, 3);
	@endcode
	*/
	mut_arr_with_bool :: proc(doc: ^Mut_Doc, vals: ^bool, count: c.size_t) -> ^Mut_Val ---

	/**
	Creates and returns a new mutable array with the given sint numbers.

	@param doc A mutable document, used for memory allocation only.
	If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of sint numbers.
	@param count The number count. If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@b Example
	@code
	const int64_t vals[3] = { -1, 0, 1 };
	yyjson_mut_val *arr = yyjson_mut_arr_with_sint64(doc, vals, 3);
	@endcode
	*/
	mut_arr_with_sint :: proc(doc: ^Mut_Doc, vals: ^i64, count: c.size_t) -> ^Mut_Val ---

	/**
	Creates and returns a new mutable array with the given uint numbers.

	@param doc A mutable document, used for memory allocation only.
	If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of uint numbers.
	@param count The number count. If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@b Example
	@code
	const uint64_t vals[3] = { 0, 1, 0 };
	yyjson_mut_val *arr = yyjson_mut_arr_with_uint(doc, vals, 3);
	@endcode
	*/
	mut_arr_with_uint :: proc(doc: ^Mut_Doc, vals: ^u64, count: c.size_t) -> ^Mut_Val ---

	/**
	Creates and returns a new mutable array with the given real numbers.

	@param doc A mutable document, used for memory allocation only.
	If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of real numbers.
	@param count The number count. If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@b Example
	@code
	const double vals[3] = { 0.1, 0.2, 0.3 };
	yyjson_mut_val *arr = yyjson_mut_arr_with_real(doc, vals, 3);
	@endcode
	*/
	mut_arr_with_real :: proc(doc: ^Mut_Doc, vals: ^f64, count: c.size_t) -> ^Mut_Val ---

	/**
	Creates and returns a new mutable array with the given int8 numbers.

	@param doc A mutable document, used for memory allocation only.
	If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of int8 numbers.
	@param count The number count. If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@b Example
	@code
	const int8_t vals[3] = { -1, 0, 1 };
	yyjson_mut_val *arr = yyjson_mut_arr_with_sint8(doc, vals, 3);
	@endcode
	*/
	mut_arr_with_sint8 :: proc(doc: ^Mut_Doc, vals: ^i8, count: c.size_t) -> ^Mut_Val ---

	/**
	Creates and returns a new mutable array with the given int16 numbers.

	@param doc A mutable document, used for memory allocation only.
	If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of int16 numbers.
	@param count The number count. If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@b Example
	@code
	const int16_t vals[3] = { -1, 0, 1 };
	yyjson_mut_val *arr = yyjson_mut_arr_with_sint16(doc, vals, 3);
	@endcode
	*/
	mut_arr_with_sint16 :: proc(doc: ^Mut_Doc, vals: ^i16, count: c.size_t) -> ^Mut_Val ---

	/**
	Creates and returns a new mutable array with the given int32 numbers.

	@param doc A mutable document, used for memory allocation only.
	If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of int32 numbers.
	@param count The number count. If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@b Example
	@code
	const int32_t vals[3] = { -1, 0, 1 };
	yyjson_mut_val *arr = yyjson_mut_arr_with_sint32(doc, vals, 3);
	@endcode
	*/
	mut_arr_with_sint32 :: proc(doc: ^Mut_Doc, vals: ^i32, count: c.size_t) -> ^Mut_Val ---

	/**
	Creates and returns a new mutable array with the given int64 numbers.

	@param doc A mutable document, used for memory allocation only.
	If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of int64 numbers.
	@param count The number count. If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@b Example
	@code
	const int64_t vals[3] = { -1, 0, 1 };
	yyjson_mut_val *arr = yyjson_mut_arr_with_sint64(doc, vals, 3);
	@endcode
	*/
	mut_arr_with_sint64 :: proc(doc: ^Mut_Doc, vals: ^i64, count: c.size_t) -> ^Mut_Val ---

	/**
	Creates and returns a new mutable array with the given uint8 numbers.

	@param doc A mutable document, used for memory allocation only.
	If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of uint8 numbers.
	@param count The number count. If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@b Example
	@code
	const uint8_t vals[3] = { 0, 1, 0 };
	yyjson_mut_val *arr = yyjson_mut_arr_with_uint8(doc, vals, 3);
	@endcode
	*/
	mut_arr_with_uint8 :: proc(doc: ^Mut_Doc, vals: ^u8, count: c.size_t) -> ^Mut_Val ---

	/**
	Creates and returns a new mutable array with the given uint16 numbers.

	@param doc A mutable document, used for memory allocation only.
	If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of uint16 numbers.
	@param count The number count. If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@b Example
	@code
	const uint16_t vals[3] = { 0, 1, 0 };
	yyjson_mut_val *arr = yyjson_mut_arr_with_uint16(doc, vals, 3);
	@endcode
	*/
	mut_arr_with_uint16 :: proc(doc: ^Mut_Doc, vals: ^u16, count: c.size_t) -> ^Mut_Val ---

	/**
	Creates and returns a new mutable array with the given uint32 numbers.

	@param doc A mutable document, used for memory allocation only.
	If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of uint32 numbers.
	@param count The number count. If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@b Example
	@code
	const uint32_t vals[3] = { 0, 1, 0 };
	yyjson_mut_val *arr = yyjson_mut_arr_with_uint32(doc, vals, 3);
	@endcode
	*/
	mut_arr_with_uint32 :: proc(doc: ^Mut_Doc, vals: ^u32, count: c.size_t) -> ^Mut_Val ---

	/**
	Creates and returns a new mutable array with the given uint64 numbers.

	@param doc A mutable document, used for memory allocation only.
	If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of uint64 numbers.
	@param count The number count. If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@b Example
	@code
	const uint64_t vals[3] = { 0, 1, 0 };
	yyjson_mut_val *arr = yyjson_mut_arr_with_uint64(doc, vals, 3);
	@endcode
	*/
	mut_arr_with_uint64 :: proc(doc: ^Mut_Doc, vals: ^u64, count: c.size_t) -> ^Mut_Val ---

	/**
	Creates and returns a new mutable array with the given float numbers.

	@param doc A mutable document, used for memory allocation only.
	If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of float numbers.
	@param count The number count. If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@b Example
	@code
	const float vals[3] = { -1.0f, 0.0f, 1.0f };
	yyjson_mut_val *arr = yyjson_mut_arr_with_float(doc, vals, 3);
	@endcode
	*/
	mut_arr_with_float :: proc(doc: ^Mut_Doc, vals: ^f32, count: c.size_t) -> ^Mut_Val ---

	/**
	Creates and returns a new mutable array with the given double numbers.

	@param doc A mutable document, used for memory allocation only.
	If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of double numbers.
	@param count The number count. If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@b Example
	@code
	const double vals[3] = { -1.0, 0.0, 1.0 };
	yyjson_mut_val *arr = yyjson_mut_arr_with_double(doc, vals, 3);
	@endcode
	*/
	mut_arr_with_double :: proc(doc: ^Mut_Doc, vals: ^f64, count: c.size_t) -> ^Mut_Val ---

	/**
	Creates and returns a new mutable array with the given strings, these strings
	will not be copied.

	@param doc A mutable document, used for memory allocation only.
	If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of UTF-8 null-terminator strings.
	If this array contains NULL, the function will fail and return NULL.
	@param count The number of values in `vals`.
	If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@warning The input strings are not copied, you should keep these strings
	unmodified for the lifetime of this JSON document. If these strings will be
	modified, you should use `yyjson_mut_arr_with_strcpy()` instead.

	@b Example
	@code
	const char *vals[3] = { "a", "b", "c" };
	yyjson_mut_val *arr = yyjson_mut_arr_with_str(doc, vals, 3);
	@endcode
	*/
	mut_arr_with_str :: proc(doc: ^Mut_Doc, vals: ^cstring, count: c.size_t) -> ^Mut_Val ---

	/**
	Creates and returns a new mutable array with the given strings and string
	lengths, these strings will not be copied.

	@param doc A mutable document, used for memory allocation only.
	If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of UTF-8 strings, null-terminator is not required.
	If this array contains NULL, the function will fail and return NULL.
	@param lens A C array of string lengths, in bytes.
	@param count The number of strings in `vals`.
	If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@warning The input strings are not copied, you should keep these strings
	unmodified for the lifetime of this JSON document. If these strings will be
	modified, you should use `yyjson_mut_arr_with_strncpy()` instead.

	@b Example
	@code
	const char *vals[3] = { "a", "bb", "c" };
	const size_t lens[3] = { 1, 2, 1 };
	yyjson_mut_val *arr = yyjson_mut_arr_with_strn(doc, vals, lens, 3);
	@endcode
	*/
	mut_arr_with_strn :: proc(doc: ^Mut_Doc, vals: ^cstring, lens: ^c.size_t, count: c.size_t) -> ^Mut_Val ---

	/**
	Creates and returns a new mutable array with the given strings, these strings
	will be copied.

	@param doc A mutable document, used for memory allocation only.
	If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of UTF-8 null-terminator strings.
	If this array contains NULL, the function will fail and return NULL.
	@param count The number of values in `vals`.
	If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@b Example
	@code
	const char *vals[3] = { "a", "b", "c" };
	yyjson_mut_val *arr = yyjson_mut_arr_with_strcpy(doc, vals, 3);
	@endcode
	*/
	mut_arr_with_strcpy :: proc(doc: ^Mut_Doc, vals: ^cstring, count: c.size_t) -> ^Mut_Val ---

	/**
	Creates and returns a new mutable array with the given strings and string
	lengths, these strings will be copied.

	@param doc A mutable document, used for memory allocation only.
	If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of UTF-8 strings, null-terminator is not required.
	If this array contains NULL, the function will fail and return NULL.
	@param lens A C array of string lengths, in bytes.
	@param count The number of strings in `vals`.
	If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@b Example
	@code
	const char *vals[3] = { "a", "bb", "c" };
	const size_t lens[3] = { 1, 2, 1 };
	yyjson_mut_val *arr = yyjson_mut_arr_with_strn(doc, vals, lens, 3);
	@endcode
	*/
	mut_arr_with_strncpy :: proc(doc: ^Mut_Doc, vals: ^cstring, lens: ^c.size_t, count: c.size_t) -> ^Mut_Val ---

	/**
	Inserts a value into an array at a given index.
	@param arr The array to which the value is to be inserted.
	Returns false if it is NULL or not an array.
	@param val The value to be inserted. Returns false if it is NULL.
	@param idx The index to which to insert the new value.
	Returns false if the index is out of range.
	@return Whether successful.
	@warning This function takes a linear search time.
	*/
	mut_arr_insert :: proc(arr: ^Mut_Val, val: ^Mut_Val, idx: c.size_t) -> bool ---

	/**
	Inserts a value at the end of the array.
	@param arr The array to which the value is to be inserted.
	Returns false if it is NULL or not an array.
	@param val The value to be inserted. Returns false if it is NULL.
	@return Whether successful.
	*/
	mut_arr_append :: proc(arr: ^Mut_Val, val: ^Mut_Val) -> bool ---

	/**
	Inserts a value at the head of the array.
	@param arr The array to which the value is to be inserted.
	Returns false if it is NULL or not an array.
	@param val The value to be inserted. Returns false if it is NULL.
	@return    Whether successful.
	*/
	mut_arr_prepend :: proc(arr: ^Mut_Val, val: ^Mut_Val) -> bool ---

	/**
	Replaces a value at index and returns old value.
	@param arr The array to which the value is to be replaced.
	Returns false if it is NULL or not an array.
	@param idx The index to which to replace the value.
	Returns false if the index is out of range.
	@param val The new value to replace. Returns false if it is NULL.
	@return Old value, or NULL on error.
	@warning This function takes a linear search time.
	*/
	mut_arr_replace :: proc(arr: ^Mut_Val, idx: c.size_t, val: ^Mut_Val) -> ^Mut_Val ---

	/**
	Removes and returns a value at index.
	@param arr The array from which the value is to be removed.
	Returns false if it is NULL or not an array.
	@param idx The index from which to remove the value.
	Returns false if the index is out of range.
	@return Old value, or NULL on error.
	@warning This function takes a linear search time.
	*/
	mut_arr_remove :: proc(arr: ^Mut_Val, idx: c.size_t) -> ^Mut_Val ---

	/**
	Removes and returns the first value in this array.
	@param arr The array from which the value is to be removed.
	Returns false if it is NULL or not an array.
	@return The first value, or NULL on error.
	*/
	mut_arr_remove_first :: proc(arr: ^Mut_Val) -> ^Mut_Val ---

	/**
	Removes and returns the last value in this array.
	@param arr The array from which the value is to be removed.
	Returns false if it is NULL or not an array.
	@return The last value, or NULL on error.
	*/
	mut_arr_remove_last :: proc(arr: ^Mut_Val) -> ^Mut_Val ---

	/**
	Removes all values within a specified range in the array.
	@param arr The array from which the value is to be removed.
	Returns false if it is NULL or not an array.
	@param idx The start index of the range (0 is the first).
	@param len The number of items in the range (can be 0).
	@return Whether successful.
	@warning This function takes a linear search time.
	*/
	mut_arr_remove_range :: proc(arr: ^Mut_Val, idx: c.size_t, len: c.size_t) -> bool ---

	/**
	Removes all values in this array.
	@param arr The array from which all of the values are to be removed.
	Returns false if it is NULL or not an array.
	@return Whether successful.
	*/
	mut_arr_clear :: proc(arr: ^Mut_Val) -> bool ---

	/**
	Rotates values in this array for the given number of times.
	For example: `[1,2,3,4,5]` rotate 2 is `[3,4,5,1,2]`.
	@param arr The array to be rotated.
	@param idx Index (or times) to rotate.
	@warning This function takes a linear search time.
	*/
	mut_arr_rotate :: proc(arr: ^Mut_Val, idx: c.size_t) -> bool ---

	/**
	Adds a value at the end of the array.
	@param arr The array to which the value is to be inserted.
	Returns false if it is NULL or not an array.
	@param val The value to be inserted. Returns false if it is NULL.
	@return Whether successful.
	*/
	mut_arr_add_val :: proc(arr: ^Mut_Val, val: ^Mut_Val) -> bool ---

	/**
	Adds a `null` value at the end of the array.
	@param doc The `doc` is only used for memory allocation.
	@param arr The array to which the value is to be inserted.
	Returns false if it is NULL or not an array.
	@return Whether successful.
	*/
	mut_arr_add_null :: proc(doc: ^Mut_Doc, arr: ^Mut_Val) -> bool ---

	/**
	Adds a `true` value at the end of the array.
	@param doc The `doc` is only used for memory allocation.
	@param arr The array to which the value is to be inserted.
	Returns false if it is NULL or not an array.
	@return Whether successful.
	*/
	mut_arr_add_true :: proc(doc: ^Mut_Doc, arr: ^Mut_Val) -> bool ---

	/**
	Adds a `false` value at the end of the array.
	@param doc The `doc` is only used for memory allocation.
	@param arr The array to which the value is to be inserted.
	Returns false if it is NULL or not an array.
	@return Whether successful.
	*/
	mut_arr_add_false :: proc(doc: ^Mut_Doc, arr: ^Mut_Val) -> bool ---

	/**
	Adds a bool value at the end of the array.
	@param doc The `doc` is only used for memory allocation.
	@param arr The array to which the value is to be inserted.
	Returns false if it is NULL or not an array.
	@param val The bool value to be added.
	@return Whether successful.
	*/
	mut_arr_add_bool :: proc(doc: ^Mut_Doc, arr: ^Mut_Val, val: bool) -> bool ---

	/**
	Adds an unsigned integer value at the end of the array.
	@param doc The `doc` is only used for memory allocation.
	@param arr The array to which the value is to be inserted.
	Returns false if it is NULL or not an array.
	@param num The number to be added.
	@return Whether successful.
	*/
	mut_arr_add_uint :: proc(doc: ^Mut_Doc, arr: ^Mut_Val, num: u64) -> bool ---

	/**
	Adds a signed integer value at the end of the array.
	@param doc The `doc` is only used for memory allocation.
	@param arr The array to which the value is to be inserted.
	Returns false if it is NULL or not an array.
	@param num The number to be added.
	@return Whether successful.
	*/
	mut_arr_add_sint :: proc(doc: ^Mut_Doc, arr: ^Mut_Val, num: i64) -> bool ---

	/**
	Adds an integer value at the end of the array.
	@param doc The `doc` is only used for memory allocation.
	@param arr The array to which the value is to be inserted.
	Returns false if it is NULL or not an array.
	@param num The number to be added.
	@return Whether successful.
	*/
	mut_arr_add_int :: proc(doc: ^Mut_Doc, arr: ^Mut_Val, num: i64) -> bool ---

	/**
	Adds a float value at the end of the array.
	@param doc The `doc` is only used for memory allocation.
	@param arr The array to which the value is to be inserted.
	Returns false if it is NULL or not an array.
	@param num The number to be added.
	@return Whether successful.
	*/
	mut_arr_add_float :: proc(doc: ^Mut_Doc, arr: ^Mut_Val, num: f32) -> bool ---

	/**
	Adds a double value at the end of the array.
	@param doc The `doc` is only used for memory allocation.
	@param arr The array to which the value is to be inserted.
	Returns false if it is NULL or not an array.
	@param num The number to be added.
	@return Whether successful.
	*/
	mut_arr_add_double :: proc(doc: ^Mut_Doc, arr: ^Mut_Val, num: f64) -> bool ---

	/**
	Adds a double value at the end of the array.
	@param doc The `doc` is only used for memory allocation.
	@param arr The array to which the value is to be inserted.
	Returns false if it is NULL or not an array.
	@param num The number to be added.
	@return Whether successful.
	*/
	mut_arr_add_real :: proc(doc: ^Mut_Doc, arr: ^Mut_Val, num: f64) -> bool ---

	/**
	Adds a string value at the end of the array (no copy).
	@param doc The `doc` is only used for memory allocation.
	@param arr The array to which the value is to be inserted.
	Returns false if it is NULL or not an array.
	@param str A null-terminated UTF-8 string.
	@return Whether successful.
	@warning The input string is not copied, you should keep this string unmodified
	for the lifetime of this JSON document.
	*/
	mut_arr_add_str :: proc(doc: ^Mut_Doc, arr: ^Mut_Val, str: cstring) -> bool ---

	/**
	Adds a string value at the end of the array (no copy).
	@param doc The `doc` is only used for memory allocation.
	@param arr The array to which the value is to be inserted.
	Returns false if it is NULL or not an array.
	@param str A UTF-8 string, null-terminator is not required.
	@param len The length of the string, in bytes.
	@return Whether successful.
	@warning The input string is not copied, you should keep this string unmodified
	for the lifetime of this JSON document.
	*/
	mut_arr_add_strn :: proc(doc: ^Mut_Doc, arr: ^Mut_Val, str: cstring, len: c.size_t) -> bool ---

	/**
	Adds a string value at the end of the array (copied).
	@param doc The `doc` is only used for memory allocation.
	@param arr The array to which the value is to be inserted.
	Returns false if it is NULL or not an array.
	@param str A null-terminated UTF-8 string.
	@return Whether successful.
	*/
	mut_arr_add_strcpy :: proc(doc: ^Mut_Doc, arr: ^Mut_Val, str: cstring) -> bool ---

	/**
	Adds a string value at the end of the array (copied).
	@param doc The `doc` is only used for memory allocation.
	@param arr The array to which the value is to be inserted.
	Returns false if it is NULL or not an array.
	@param str A UTF-8 string, null-terminator is not required.
	@param len The length of the string, in bytes.
	@return Whether successful.
	*/
	mut_arr_add_strncpy :: proc(doc: ^Mut_Doc, arr: ^Mut_Val, str: cstring, len: c.size_t) -> bool ---

	/**
	Creates and adds a new array at the end of the array.
	@param doc The `doc` is only used for memory allocation.
	@param arr The array to which the value is to be inserted.
	Returns false if it is NULL or not an array.
	@return The new array, or NULL on error.
	*/
	mut_arr_add_arr :: proc(doc: ^Mut_Doc, arr: ^Mut_Val) -> ^Mut_Val ---

	/**
	Creates and adds a new object at the end of the array.
	@param doc The `doc` is only used for memory allocation.
	@param arr The array to which the value is to be inserted.
	Returns false if it is NULL or not an array.
	@return The new object, or NULL on error.
	*/
	mut_arr_add_obj :: proc(doc: ^Mut_Doc, arr: ^Mut_Val) -> ^Mut_Val ---

	/** Returns the number of key-value pairs in this object.
	Returns 0 if `obj` is NULL or type is not object. */
	mut_obj_size :: proc(obj: ^Mut_Val) -> c.size_t ---

	/** Returns the value to which the specified key is mapped.
	Returns NULL if this object contains no mapping for the key.
	Returns NULL if `obj/key` is NULL, or type is not object.

	The `key` should be a null-terminated UTF-8 string.

	@warning This function takes a linear search time. */
	mut_obj_get :: proc(obj: ^Mut_Val, key: cstring) -> ^Mut_Val ---

	/** Returns the value to which the specified key is mapped.
	Returns NULL if this object contains no mapping for the key.
	Returns NULL if `obj/key` is NULL, or type is not object.

	The `key` should be a UTF-8 string, null-terminator is not required.
	The `key_len` should be the length of the key, in bytes.

	@warning This function takes a linear search time. */
	mut_obj_getn :: proc(obj: ^Mut_Val, key: cstring, key_len: c.size_t) -> ^Mut_Val ---

	/**
	Initialize an iterator for this object.

	@param obj The object to be iterated over.
	If this parameter is NULL or not an array, `iter` will be set to empty.
	@param iter The iterator to be initialized.
	If this parameter is NULL, the function will fail and return false.
	@return true if the `iter` has been successfully initialized.

	@note The iterator does not need to be destroyed.
	*/
	mut_obj_iter_init :: proc(obj: ^Mut_Val, iter: ^Mut_Obj_Iter) -> bool ---

	/**
	Create an iterator with an object, same as `yyjson_obj_iter_init()`.

	@param obj The object to be iterated over.
	If this parameter is NULL or not an object, an empty iterator will returned.
	@return A new iterator for the object.

	@note The iterator does not need to be destroyed.
	*/
	mut_obj_iter_with :: proc(obj: ^Mut_Val) -> Mut_Obj_Iter ---

	/**
	Returns whether the iteration has more elements.
	If `iter` is NULL, this function will return false.
	*/
	mut_obj_iter_has_next :: proc(iter: ^Mut_Obj_Iter) -> bool ---

	/**
	Returns the next key in the iteration, or NULL on end.
	If `iter` is NULL, this function will return NULL.
	*/
	mut_obj_iter_next :: proc(iter: ^Mut_Obj_Iter) -> ^Mut_Val ---

	/**
	Returns the value for key inside the iteration.
	If `iter` is NULL, this function will return NULL.
	*/
	mut_obj_iter_get_val :: proc(key: ^Mut_Val) -> ^Mut_Val ---

	/**
	Removes current key-value pair in the iteration, returns the removed value.
	If `iter` is NULL, this function will return NULL.
	*/
	mut_obj_iter_remove :: proc(iter: ^Mut_Obj_Iter) -> ^Mut_Val ---

	/**
	Iterates to a specified key and returns the value.

	This function does the same thing as `yyjson_mut_obj_get()`, but is much faster
	if the ordering of the keys is known at compile-time and you are using the same
	order to look up the values. If the key exists in this object, then the
	iterator will stop at the next key, otherwise the iterator will not change and
	NULL is returned.

	@param iter The object iterator, should not be NULL.
	@param key The key, should be a UTF-8 string with null-terminator.
	@return The value to which the specified key is mapped.
	NULL if this object contains no mapping for the key or input is invalid.

	@warning This function takes a linear search time if the key is not nearby.
	*/
	mut_obj_iter_get :: proc(iter: ^Mut_Obj_Iter, key: cstring) -> ^Mut_Val ---

	/**
	Iterates to a specified key and returns the value.

	This function does the same thing as `yyjson_mut_obj_getn()` but is much faster
	if the ordering of the keys is known at compile-time and you are using the same
	order to look up the values. If the key exists in this object, then the
	iterator will stop at the next key, otherwise the iterator will not change and
	NULL is returned.

	@param iter The object iterator, should not be NULL.
	@param key The key, should be a UTF-8 string, null-terminator is not required.
	@param key_len The the length of `key`, in bytes.
	@return The value to which the specified key is mapped.
	NULL if this object contains no mapping for the key or input is invalid.

	@warning This function takes a linear search time if the key is not nearby.
	*/
	mut_obj_iter_getn :: proc(iter: ^Mut_Obj_Iter, key: cstring, key_len: c.size_t) -> ^Mut_Val ---

	/** Creates and returns a mutable object, returns NULL on error. */
	mut_obj :: proc(doc: ^Mut_Doc) -> ^Mut_Val ---

	/**
	Creates and returns a mutable object with keys and values, returns NULL on
	error. The keys and values are not copied. The strings should be a
	null-terminated UTF-8 string.

	@warning The input string is not copied, you should keep this string
	unmodified for the lifetime of this JSON document.

	@b Example
	@code
	const char *keys[2] = { "id", "name" };
	const char *vals[2] = { "01", "Harry" };
	yyjson_mut_val *obj = yyjson_mut_obj_with_str(doc, keys, vals, 2);
	@endcode
	*/
	mut_obj_with_str :: proc(doc: ^Mut_Doc, keys: ^cstring, vals: ^cstring, count: c.size_t) -> ^Mut_Val ---

	/**
	Creates and returns a mutable object with key-value pairs and pair count,
	returns NULL on error. The keys and values are not copied. The strings should
	be a null-terminated UTF-8 string.

	@warning The input string is not copied, you should keep this string
	unmodified for the lifetime of this JSON document.

	@b Example
	@code
	const char *kv_pairs[4] = { "id", "01", "name", "Harry" };
	yyjson_mut_val *obj = yyjson_mut_obj_with_kv(doc, kv_pairs, 2);
	@endcode
	*/
	mut_obj_with_kv :: proc(doc: ^Mut_Doc, kv_pairs: ^cstring, pair_count: c.size_t) -> ^Mut_Val ---

	/**
	Adds a key-value pair at the end of the object.
	This function allows duplicated key in one object.
	@param obj The object to which the new key-value pair is to be added.
	@param key The key, should be a string which is created by `yyjson_mut_str()`,
	`yyjson_mut_strn()`, `yyjson_mut_strcpy()` or `yyjson_mut_strncpy()`.
	@param val The value to add to the object.
	@return Whether successful.
	*/
	mut_obj_add :: proc(obj: ^Mut_Val, key: ^Mut_Val, val: ^Mut_Val) -> bool ---

	/**
	Sets a key-value pair at the end of the object.
	This function may remove all key-value pairs for the given key before add.
	@param obj The object to which the new key-value pair is to be added.
	@param key The key, should be a string which is created by `yyjson_mut_str()`,
	`yyjson_mut_strn()`, `yyjson_mut_strcpy()` or `yyjson_mut_strncpy()`.
	@param val The value to add to the object. If this value is null, the behavior
	is same as `yyjson_mut_obj_remove()`.
	@return Whether successful.
	*/
	mut_obj_put :: proc(obj: ^Mut_Val, key: ^Mut_Val, val: ^Mut_Val) -> bool ---

	/**
	Inserts a key-value pair to the object at the given position.
	This function allows duplicated key in one object.
	@param obj The object to which the new key-value pair is to be added.
	@param key The key, should be a string which is created by `yyjson_mut_str()`,
	`yyjson_mut_strn()`, `yyjson_mut_strcpy()` or `yyjson_mut_strncpy()`.
	@param val The value to add to the object.
	@param idx The index to which to insert the new pair.
	@return Whether successful.
	*/
	mut_obj_insert :: proc(obj: ^Mut_Val, key: ^Mut_Val, val: ^Mut_Val, idx: c.size_t) -> bool ---

	/**
	Removes all key-value pair from the object with given key.
	@param obj The object from which the key-value pair is to be removed.
	@param key The key, should be a string value.
	@return The first matched value, or NULL if no matched value.
	@warning This function takes a linear search time.
	*/
	mut_obj_remove :: proc(obj: ^Mut_Val, key: ^Mut_Val) -> ^Mut_Val ---

	/**
	Removes all key-value pair from the object with given key.
	@param obj The object from which the key-value pair is to be removed.
	@param key The key, should be a UTF-8 string with null-terminator.
	@return The first matched value, or NULL if no matched value.
	@warning This function takes a linear search time.
	*/
	mut_obj_remove_key :: proc(obj: ^Mut_Val, key: cstring) -> ^Mut_Val ---

	/**
	Removes all key-value pair from the object with given key.
	@param obj The object from which the key-value pair is to be removed.
	@param key The key, should be a UTF-8 string, null-terminator is not required.
	@param key_len The length of the key.
	@return The first matched value, or NULL if no matched value.
	@warning This function takes a linear search time.
	*/
	mut_obj_remove_keyn :: proc(obj: ^Mut_Val, key: cstring, key_len: c.size_t) -> ^Mut_Val ---

	/**
	Removes all key-value pairs in this object.
	@param obj The object from which all of the values are to be removed.
	@return Whether successful.
	*/
	mut_obj_clear :: proc(obj: ^Mut_Val) -> bool ---

	/**
	Replaces value from the object with given key.
	If the key is not exist, or the value is NULL, it will fail.
	@param obj The object to which the value is to be replaced.
	@param key The key, should be a string value.
	@param val The value to replace into the object.
	@return Whether successful.
	@warning This function takes a linear search time.
	*/
	mut_obj_replace :: proc(obj: ^Mut_Val, key: ^Mut_Val, val: ^Mut_Val) -> bool ---

	/**
	Rotates key-value pairs in the object for the given number of times.
	For example: `{"a":1,"b":2,"c":3,"d":4}` rotate 1 is
	`{"b":2,"c":3,"d":4,"a":1}`.
	@param obj The object to be rotated.
	@param idx Index (or times) to rotate.
	@return Whether successful.
	@warning This function takes a linear search time.
	*/
	mut_obj_rotate :: proc(obj: ^Mut_Val, idx: c.size_t) -> bool ---

	/** Adds a `null` value at the end of the object.
	The `key` should be a null-terminated UTF-8 string.
	This function allows duplicated key in one object.

	@warning The key string is not copied, you should keep the string
	unmodified for the lifetime of this JSON document. */
	mut_obj_add_null :: proc(doc: ^Mut_Doc, obj: ^Mut_Val, key: cstring) -> bool ---

	/** Adds a `true` value at the end of the object.
	The `key` should be a null-terminated UTF-8 string.
	This function allows duplicated key in one object.

	@warning The key string is not copied, you should keep the string
	unmodified for the lifetime of this JSON document. */
	mut_obj_add_true :: proc(doc: ^Mut_Doc, obj: ^Mut_Val, key: cstring) -> bool ---

	/** Adds a `false` value at the end of the object.
	The `key` should be a null-terminated UTF-8 string.
	This function allows duplicated key in one object.

	@warning The key string is not copied, you should keep the string
	unmodified for the lifetime of this JSON document. */
	mut_obj_add_false :: proc(doc: ^Mut_Doc, obj: ^Mut_Val, key: cstring) -> bool ---

	/** Adds a bool value at the end of the object.
	The `key` should be a null-terminated UTF-8 string.
	This function allows duplicated key in one object.

	@warning The key string is not copied, you should keep the string
	unmodified for the lifetime of this JSON document. */
	mut_obj_add_bool :: proc(doc: ^Mut_Doc, obj: ^Mut_Val, key: cstring, val: bool) -> bool ---

	/** Adds an unsigned integer value at the end of the object.
	The `key` should be a null-terminated UTF-8 string.
	This function allows duplicated key in one object.

	@warning The key string is not copied, you should keep the string
	unmodified for the lifetime of this JSON document. */
	mut_obj_add_uint :: proc(doc: ^Mut_Doc, obj: ^Mut_Val, key: cstring, val: u64) -> bool ---

	/** Adds a signed integer value at the end of the object.
	The `key` should be a null-terminated UTF-8 string.
	This function allows duplicated key in one object.

	@warning The key string is not copied, you should keep the string
	unmodified for the lifetime of this JSON document. */
	mut_obj_add_sint :: proc(doc: ^Mut_Doc, obj: ^Mut_Val, key: cstring, val: i64) -> bool ---

	/** Adds an int value at the end of the object.
	The `key` should be a null-terminated UTF-8 string.
	This function allows duplicated key in one object.

	@warning The key string is not copied, you should keep the string
	unmodified for the lifetime of this JSON document. */
	mut_obj_add_int :: proc(doc: ^Mut_Doc, obj: ^Mut_Val, key: cstring, val: i64) -> bool ---

	/** Adds a float value at the end of the object.
	The `key` should be a null-terminated UTF-8 string.
	This function allows duplicated key in one object.

	@warning The key string is not copied, you should keep the string
	unmodified for the lifetime of this JSON document. */
	mut_obj_add_float :: proc(doc: ^Mut_Doc, obj: ^Mut_Val, key: cstring, val: f32) -> bool ---

	/** Adds a double value at the end of the object.
	The `key` should be a null-terminated UTF-8 string.
	This function allows duplicated key in one object.

	@warning The key string is not copied, you should keep the string
	unmodified for the lifetime of this JSON document. */
	mut_obj_add_double :: proc(doc: ^Mut_Doc, obj: ^Mut_Val, key: cstring, val: f64) -> bool ---

	/** Adds a real value at the end of the object.
	The `key` should be a null-terminated UTF-8 string.
	This function allows duplicated key in one object.

	@warning The key string is not copied, you should keep the string
	unmodified for the lifetime of this JSON document. */
	mut_obj_add_real :: proc(doc: ^Mut_Doc, obj: ^Mut_Val, key: cstring, val: f64) -> bool ---

	/** Adds a string value at the end of the object.
	The `key` and `val` should be null-terminated UTF-8 strings.
	This function allows duplicated key in one object.

	@warning The key/value strings are not copied, you should keep these strings
	unmodified for the lifetime of this JSON document. */
	mut_obj_add_str :: proc(doc: ^Mut_Doc, obj: ^Mut_Val, key: cstring, val: cstring) -> bool ---

	/** Adds a string value at the end of the object.
	The `key` should be a null-terminated UTF-8 string.
	The `val` should be a UTF-8 string, null-terminator is not required.
	The `len` should be the length of the `val`, in bytes.
	This function allows duplicated key in one object.

	@warning The key/value strings are not copied, you should keep these strings
	unmodified for the lifetime of this JSON document. */
	mut_obj_add_strn :: proc(doc: ^Mut_Doc, obj: ^Mut_Val, key: cstring, val: cstring, len: c.size_t) -> bool ---

	/** Adds a string value at the end of the object.
	The `key` and `val` should be null-terminated UTF-8 strings.
	The value string is copied.
	This function allows duplicated key in one object.

	@warning The key string is not copied, you should keep the string
	unmodified for the lifetime of this JSON document. */
	mut_obj_add_strcpy :: proc(doc: ^Mut_Doc, obj: ^Mut_Val, key: cstring, val: cstring) -> bool ---

	/** Adds a string value at the end of the object.
	The `key` should be a null-terminated UTF-8 string.
	The `val` should be a UTF-8 string, null-terminator is not required.
	The `len` should be the length of the `val`, in bytes.
	This function allows duplicated key in one object.

	@warning The key strings are not copied, you should keep these strings
	unmodified for the lifetime of this JSON document. */
	mut_obj_add_strncpy :: proc(doc: ^Mut_Doc, obj: ^Mut_Val, key: cstring, val: cstring, len: c.size_t) -> bool ---

	/**
	Creates and adds a new array to the target object.
	The `key` should be a null-terminated UTF-8 string.
	This function allows duplicated key in one object.

	@warning The key string is not copied, you should keep these strings
	unmodified for the lifetime of this JSON document.
	@return The new array, or NULL on error.
	*/
	mut_obj_add_arr :: proc(doc: ^Mut_Doc, obj: ^Mut_Val, key: cstring) -> ^Mut_Val ---

	/**
	Creates and adds a new object to the target object.
	The `key` should be a null-terminated UTF-8 string.
	This function allows duplicated key in one object.

	@warning The key string is not copied, you should keep these strings
	unmodified for the lifetime of this JSON document.
	@return The new object, or NULL on error.
	*/
	mut_obj_add_obj :: proc(doc: ^Mut_Doc, obj: ^Mut_Val, key: cstring) -> ^Mut_Val ---

	/** Adds a JSON value at the end of the object.
	The `key` should be a null-terminated UTF-8 string.
	This function allows duplicated key in one object.

	@warning The key string is not copied, you should keep the string
	unmodified for the lifetime of this JSON document. */
	mut_obj_add_val :: proc(doc: ^Mut_Doc, obj: ^Mut_Val, key: cstring, val: ^Mut_Val) -> bool ---

	/** Removes all key-value pairs for the given key.
	Returns the first value to which the specified key is mapped or NULL if this
	object contains no mapping for the key.
	The `key` should be a null-terminated UTF-8 string.

	@warning This function takes a linear search time. */
	mut_obj_remove_str :: proc(obj: ^Mut_Val, key: cstring) -> ^Mut_Val ---

	/** Removes all key-value pairs for the given key.
	Returns the first value to which the specified key is mapped or NULL if this
	object contains no mapping for the key.
	The `key` should be a UTF-8 string, null-terminator is not required.
	The `len` should be the length of the key, in bytes.

	@warning This function takes a linear search time. */
	mut_obj_remove_strn :: proc(obj: ^Mut_Val, key: cstring, len: c.size_t) -> ^Mut_Val ---

	/** Replaces all matching keys with the new key.
	Returns true if at least one key was renamed.
	The `key` and `new_key` should be a null-terminated UTF-8 string.
	The `new_key` is copied and held by doc.

	@warning This function takes a linear search time.
	If `new_key` already exists, it will cause duplicate keys.
	*/
	mut_obj_rename_key :: proc(doc: ^Mut_Doc, obj: ^Mut_Val, key: cstring, new_key: cstring) -> bool ---

	/** Replaces all matching keys with the new key.
	Returns true if at least one key was renamed.
	The `key` and `new_key` should be a UTF-8 string,
	null-terminator is not required. The `new_key` is copied and held by doc.

	@warning This function takes a linear search time.
	If `new_key` already exists, it will cause duplicate keys.
	*/
	mut_obj_rename_keyn :: proc(doc: ^Mut_Doc, obj: ^Mut_Val, key: cstring, len: c.size_t, new_key: cstring, new_len: c.size_t) -> bool ---

	/**
	Get value by a JSON Pointer.
	@param doc The JSON document to be queried.
	@param ptr The JSON pointer string (UTF-8 with null-terminator).
	@return The value referenced by the JSON pointer.
	NULL if `doc` or `ptr` is NULL, or the JSON pointer cannot be resolved.
	*/
	doc_ptr_get :: proc(doc: ^Doc, ptr: cstring) -> ^Val ---

	/**
	Get value by a JSON Pointer.
	@param doc The JSON document to be queried.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@return The value referenced by the JSON pointer.
	NULL if `doc` or `ptr` is NULL, or the JSON pointer cannot be resolved.
	*/
	doc_ptr_getn :: proc(doc: ^Doc, ptr: cstring, len: c.size_t) -> ^Val ---

	/**
	Get value by a JSON Pointer.
	@param doc The JSON document to be queried.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param err A pointer to store the error information, or NULL if not needed.
	@return The value referenced by the JSON pointer.
	NULL if `doc` or `ptr` is NULL, or the JSON pointer cannot be resolved.
	*/
	doc_ptr_getx :: proc(doc: ^Doc, ptr: cstring, len: c.size_t, err: ^Ptr_Err = nil) -> ^Val ---

	/**
	Get value by a JSON Pointer.
	@param val The JSON value to be queried.
	@param ptr The JSON pointer string (UTF-8 with null-terminator).
	@return The value referenced by the JSON pointer.
	NULL if `val` or `ptr` is NULL, or the JSON pointer cannot be resolved.
	*/
	ptr_get :: proc(val: ^Val, ptr: cstring) -> ^Val ---

	/**
	Get value by a JSON Pointer.
	@param val The JSON value to be queried.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@return The value referenced by the JSON pointer.
	NULL if `val` or `ptr` is NULL, or the JSON pointer cannot be resolved.
	*/
	ptr_getn :: proc(val: ^Val, ptr: cstring, len: c.size_t) -> ^Val ---

	/**
	Get value by a JSON Pointer.
	@param val The JSON value to be queried.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param err A pointer to store the error information, or NULL if not needed.
	@return The value referenced by the JSON pointer.
	NULL if `val` or `ptr` is NULL, or the JSON pointer cannot be resolved.
	*/
	ptr_getx :: proc(val: ^Val, ptr: cstring, len: c.size_t, err: ^Ptr_Err = nil) -> ^Val ---

	/**
	Get value by a JSON Pointer.
	@param doc The JSON document to be queried.
	@param ptr The JSON pointer string (UTF-8 with null-terminator).
	@return The value referenced by the JSON pointer.
	NULL if `doc` or `ptr` is NULL, or the JSON pointer cannot be resolved.
	*/
	mut_doc_ptr_get :: proc(doc: ^Mut_Doc, ptr: cstring) -> ^Mut_Val ---

	/**
	Get value by a JSON Pointer.
	@param doc The JSON document to be queried.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@return The value referenced by the JSON pointer.
	NULL if `doc` or `ptr` is NULL, or the JSON pointer cannot be resolved.
	*/
	mut_doc_ptr_getn :: proc(doc: ^Mut_Doc, ptr: cstring, len: c.size_t) -> ^Mut_Val ---

	/**
	Get value by a JSON Pointer.
	@param doc The JSON document to be queried.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param ctx A pointer to store the result context, or NULL if not needed.
	@param err A pointer to store the error information, or NULL if not needed.
	@return The value referenced by the JSON pointer.
	NULL if `doc` or `ptr` is NULL, or the JSON pointer cannot be resolved.
	*/
	mut_doc_ptr_getx :: proc(doc: ^Mut_Doc, ptr: cstring, len: c.size_t, ctx: ^Ptr_Ctx = nil, err: ^Ptr_Err = nil) -> ^Mut_Val ---

	/**
	Get value by a JSON Pointer.
	@param val The JSON value to be queried.
	@param ptr The JSON pointer string (UTF-8 with null-terminator).
	@return The value referenced by the JSON pointer.
	NULL if `val` or `ptr` is NULL, or the JSON pointer cannot be resolved.
	*/
	mut_ptr_get :: proc(val: ^Mut_Val, ptr: cstring) -> ^Mut_Val ---

	/**
	Get value by a JSON Pointer.
	@param val The JSON value to be queried.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@return The value referenced by the JSON pointer.
	NULL if `val` or `ptr` is NULL, or the JSON pointer cannot be resolved.
	*/
	mut_ptr_getn :: proc(val: ^Mut_Val, ptr: cstring, len: c.size_t) -> ^Mut_Val ---

	/**
	Get value by a JSON Pointer.
	@param val The JSON value to be queried.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param ctx A pointer to store the result context, or NULL if not needed.
	@param err A pointer to store the error information, or NULL if not needed.
	@return The value referenced by the JSON pointer.
	NULL if `val` or `ptr` is NULL, or the JSON pointer cannot be resolved.
	*/
	mut_ptr_getx :: proc(val: ^Mut_Val, ptr: cstring, len: c.size_t, ctx: ^Ptr_Ctx = nil, err: ^Ptr_Err = nil) -> ^Mut_Val ---

	/**
	Add (insert) value by a JSON pointer.
	@param doc The target JSON document.
	@param ptr The JSON pointer string (UTF-8 with null-terminator).
	@param new_val The value to be added.
	@return true if JSON pointer is valid and new value is added, false otherwise.
	@note The parent nodes will be created if they do not exist.
	*/
	mut_doc_ptr_add :: proc(doc: ^Mut_Doc, ptr: cstring, new_val: ^Mut_Val) -> bool ---

	/**
	Add (insert) value by a JSON pointer.
	@param doc The target JSON document.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param new_val The value to be added.
	@return true if JSON pointer is valid and new value is added, false otherwise.
	@note The parent nodes will be created if they do not exist.
	*/
	mut_doc_ptr_addn :: proc(doc: ^Mut_Doc, ptr: cstring, len: c.size_t, new_val: ^Mut_Val) -> bool ---

	/**
	Add (insert) value by a JSON pointer.
	@param doc The target JSON document.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param new_val The value to be added.
	@param create_parent Whether to create parent nodes if not exist.
	@param ctx A pointer to store the result context, or NULL if not needed.
	@param err A pointer to store the error information, or NULL if not needed.
	@return true if JSON pointer is valid and new value is added, false otherwise.
	*/
	mut_doc_ptr_addx :: proc(doc: ^Mut_Doc, ptr: cstring, len: c.size_t, new_val: ^Mut_Val, create_parent: bool, ctx: ^Ptr_Ctx = nil, err: ^Ptr_Err = nil) -> bool ---

	/**
	Add (insert) value by a JSON pointer.
	@param val The target JSON value.
	@param ptr The JSON pointer string (UTF-8 with null-terminator).
	@param doc Only used to create new values when needed.
	@param new_val The value to be added.
	@return true if JSON pointer is valid and new value is added, false otherwise.
	@note The parent nodes will be created if they do not exist.
	*/
	mut_ptr_add :: proc(val: ^Mut_Val, ptr: cstring, new_val: ^Mut_Val, doc: ^Mut_Doc) -> bool ---

	/**
	Add (insert) value by a JSON pointer.
	@param val The target JSON value.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param doc Only used to create new values when needed.
	@param new_val The value to be added.
	@return true if JSON pointer is valid and new value is added, false otherwise.
	@note The parent nodes will be created if they do not exist.
	*/
	mut_ptr_addn :: proc(val: ^Mut_Val, ptr: cstring, len: c.size_t, new_val: ^Mut_Val, doc: ^Mut_Doc) -> bool ---

	/**
	Add (insert) value by a JSON pointer.
	@param val The target JSON value.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param doc Only used to create new values when needed.
	@param new_val The value to be added.
	@param create_parent Whether to create parent nodes if not exist.
	@param ctx A pointer to store the result context, or NULL if not needed.
	@param err A pointer to store the error information, or NULL if not needed.
	@return true if JSON pointer is valid and new value is added, false otherwise.
	*/
	mut_ptr_addx :: proc(val: ^Mut_Val, ptr: cstring, len: c.size_t, new_val: ^Mut_Val, doc: ^Mut_Doc, create_parent: bool, ctx: ^Ptr_Ctx = nil, err: ^Ptr_Err = nil) -> bool ---

	/**
	Set value by a JSON pointer.
	@param doc The target JSON document.
	@param ptr The JSON pointer string (UTF-8 with null-terminator).
	@param new_val The value to be set, pass NULL to remove.
	@return true if JSON pointer is valid and new value is set, false otherwise.
	@note The parent nodes will be created if they do not exist.
	If the target value already exists, it will be replaced by the new value.
	*/
	mut_doc_ptr_set :: proc(doc: ^Mut_Doc, ptr: cstring, new_val: ^Mut_Val) -> bool ---

	/**
	Set value by a JSON pointer.
	@param doc The target JSON document.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param new_val The value to be set, pass NULL to remove.
	@return true if JSON pointer is valid and new value is set, false otherwise.
	@note The parent nodes will be created if they do not exist.
	If the target value already exists, it will be replaced by the new value.
	*/
	mut_doc_ptr_setn :: proc(doc: ^Mut_Doc, ptr: cstring, len: c.size_t, new_val: ^Mut_Val) -> bool ---

	/**
	Set value by a JSON pointer.
	@param doc The target JSON document.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param new_val The value to be set, pass NULL to remove.
	@param create_parent Whether to create parent nodes if not exist.
	@param ctx A pointer to store the result context, or NULL if not needed.
	@param err A pointer to store the error information, or NULL if not needed.
	@return true if JSON pointer is valid and new value is set, false otherwise.
	@note If the target value already exists, it will be replaced by the new value.
	*/
	mut_doc_ptr_setx :: proc(doc: ^Mut_Doc, ptr: cstring, len: c.size_t, new_val: ^Mut_Val, create_parent: bool, ctx: ^Ptr_Ctx = nil, err: ^Ptr_Err = nil) -> bool ---

	/**
	Set value by a JSON pointer.
	@param val The target JSON value.
	@param ptr The JSON pointer string (UTF-8 with null-terminator).
	@param new_val The value to be set, pass NULL to remove.
	@param doc Only used to create new values when needed.
	@return true if JSON pointer is valid and new value is set, false otherwise.
	@note The parent nodes will be created if they do not exist.
	If the target value already exists, it will be replaced by the new value.
	*/
	mut_ptr_set :: proc(val: ^Mut_Val, ptr: cstring, new_val: ^Mut_Val, doc: ^Mut_Doc) -> bool ---

	/**
	Set value by a JSON pointer.
	@param val The target JSON value.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param new_val The value to be set, pass NULL to remove.
	@param doc Only used to create new values when needed.
	@return true if JSON pointer is valid and new value is set, false otherwise.
	@note The parent nodes will be created if they do not exist.
	If the target value already exists, it will be replaced by the new value.
	*/
	mut_ptr_setn :: proc(val: ^Mut_Val, ptr: cstring, len: c.size_t, new_val: ^Mut_Val, doc: ^Mut_Doc) -> bool ---

	/**
	Set value by a JSON pointer.
	@param val The target JSON value.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param new_val The value to be set, pass NULL to remove.
	@param doc Only used to create new values when needed.
	@param create_parent Whether to create parent nodes if not exist.
	@param ctx A pointer to store the result context, or NULL if not needed.
	@param err A pointer to store the error information, or NULL if not needed.
	@return true if JSON pointer is valid and new value is set, false otherwise.
	@note If the target value already exists, it will be replaced by the new value.
	*/
	mut_ptr_setx :: proc(val: ^Mut_Val, ptr: cstring, len: c.size_t, new_val: ^Mut_Val, doc: ^Mut_Doc, create_parent: bool, ctx: ^Ptr_Ctx = nil, err: ^Ptr_Err = nil) -> bool ---

	/**
	Replace value by a JSON pointer.
	@param doc The target JSON document.
	@param ptr The JSON pointer string (UTF-8 with null-terminator).
	@param new_val The new value to replace the old one.
	@return The old value that was replaced, or NULL if not found.
	*/
	mut_doc_ptr_replace :: proc(doc: ^Mut_Doc, ptr: cstring, new_val: ^Mut_Val) -> ^Mut_Val ---

	/**
	Replace value by a JSON pointer.
	@param doc The target JSON document.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param new_val The new value to replace the old one.
	@return The old value that was replaced, or NULL if not found.
	*/
	mut_doc_ptr_replacen :: proc(doc: ^Mut_Doc, ptr: cstring, len: c.size_t, new_val: ^Mut_Val) -> ^Mut_Val ---

	/**
	Replace value by a JSON pointer.
	@param doc The target JSON document.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param new_val The new value to replace the old one.
	@param ctx A pointer to store the result context, or NULL if not needed.
	@param err A pointer to store the error information, or NULL if not needed.
	@return The old value that was replaced, or NULL if not found.
	*/
	mut_doc_ptr_replacex :: proc(doc: ^Mut_Doc, ptr: cstring, len: c.size_t, new_val: ^Mut_Val, ctx: ^Ptr_Ctx = nil, err: ^Ptr_Err = nil) -> ^Mut_Val ---

	/**
	Replace value by a JSON pointer.
	@param val The target JSON value.
	@param ptr The JSON pointer string (UTF-8 with null-terminator).
	@param new_val The new value to replace the old one.
	@return The old value that was replaced, or NULL if not found.
	*/
	mut_ptr_replace :: proc(val: ^Mut_Val, ptr: cstring, new_val: ^Mut_Val) -> ^Mut_Val ---

	/**
	Replace value by a JSON pointer.
	@param val The target JSON value.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param new_val The new value to replace the old one.
	@return The old value that was replaced, or NULL if not found.
	*/
	mut_ptr_replacen :: proc(val: ^Mut_Val, ptr: cstring, len: c.size_t, new_val: ^Mut_Val) -> ^Mut_Val ---

	/**
	Replace value by a JSON pointer.
	@param val The target JSON value.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param new_val The new value to replace the old one.
	@param ctx A pointer to store the result context, or NULL if not needed.
	@param err A pointer to store the error information, or NULL if not needed.
	@return The old value that was replaced, or NULL if not found.
	*/
	mut_ptr_replacex :: proc(val: ^Mut_Val, ptr: cstring, len: c.size_t, new_val: ^Mut_Val, ctx: ^Ptr_Ctx = nil, err: ^Ptr_Err = nil) -> ^Mut_Val ---

	/**
	Remove value by a JSON pointer.
	@param doc The target JSON document.
	@param ptr The JSON pointer string (UTF-8 with null-terminator).
	@return The removed value, or NULL on error.
	*/
	mut_doc_ptr_remove :: proc(doc: ^Mut_Doc, ptr: cstring) -> ^Mut_Val ---

	/**
	Remove value by a JSON pointer.
	@param doc The target JSON document.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@return The removed value, or NULL on error.
	*/
	mut_doc_ptr_removen :: proc(doc: ^Mut_Doc, ptr: cstring, len: c.size_t) -> ^Mut_Val ---

	/**
	Remove value by a JSON pointer.
	@param doc The target JSON document.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param ctx A pointer to store the result context, or NULL if not needed.
	@param err A pointer to store the error information, or NULL if not needed.
	@return The removed value, or NULL on error.
	*/
	mut_doc_ptr_removex :: proc(doc: ^Mut_Doc, ptr: cstring, len: c.size_t, ctx: ^Ptr_Ctx = nil, err: ^Ptr_Err = nil) -> ^Mut_Val ---

	/**
	Remove value by a JSON pointer.
	@param val The target JSON value.
	@param ptr The JSON pointer string (UTF-8 with null-terminator).
	@return The removed value, or NULL on error.
	*/
	mut_ptr_remove :: proc(val: ^Mut_Val, ptr: cstring) -> ^Mut_Val ---

	/**
	Remove value by a JSON pointer.
	@param val The target JSON value.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@return The removed value, or NULL on error.
	*/
	mut_ptr_removen :: proc(val: ^Mut_Val, ptr: cstring, len: c.size_t) -> ^Mut_Val ---

	/**
	Remove value by a JSON pointer.
	@param val The target JSON value.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param ctx A pointer to store the result context, or NULL if not needed.
	@param err A pointer to store the error information, or NULL if not needed.
	@return The removed value, or NULL on error.
	*/
	mut_ptr_removex :: proc(val: ^Mut_Val, ptr: cstring, len: c.size_t, ctx: ^Ptr_Ctx = nil, err: ^Ptr_Err = nil) -> ^Mut_Val ---

	/**
	Append value by JSON pointer context.
	@param ctx The context from the `yyjson_mut_ptr_xxx()` calls.
	@param key New key if `ctx->ctn` is object, or NULL if `ctx->ctn` is array.
	@param val New value to be added.
	@return true on success or false on fail.
	*/
	ptr_ctx_append :: proc(ctx: ^Ptr_Ctx, key: ^Mut_Val, val: ^Mut_Val) -> bool ---

	/**
	Replace value by JSON pointer context.
	@param ctx The context from the `yyjson_mut_ptr_xxx()` calls.
	@param val New value to be replaced.
	@return true on success or false on fail.
	@note If success, the old value will be returned via `ctx->old`.
	*/
	ptr_ctx_replace :: proc(ctx: ^Ptr_Ctx, val: ^Mut_Val) -> bool ---

	/**
	Remove value by JSON pointer context.
	@param ctx The context from the `yyjson_mut_ptr_xxx()` calls.
	@return true on success or false on fail.
	@note If success, the old value will be returned via `ctx->old`.
	*/
	ptr_ctx_remove :: proc(ctx: ^Ptr_Ctx) -> bool ---

	/**
	Creates and returns a patched JSON value (RFC 6902).
	The memory of the returned value is allocated by the `doc`.
	The `err` is used to receive error information, pass NULL if not needed.
	Returns NULL if the patch could not be applied.
	*/
	patch :: proc(doc: ^Mut_Doc, orig: ^Val, patch: ^Val, err: ^Patch_Err = nil) -> ^Mut_Val ---

	/**
	Creates and returns a patched JSON value (RFC 6902).
	The memory of the returned value is allocated by the `doc`.
	The `err` is used to receive error information, pass NULL if not needed.
	Returns NULL if the patch could not be applied.
	*/
	mut_patch :: proc(doc: ^Mut_Doc, orig: ^Mut_Val, patch: ^Mut_Val, err: ^Patch_Err = nil) -> ^Mut_Val ---

	/**
	Creates and returns a merge-patched JSON value (RFC 7386).
	The memory of the returned value is allocated by the `doc`.
	Returns NULL if the patch could not be applied.

	@warning This function is recursive and may cause a stack overflow if the
	object level is too deep.
	*/
	merge_patch :: proc(doc: ^Mut_Doc, orig: ^Val, patch: ^Val) -> ^Mut_Val ---

	/**
	Creates and returns a merge-patched JSON value (RFC 7386).
	The memory of the returned value is allocated by the `doc`.
	Returns NULL if the patch could not be applied.

	@warning This function is recursive and may cause a stack overflow if the
	object level is too deep.
	*/
	mut_merge_patch :: proc(doc: ^Mut_Doc, orig: ^Mut_Val, patch: ^Mut_Val) -> ^Mut_Val ---

	/*
	Whether the string does not need to be escaped for serialization.
	This function is used to optimize the writing speed of small constant strings.
	This function works only if the compiler can evaluate it at compile time.

	Clang supports it since v8.0,
	earlier versions do not support constant_p(strlen) and return false.
	GCC supports it since at least v4.4,
	earlier versions may compile it as run-time instructions.
	ICC supports it since at least v16,
	earlier versions are uncertain.

	@param str The C string.
	@param len The returnd value from strlen(str).
	*/
	unsafe_yyjson_is_str_noesc :: proc(str: cstring, len: c.size_t) -> bool ---
	unsafe_yyjson_u64_to_f64 :: proc(num: u64) -> f64 ---
	unsafe_yyjson_get_type :: proc(val: rawptr) -> Type ---
	unsafe_yyjson_get_subtype :: proc(val: rawptr) -> Subtype ---
	unsafe_yyjson_get_tag :: proc(val: rawptr) -> u8 ---
	unsafe_yyjson_is_raw :: proc(val: rawptr) -> bool ---
	unsafe_yyjson_is_null :: proc(val: rawptr) -> bool ---
	unsafe_yyjson_is_bool :: proc(val: rawptr) -> bool ---
	unsafe_yyjson_is_num :: proc(val: rawptr) -> bool ---
	unsafe_yyjson_is_str :: proc(val: rawptr) -> bool ---
	unsafe_yyjson_is_arr :: proc(val: rawptr) -> bool ---
	unsafe_yyjson_is_obj :: proc(val: rawptr) -> bool ---
	unsafe_yyjson_is_ctn :: proc(val: rawptr) -> bool ---
	unsafe_yyjson_is_uint :: proc(val: rawptr) -> bool ---
	unsafe_yyjson_is_sint :: proc(val: rawptr) -> bool ---
	unsafe_yyjson_is_int :: proc(val: rawptr) -> bool ---
	unsafe_yyjson_is_real :: proc(val: rawptr) -> bool ---
	unsafe_yyjson_is_true :: proc(val: rawptr) -> bool ---
	unsafe_yyjson_is_false :: proc(val: rawptr) -> bool ---
	unsafe_yyjson_arr_is_flat :: proc(val: ^Val) -> bool ---
	unsafe_yyjson_get_raw :: proc(val: rawptr) -> cstring ---
	unsafe_yyjson_get_bool :: proc(val: rawptr) -> bool ---
	unsafe_yyjson_get_uint :: proc(val: rawptr) -> u64 ---
	unsafe_yyjson_get_sint :: proc(val: rawptr) -> i64 ---
	unsafe_yyjson_get_int :: proc(val: rawptr) -> i32 ---
	unsafe_yyjson_get_real :: proc(val: rawptr) -> f64 ---
	unsafe_yyjson_get_num :: proc(val: rawptr) -> f64 ---
	unsafe_yyjson_get_str :: proc(val: rawptr) -> cstring ---
	unsafe_yyjson_get_len :: proc(val: rawptr) -> c.size_t ---
	unsafe_yyjson_get_first :: proc(ctn: ^Val) -> ^Val ---
	unsafe_yyjson_get_next :: proc(val: ^Val) -> ^Val ---
	unsafe_yyjson_equals_strn :: proc(val: rawptr, str: cstring, len: c.size_t) -> bool ---
	unsafe_yyjson_equals_str :: proc(val: rawptr, str: cstring) -> bool ---
	unsafe_yyjson_set_type :: proc(val: rawptr, type: Type, subtype: Subtype) ---
	unsafe_yyjson_set_len :: proc(val: rawptr, len: c.size_t) ---
	unsafe_yyjson_set_tag :: proc(val: rawptr, type: Type, subtype: Subtype, len: c.size_t) ---
	unsafe_yyjson_inc_len :: proc(val: rawptr) ---
	unsafe_yyjson_set_raw :: proc(val: rawptr, raw: cstring, len: c.size_t) ---
	unsafe_yyjson_set_null :: proc(val: rawptr) ---
	unsafe_yyjson_set_bool :: proc(val: rawptr, num: bool) ---
	unsafe_yyjson_set_uint :: proc(val: rawptr, num: u64) ---
	unsafe_yyjson_set_sint :: proc(val: rawptr, num: i64) ---
	unsafe_yyjson_set_fp_to_fixed :: proc(val: rawptr, prec: i32) ---
	unsafe_yyjson_set_fp_to_float :: proc(val: rawptr, flt: bool) ---
	unsafe_yyjson_set_float :: proc(val: rawptr, num: f32) ---
	unsafe_yyjson_set_double :: proc(val: rawptr, num: f64) ---
	unsafe_yyjson_set_real :: proc(val: rawptr, num: f64) ---
	unsafe_yyjson_set_str_noesc :: proc(val: rawptr, noesc: bool) ---
	unsafe_yyjson_set_strn :: proc(val: rawptr, str: cstring, len: c.size_t) ---
	unsafe_yyjson_set_str :: proc(val: rawptr, str: cstring) ---
	unsafe_yyjson_set_arr :: proc(val: rawptr, size: c.size_t) ---
	unsafe_yyjson_set_obj :: proc(val: rawptr, size: c.size_t) ---
	unsafe_yyjson_equals :: proc(lhs: ^Val, rhs: ^Val) -> bool ---

	/* Ensures the capacity to at least equal to the specified byte length. */
	unsafe_yyjson_str_pool_grow :: proc(pool: ^Str_Pool, alc: ^Alc = nil, len: c.size_t) -> bool ---

	/* Ensures the capacity to at least equal to the specified value count. */
	unsafe_yyjson_val_pool_grow :: proc(pool: ^Val_Pool, alc: ^Alc = nil, count: c.size_t) -> bool ---

	/* Allocate memory for string. */
	unsafe_yyjson_mut_str_alc :: proc(doc: ^Mut_Doc, len: c.size_t) -> cstring ---
	unsafe_yyjson_mut_strncpy :: proc(doc: ^Mut_Doc, str: cstring, len: c.size_t) -> cstring ---
	unsafe_yyjson_mut_val :: proc(doc: ^Mut_Doc, count: c.size_t) -> ^Mut_Val ---
	unsafe_yyjson_mut_equals :: proc(lhs: ^Mut_Val, rhs: ^Mut_Val) -> bool ---

	/*==============================================================================
	* MARK: - Mutable JSON Object Modification API (Implementation)
	*============================================================================*/
	unsafe_yyjson_mut_obj_add :: proc(obj: ^Mut_Val, key: ^Mut_Val, val: ^Mut_Val, len: c.size_t) ---
	unsafe_yyjson_mut_obj_remove :: proc(obj: ^Mut_Val, key: cstring, key_len: c.size_t) -> ^Mut_Val ---
	unsafe_yyjson_mut_obj_replace :: proc(obj: ^Mut_Val, key: ^Mut_Val, val: ^Mut_Val) -> bool ---
	unsafe_yyjson_mut_obj_rotate :: proc(obj: ^Mut_Val, idx: c.size_t) ---

	/* require: val != NULL, *ptr == '/', len > 0 */
	unsafe_yyjson_ptr_getx :: proc(val: ^Val, ptr: cstring, len: c.size_t, err: ^Ptr_Err) -> ^Val ---

	/* require: val != NULL, *ptr == '/', len > 0 */
	unsafe_yyjson_mut_ptr_getx :: proc(val: ^Mut_Val, ptr: cstring, len: c.size_t, ctx: ^Ptr_Ctx, err: ^Ptr_Err) -> ^Mut_Val ---

	/* require: val/new_val/doc != NULL, *ptr == '/', len > 0 */
	unsafe_yyjson_mut_ptr_putx :: proc(val: ^Mut_Val, ptr: cstring, len: c.size_t, new_val: ^Mut_Val, doc: ^Mut_Doc, create_parent: bool, insert_new: bool, ctx: ^Ptr_Ctx, err: ^Ptr_Err) -> bool ---

	/* require: val/err != NULL, *ptr == '/', len > 0 */
	unsafe_yyjson_mut_ptr_replacex :: proc(val: ^Mut_Val, ptr: cstring, len: c.size_t, new_val: ^Mut_Val, ctx: ^Ptr_Ctx, err: ^Ptr_Err) -> ^Mut_Val ---

	/* require: val/err != NULL, *ptr == '/', len > 0 */
	unsafe_yyjson_mut_ptr_removex :: proc(val: ^Mut_Val, ptr: cstring, len: c.size_t, ctx: ^Ptr_Ctx, err: ^Ptr_Err) -> ^Mut_Val ---

	/**
	Set provided `value` if the JSON Pointer (RFC 6901) exists and is type bool.
	Returns true if value at `ptr` exists and is the correct type, otherwise false.
	*/
	ptr_get_bool :: proc(root: ^Val, ptr: cstring, value: ^bool) -> bool ---

	/**
	Set provided `value` if the JSON Pointer (RFC 6901) exists and is an integer
	that fits in `uint64_t`. Returns true if successful, otherwise false.
	*/
	ptr_get_uint :: proc(root: ^Val, ptr: cstring, value: ^u64) -> bool ---

	/**
	Set provided `value` if the JSON Pointer (RFC 6901) exists and is an integer
	that fits in `int64_t`. Returns true if successful, otherwise false.
	*/
	ptr_get_sint :: proc(root: ^Val, ptr: cstring, value: ^i64) -> bool ---

	/**
	Set provided `value` if the JSON Pointer (RFC 6901) exists and is type real.
	Returns true if value at `ptr` exists and is the correct type, otherwise false.
	*/
	ptr_get_real :: proc(root: ^Val, ptr: cstring, value: ^f64) -> bool ---

	/**
	Set provided `value` if the JSON Pointer (RFC 6901) exists and is type sint,
	uint or real.
	Returns true if value at `ptr` exists and is the correct type, otherwise false.
	*/
	ptr_get_num :: proc(root: ^Val, ptr: cstring, value: ^f64) -> bool ---

	/**
	Set provided `value` if the JSON Pointer (RFC 6901) exists and is type string.
	Returns true if value at `ptr` exists and is the correct type, otherwise false.
	*/
	ptr_get_str :: proc(root: ^Val, ptr: cstring, value: ^cstring) -> bool ---

	/** @deprecated renamed to `yyjson_doc_ptr_get` */
	doc_get_pointer :: proc(doc: ^Doc, ptr: cstring) -> ^Val ---

	/** @deprecated renamed to `yyjson_doc_ptr_getn` */
	doc_get_pointern :: proc(doc: ^Doc, ptr: cstring, len: c.size_t) -> ^Val ---

	/** @deprecated renamed to `yyjson_mut_doc_ptr_get` */
	mut_doc_get_pointer :: proc(doc: ^Mut_Doc, ptr: cstring) -> ^Mut_Val ---

	/** @deprecated renamed to `yyjson_mut_doc_ptr_getn` */
	mut_doc_get_pointern :: proc(doc: ^Mut_Doc, ptr: cstring, len: c.size_t) -> ^Mut_Val ---

	/** @deprecated renamed to `yyjson_ptr_get` */
	get_pointer :: proc(val: ^Val, ptr: cstring) -> ^Val ---

	/** @deprecated renamed to `yyjson_ptr_getn` */
	get_pointern :: proc(val: ^Val, ptr: cstring, len: c.size_t) -> ^Val ---

	/** @deprecated renamed to `yyjson_mut_ptr_get` */
	mut_get_pointer :: proc(val: ^Mut_Val, ptr: cstring) -> ^Mut_Val ---

	/** @deprecated renamed to `yyjson_mut_ptr_getn` */
	mut_get_pointern :: proc(val: ^Mut_Val, ptr: cstring, len: c.size_t) -> ^Mut_Val ---

	/** @deprecated renamed to `yyjson_mut_ptr_getn` */
	unsafe_yyjson_get_pointer :: proc(val: ^Val, ptr: cstring, len: c.size_t) -> ^Val ---

	/** @deprecated renamed to `unsafe_yyjson_mut_ptr_getx` */
	unsafe_yyjson_mut_get_pointer :: proc(val: ^Mut_Val, ptr: cstring, len: c.size_t) -> ^Mut_Val ---
}

/** YYJSON_WRITE_FP_TO_FIXED is an extra feature that combines multiple bits to set the fp precision.
    This doesn't play well with the other flags all fitting into a bitset cleanly.

	Write floating-point number using fixed-point notation.
	- This is similar to ECMAScript `Number.prototype.toFixed(prec)`,
	  but with trailing zeros removed. The `prec` ranges from 1 to 15.
	- This will produce shorter output but may lose some precision. */
write_flags_add_write_fp_to_fixed_precision_bits :: proc(flag: Write_Flags, precision: c.uint32_t) -> Write_Flags {
	write_fp_to_fixed_bits := precision << (32 - 4)
	new_flag := transmute(c.uint32_t)flag | write_fp_to_fixed_bits
	return transmute(Write_Flags)new_flag
}
