package yyjson

import "core:c"
import "core:c/libc"


when ODIN_OS == .Windows {
	// yyjson.lib is shipped with these bindings, but can be rebuilt manually with ./src/build.bat
	foreign import yyjson "lib/yyjson.lib"
} else when ODIN_OS == .Linux || ODIN_OS == .FreeBSD || ODIN_OS == .OpenBSD || ODIN_OS == .NetBSD {
	when !#exists("lib/yyjson.a") {
		#panic("Cannot find compiled yyjson libraries ./lib/yyjson.a. Compile by running `make -C src`")
	}
	foreign import yyjson "lib/yyjson.a"
} else when ODIN_OS == .Darwin {
	when !#exists("lib/darwin/yyjson.a") {
		#panic("Cannot find compiled yyjson libraries ./lib/darwin/yyjson.a for ODIN_OS.Darwin. Compile by running `make -C src`")
	}
	foreign import yyjson "lib/darwin/yyjson.a"
} else {
	// Unknown OS. Fallback to searching for a global system installed library (also c.f. LD_LIBRARY_PATH)
	foreign import yyjson "system:yyjson"
}


malloc_func :: #type proc(ctx: rawptr, size: c.size_t) -> rawptr
realloc_func :: #type proc(ctx: rawptr, ptr: rawptr, old_size: c.size_t, size: c.size_t) -> rawptr
free_func :: #type proc(ctx: rawptr, ptr: rawptr) -> rawptr

// A memory allocator. Typically you don't need to use it, unless you want to customize your own memory allocator.
alc :: struct {
	// odin has the same struct layout as C, but padding may not be zero inited
	malloc:  malloc_func,
	realloc: realloc_func,
	free:    free_func,
	ctx:     rawptr,
}

// Payload of a JSON value (8 bytes).
val_uni :: struct #raw_union {
	u64: c.uint64_t,
	i64: c.int64_t,
	f64: c.double,
	str: cstring,
	ptr: rawptr,
	ofs: c.size_t,
}

// Mutable JSON value, 24 bytes. The 'tag' and 'uni' field is same as immutable value. The 'next' field links all elements inside the container to be a cycle.
mut_val :: struct {
	next: ^mut_val,
	tag:  c.uint64_t,
	uni:  val_uni, // payload
}

val :: struct {
	tag: c.uint64_t,
	uni: val_uni,
}

// A mutable JSON object iterator.
mut_obj_iter :: struct {
	idx: c.size_t,
	max: c.size_t,
	cur: ^mut_val,
	pre: ^mut_val,
	obj: ^mut_val,
}

// A mutable JSON array iterator.
mut_arr_iter :: struct {
	idx: c.size_t,
	max: c.size_t,
	cur: ^mut_val,
	pre: ^mut_val,
	obj: ^mut_val,
}

// A JSON object iterator
obj_iter :: struct {
	idx: c.size_t,
	max: c.size_t,
	cur: ^val,
	obj: ^val,
}

arr_iter :: struct {
	idx: c.size_t,
	max: c.size_t,
	cur: ^val,
}

// A memory chunk in string memory pool.
str_chunk :: struct {
	next:       [^]str_chunk,
	chunk_size: c.size_t,
}

// A memory chunk in value memory pool. sizeof(val_chunk) should not larger than sizeof(mut_val).
val_chunk :: struct {
	next:       [^]val_chunk,
	chunk_size: c.size_t,
}

// A memory pool to hold all strings in a mutable document.
str_pool :: struct {
	cur:            [^]c.char, // cursor inside current chunk
	end:            [^]c.char, // end of current chunk
	chunk_size:     c.size_t,
	chunk_size_max: c.size_t,
	chunks:         [^]str_chunk,
}

// A memory pool to hold all values in a mutable document.
val_pool :: struct {
	cur:            [^]mut_val,
	end:            [^]mut_val,
	chunk_size:     c.size_t,
	chunk_size_max: c.size_t,
	chunks:         [^]val_chunk,
}

// Context for JSON pointer operation.
ptr_ctx :: struct {
	ctn: ^mut_val,
	pre: ^mut_val,
	old: ^mut_val,
}

// JSON Pointer error code
ptr_code :: enum c.uint32_t {
	/** No JSON pointer error. */
	YYJSON_PTR_ERR_NONE              = 0,

	/** Invalid input parameter, such as NULL input. */
	YYJSON_PTR_ERR_PARAMETER         = 1,

	/** JSON pointer syntax error, such as invalid escape, token no prefix. */
	YYJSON_PTR_ERR_SYNTAX            = 2,

	/** JSON pointer resolve failed, such as index out of range, key not found. */
	YYJSON_PTR_ERR_RESOLVE           = 3,

	/** Document's root is NULL, but it is required for the function call. */
	YYJSON_PTR_ERR_NULL_ROOT         = 4,

	/** Cannot set root as the target is not a document. */
	YYJSON_PTR_ERR_SET_ROOT          = 5,

	/** The memory allocation failed and a new value could not be created. */
	YYJSON_PTR_ERR_MEMORY_ALLOCATION = 6,
}


// Error information for JSON pointer
ptr_err :: struct {
	code: ptr_code,
	msg:  cstring,
	pos:  c.size_t,
}


// Result code for JSON patch
patch_code :: enum c.uint32_t {
	/** Success, no error. */
	YYJSON_PATCH_SUCCESS                 = 0,

	/** Invalid parameter, such as NULL input or non-array patch. */
	YYJSON_PATCH_ERROR_INVALID_PARAMETER = 1,

	/** Memory allocation failure occurs. */
	YYJSON_PATCH_ERROR_MEMORY_ALLOCATION = 2,

	/** JSON patch operation is not object type. */
	YYJSON_PATCH_ERROR_INVALID_OPERATION = 3,

	/** JSON patch operation is missing a required key. */
	YYJSON_PATCH_ERROR_MISSING_KEY       = 4,

	/** JSON patch operation member is invalid. */
	YYJSON_PATCH_ERROR_INVALID_MEMBER    = 5,

	/** JSON patch operation `test` not equal. */
	YYJSON_PATCH_ERROR_EQUAL             = 6,

	/** JSON patch operation failed on JSON pointer. */
	YYJSON_PATCH_ERROR_POINTER           = 7,
}

// Error information for JSON patch.
patch_err :: struct {
	code: patch_code,
	idx:  c.size_t,
	msg:  cstring,
	ptr:  ptr_err,
}

// A mutable document for building JSON. This document holds memory for all its JSON values and strings. When it is no longer used, the user should call yyjson_mut_doc_free() to free its memory.
mut_doc :: struct {
	alc:      alc, // non null
	root:     ^mut_val, // nullable
	str_pool: str_pool, // string memory pool
	val_pool: val_pool, // value memory pool
}

doc :: struct {
	root:     ^val,
	alc:      alc,
	dat_read: c.size_t,
	val_read: c.size_t,
	str_pool: ^c.char,
}


// Run-time options for JSON reader
// Default option (YYJSON_READ_NOFLAG):
// - Read positive integer as uint64_t.
// - Read negative integer as int64_t.
// - Read floating-point number as double with round-to-nearest mode.
// - Read integer which cannot fit in uint64_t or int64_t as double.
// - Report error if double number is infinity.
// - Report error if string contains invalid UTF-8 character or BOM.
// - Report error on trailing commas, comments, inf and nan literals.
Read_Flags :: enum c.uint32_t {
	/** Read the input data in-situ.
    This option allows the reader to modify and use input data to store string
    values, which can increase reading speed slightly.
    The caller should hold the input data before free the document.
    The input data must be padded by at least `YYJSON_PADDING_SIZE` bytes.
    For example: `[1,2]` should be `[1,2]\0\0\0\0`, input length should be 5. */
	YYJSON_READ_INSITU                = 0, // 1 << 0,

	/** Stop when done instead of issuing an error if there's additional content
	    after a JSON document. This option may be used to parse small pieces of JSON
	    in larger data, such as `NDJSON`. */
	YYJSON_READ_STOP_WHEN_DONE        = 1, // 1 << 1,

	/** Allow single trailing comma at the end of an object or array,
	    such as `[1,2,3,]`, `{"a":1,"b":2,}` (non-standard). */
	YYJSON_READ_ALLOW_TRAILING_COMMAS = 2, // 1 << 2,

	/** Allow C-style single line and multiple line comments (non-standard). */
	YYJSON_READ_ALLOW_COMMENTS        = 3, // 1 << 3,

	/** Allow inf/nan number and literal, case-insensitive,
	    such as 1e999, NaN, inf, -Infinity (non-standard). */
	YYJSON_READ_ALLOW_INF_AND_NAN     = 4, // 1 << 4,

	/** Read all numbers as raw strings (value with `YYJSON_TYPE_RAW` type),
	    inf/nan literal is also read as raw with `ALLOW_INF_AND_NAN` flag. */
	YYJSON_READ_NUMBER_AS_RAW         = 5, // 1 << 5,

	/** Allow reading invalid unicode when parsing string values (non-standard).
	    Invalid characters will be allowed to appear in the string values, but
	    invalid escape sequences will still be reported as errors.
	    This flag does not affect the performance of correctly encoded strings.

	    @warning Strings in JSON values may contain incorrect encoding when this
	    option is used, you need to handle these strings carefully to avoid security
	    risks. */
	YYJSON_READ_ALLOW_INVALID_UNICODE = 6, // 1 << 6,

	/** Read big numbers as raw strings. These big numbers include integers that
	    cannot be represented by `int64_t` and `uint64_t`, and floating-point
	    numbers that cannot be represented by finite `double`.
	    The flag will be overridden by `YYJSON_READ_NUMBER_AS_RAW` flag. */
	YYJSON_READ_BIGNUM_AS_RAW         = 7, // 1 << 7,
}

read_flag :: bit_set[Read_Flags;c.uint32_t]

read_code :: enum c.uint32_t {
	/** Success, no error. */
	YYJSON_READ_SUCCESS                    = 0,

	/** Invalid parameter, such as NULL input string or 0 input length. */
	YYJSON_READ_ERROR_INVALID_PARAMETER    = 1,

	/** Memory allocation failure occurs. */
	YYJSON_READ_ERROR_MEMORY_ALLOCATION    = 2,

	/** Input JSON string is empty. */
	YYJSON_READ_ERROR_EMPTY_CONTENT        = 3,

	/** Unexpected content after document, such as `[123]abc`. */
	YYJSON_READ_ERROR_UNEXPECTED_CONTENT   = 4,

	/** Unexpected ending, such as `[123`. */
	YYJSON_READ_ERROR_UNEXPECTED_END       = 5,

	/** Unexpected character inside the document, such as `[abc]`. */
	YYJSON_READ_ERROR_UNEXPECTED_CHARACTER = 6,

	/** Invalid JSON structure, such as `[1,]`. */
	YYJSON_READ_ERROR_JSON_STRUCTURE       = 7,

	/** Invalid comment, such as unclosed multi-line comment. */
	YYJSON_READ_ERROR_INVALID_COMMENT      = 8,

	/** Invalid number, such as `123.e12`, `000`. */
	YYJSON_READ_ERROR_INVALID_NUMBER       = 9,

	/** Invalid string, such as invalid escaped character inside a string. */
	YYJSON_READ_ERROR_INVALID_STRING       = 10,

	/** Invalid JSON literal, such as `truu`. */
	YYJSON_READ_ERROR_LITERAL              = 11,

	/** Failed to open a file. */
	YYJSON_READ_ERROR_FILE_OPEN            = 12,

	/** Failed to read a file. */
	YYJSON_READ_ERROR_FILE_READ            = 13,
}


read_err :: struct {
	code: read_code,
	msg:  cstring,
	pos:  c.size_t,
}

// Run-time options for JSON writer
// Default option (YYJSON_WRITE_NOFLAG):
//     - Write JSON minify.
//     - Report error on inf or nan number.
//     - Report error on invalid UTF-8 string.
//     - Do not escape unicode or slash.
Write_Flags :: enum c.uint32_t {
	/** Write JSON pretty with 4 space indent. */
	YYJSON_WRITE_PRETTY                = 0, // first bit, bit 0  (1 << 0)

	/** Escape unicode as `uXXXX`, make the output ASCII only. */
	YYJSON_WRITE_ESCAPE_UNICODE        = 1,

	/** Escape '/' as '\/'. */
	YYJSON_WRITE_ESCAPE_SLASHES        = 2,

	/** Write inf and nan number as 'Infinity' and 'NaN' literal (non-standard). */
	YYJSON_WRITE_ALLOW_INF_AND_NAN     = 3,

	/** Write inf and nan number as null literal.
	    This flag will override `YYJSON_WRITE_ALLOW_INF_AND_NAN` flag. */
	YYJSON_WRITE_INF_AND_NAN_AS_NULL   = 4,

	/** Allow invalid unicode when encoding string values (non-standard).
	    Invalid characters in string value will be copied byte by byte.
	    If `YYJSON_WRITE_ESCAPE_UNICODE` flag is also set, invalid character will be
	    escaped as `U+FFFD` (replacement character).
	    This flag does not affect the performance of correctly encoded strings. */
	YYJSON_WRITE_ALLOW_INVALID_UNICODE = 5,

	/** Write JSON pretty with 2 space indent.
	    This flag will override `YYJSON_WRITE_PRETTY` flag. */
	YYJSON_WRITE_PRETTY_TWO_SPACES     = 6,

	/** Adds a newline character `\n` at the end of the JSON.
	    This can be helpful for text editors or NDJSON. */
	YYJSON_WRITE_NEWLINE_AT_END        = 7,
}

write_flag :: bit_set[Write_Flags;c.uint32_t]

// Result code for JSON writer
write_code :: enum c.uint32_t {
	// Success, no error.
	YYJSON_WRITE_SUCCESS                  = 0,

	/** Invalid parameter, such as NULL document. */
	YYJSON_WRITE_ERROR_INVALID_PARAMETER  = 1,

	/** Memory allocation failure occurs. */
	YYJSON_WRITE_ERROR_MEMORY_ALLOCATION  = 2,

	/** Invalid value type in JSON document. */
	YYJSON_WRITE_ERROR_INVALID_VALUE_TYPE = 3,

	/** NaN or Infinity number occurs. */
	YYJSON_WRITE_ERROR_NAN_OR_INF         = 4,

	/** Failed to open a file. */
	YYJSON_WRITE_ERROR_FILE_OPEN          = 5,

	/** Failed to write a file. */
	YYJSON_WRITE_ERROR_FILE_WRITE         = 6,

	/** Invalid unicode in string. */
	YYJSON_WRITE_ERROR_INVALID_STRING     = 7,
}

write_err :: struct {
	code: write_code,
	/** Error message, constant, no need to free (NULL if success). */
	msg:  cstring,
}

// Type of a JSON value (3 bit)
type :: enum c.uint8_t {
	/** No type, invalid. */
	YYJSON_TYPE_NONE = 0, /* _____000 */
	/** Raw string type, no subtype. */
	YYJSON_TYPE_RAW  = 1, /* _____001 */
	/** Null type: `null` literal, no subtype. */
	YYJSON_TYPE_NULL = 2, /* _____010 */
	/** Boolean type, subtype: TRUE, FALSE. */
	YYJSON_TYPE_BOOL = 3, /* _____011 */
	/** Number type, subtype: UINT, SINT, REAL. */
	YYJSON_TYPE_NUM  = 4, /* _____100 */
	/** String type, subtype: NONE, NOESC. */
	YYJSON_TYPE_STR  = 5, /* _____101 */
	/** Array type, no subtype. */
	YYJSON_TYPE_ARR  = 6, /* _____110 */
	/** Object type, no subtype. */
	YYJSON_TYPE_OBJ  = 7, /* _____111 */
}

// Subtype of a JSON value (2 bit)
subtype :: enum c.uint8_t {
	/** No subtype. */
	YYJSON_SUBTYPE_NONE  = 0 << 3, /* ___00___ */
	/** False subtype: `false` literal. */
	YYJSON_SUBTYPE_FALSE = 0 << 3, /* ___00___ */
	/** True subtype: `true` literal. */
	YYJSON_SUBTYPE_TRUE  = 1 << 3, /* ___01___ */
	/** Unsigned integer subtype: `uint64_t`. */
	YYJSON_SUBTYPE_UINT  = 0 << 3, /* ___00___ */
	/** Signed integer subtype: `int64_t`. */
	YYJSON_SUBTYPE_SINT  = 1 << 3, /* ___01___ */
	/** Real number subtype: `double`. */
	YYJSON_SUBTYPE_REAL  = 2 << 3, /* ___10___ */
	/** String that do not need to be escaped for writing (internal use). */
	YYJSON_SUBTYPE_NOESC = 1 << 3, /* ___01___ */
}


@(default_calling_convention = "c", link_prefix = "yyjson_")
foreign yyjson {

	// The version of yyjson in hex, same as `YYJSON_VERSION_HEX`.
	version :: proc() -> c.uint ---


	/* doc ----------------------------- */

	doc_free :: #force_inline proc(doc: ^doc) ---
	doc_get_read_size :: #force_inline proc(doc: ^doc) -> c.size_t ---
	doc_get_root :: #force_inline proc(doc: ^doc) -> ^val ---
	doc_get_val_count :: #force_inline proc(doc: ^doc) -> c.size_t ---
	doc_mut_copy :: proc(doc: ^doc, alc: ^alc = nil) -> ^mut_doc ---
	doc_ptr_get :: #force_inline proc(doc: ^doc, ptr: cstring) -> ^val ---
	doc_ptr_getn :: #force_inline proc(doc: ^doc, ptr: cstring, len: c.size_t) -> ^val ---
	doc_ptr_getx :: #force_inline proc(doc: ^doc, ptr: cstring, len: c.size_t, err: ^ptr_err = nil) -> ^val ---

	mut_doc_ptr_add :: #force_inline proc(doc: ^mut_doc, ptr: cstring, new_val: ^mut_val) -> bool ---
	mut_doc_ptr_addn :: #force_inline proc(doc: ^mut_doc, ptr: cstring, len: c.size_t, new_val: ^mut_val) -> bool ---
	mut_doc_ptr_addx :: #force_inline proc(doc: ^mut_doc, ptr: cstring, len: c.size_t, new_val: ^mut_val, create_parent: bool, ctx: ^ptr_ctx = nil, err: ^ptr_err = nil) -> bool ---
	mut_doc_ptr_get :: #force_inline proc(doc: ^mut_doc, ptr: cstring) -> ^mut_val ---
	mut_doc_ptr_getn :: #force_inline proc(doc: ^mut_doc, ptr: cstring, len: c.size_t) -> ^mut_val ---
	mut_doc_ptr_getx :: #force_inline proc(doc: ^mut_doc, ptr: cstring, len: c.size_t, ctx: ^ptr_ctx = nil, err: ^ptr_err = nil) -> ^mut_val ---

	mut_doc_ptr_remove :: #force_inline proc(doc: ^mut_doc, ptr: cstring) -> ^mut_val ---
	mut_doc_ptr_removen :: #force_inline proc(doc: ^mut_doc, ptr: cstring, len: c.size_t) -> ^mut_val ---
	mut_doc_ptr_removex :: #force_inline proc(doc: ^mut_doc, ptr: cstring, len: c.size_t, ctx: ^ptr_ctx = nil, err: ^ptr_err = nil) -> ^mut_val ---
	mut_doc_ptr_replace :: #force_inline proc(doc: ^mut_doc, ptr: cstring, new_val: ^mut_val) -> ^mut_val ---
	mut_doc_ptr_replacen :: #force_inline proc(doc: ^mut_doc, ptr: cstring, len: c.size_t, new_val: ^mut_val) -> ^mut_val ---
	mut_doc_ptr_replacex :: #force_inline proc(doc: ^mut_doc, ptr: cstring, len: c.size_t, new_val: ^mut_val, ctx: ^ptr_ctx = nil, err: ^ptr_err = nil) -> ^mut_val ---

	mut_doc_ptr_set :: #force_inline proc(doc: ^mut_doc, ptr: cstring, new_val: ^mut_val) -> bool ---
	mut_doc_ptr_setn :: #force_inline proc(doc: ^mut_doc, ptr: cstring, len: c.size_t, new_val: ^mut_val) -> bool ---
	mut_doc_ptr_setx :: #force_inline proc(doc: ^mut_doc, ptr: cstring, len: c.size_t, new_val: ^mut_val, create_parent: bool, ctx: ^ptr_ctx = nil, err: ^ptr_err = nil) -> bool ---


	/* alc ----------------------------- */

	alc_dyn_new :: proc() -> ^alc ---
	alc_dyn_free :: proc(alc: ^alc) ---
	alc_pool_init :: proc(alc: ^alc, buf: rawptr, size: c.size_t) -> bool ---

	/* arr ----------------------------- */

	// Returns the number of elements in this array. Returns 0 if `arr` is NULL or type is not array.
	arr_size :: #force_inline proc(arr: ^val) -> c.size_t ---

	// Returns the element at the specified position in this array. Returns NULL if array is NULL/empty or the index is out of bounds.
	arr_get :: #force_inline proc(arr: ^val, idx: c.size_t) -> ^val ---

	// Returns the first element of this array. Returns NULL if `arr` is NULL/empty or type is not array.
	arr_get_first :: #force_inline proc(arr: ^val) -> ^val ---

	// Returns the last element of this array. Returns NULL if `arr` is NULL/empty or type is not array.
	arr_get_last :: #force_inline proc(arr: val) -> ^val ---

	/**
	 Initialize an iterator for this array.

	 @param arr The array to be iterated over.
	    If this parameter is NULL or not an array, `iter` will be set to empty.
	 @param iter The iterator to be initialized.
	    If this parameter is NULL, the function will fail and return false.
	 @return true if the `iter` has been successfully initialized.

	 @note The iterator does not need to be destroyed.
	 */
	arr_iter_init :: #force_inline proc(arr: ^val, iter: ^arr_iter) -> bool ---

	/**
	 Create an iterator with an array , same as `yyjson_arr_iter_init()`.

	 @param arr The array to be iterated over.
	    If this parameter is NULL or not an array, an empty iterator will returned.
	 @return A new iterator for the array.

	 @note The iterator does not need to be destroyed.
	 */
	arr_iter_with :: #force_inline proc(arr: ^val) -> arr_iter ---

	/**
	 Returns whether the iteration has more elements.
	 If `iter` is NULL, this function will return false.
	 */
	arr_iter_has_next :: #force_inline proc(iter: ^arr_iter) -> bool ---

	/**
	 Returns the next element in the iteration, or NULL on end.
	 If `iter` is NULL, this function will return NULL.
	 */
	arr_iter_next :: #force_inline proc(iter: ^arr_iter) -> ^val ---


	/* Text Locating ----------------------------- */

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
	 Creates and returns a merge-patched JSON value (RFC 7386).
	 The memory of the returned value is allocated by the `doc`.
	 Returns NULL if the patch could not be applied.

	 @warning This function is recursive and may cause a stack overflow if the
	    object level is too deep.
	 */
	merge_patch :: proc(doc: ^mut_doc, orig: ^val, patch: ^val) -> ^mut_val ---

	/**
	 Creates and returns a merge-patched JSON value (RFC 7386).
	 The memory of the returned value is allocated by the `doc`.
	 Returns NULL if the patch could not be applied.

	 @warning This function is recursive and may cause a stack overflow if the
	    object level is too deep.
	 */
	mut_merge_patch :: proc(doc: ^mut_doc, orig: ^mut_val, patch: ^mut_val) -> ^mut_val ---

	patch :: proc(doc: ^mut_doc, orig: ^val, patch: ^val, err: ^patch_err = nil) -> ^mut_val ---

	ptr_ctx_append :: #force_inline proc(ctx: ^ptr_ctx, key: ^mut_val, val: ^mut_val) -> bool ---
	ptr_ctx_remove :: #force_inline proc(ctx: ^ptr_ctx) -> bool ---
	ptr_ctx_replace :: #force_inline proc(ctx: ^ptr_ctx, val: ^mut_val) -> bool ---
	ptr_get :: #force_inline proc(v: ^val, ptr: cstring) -> ^val ---

	ptr_get_bool :: #force_inline proc(root: ^val, ptr: cstring, value: ^bool) -> bool ---
	ptr_get_num :: #force_inline proc(root: ^val, ptr: cstring, value: ^c.double) -> bool ---

	ptr_get_real :: #force_inline proc(root: ^val, ptr: cstring, value: ^c.double) -> bool ---
	ptr_get_sint :: #force_inline proc(root: ^val, ptr: cstring, value: ^c.int64_t) -> bool ---

	ptr_get_str :: #force_inline proc(root: ^val, ptr: cstring, value: ^cstring) -> bool ---
	ptr_get_uint :: #force_inline proc(root: ^val, ptr: cstring, value: ^c.uint64_t) -> bool ---
	ptr_getn :: #force_inline proc(root: ^val, ptr: cstring) -> ^val ---
	ptr_getx :: #force_inline proc(root: ^val, ptr: cstring, len: c.size_t) -> ^val ---


	/* set ----------------------------- */

	// Set the value to raw. Returns false if input is NULL or `val` is object or array.
	set_raw :: #force_inline proc(val: ^val, raw: cstring, len: c.size_t) -> bool ---

	// Set the value to null. Returns false if input is NULL or `val` is object or array.
	set_null :: #force_inline proc(val: ^val) -> bool ---

	// Set the value to bool. Returns false if input is NULL or `val` is object or array.
	set_bool :: #force_inline proc(val: ^val, num: c.bool) -> bool ---

	// Set the value to uint. Returns false if input is NULL or `val` is object or array.
	set_uint :: #force_inline proc(val: ^val, num: c.uint64_t) -> bool ---

	// Set the value to sint. Returns false if input is NULL or `val` is object or array.
	set_sint :: #force_inline proc(val: ^val, num: c.int64_t) -> bool ---

	// Set the value to int. Returns false if input is NULL or `val` is object or array.
	set_int :: #force_inline proc(val: ^val, num: c.int) -> bool ---

	// Set the value to real. Returns false if input is NULL or `val` is object or array.
	set_real :: #force_inline proc(val: ^val, num: c.double) -> bool ---

	// Set the value to string (null-terminated). Returns false if input is NULL or `val` is object or array.
	set_str :: #force_inline proc(val: ^val, str: cstring) -> bool ---

	// Set the value to string (with length). Returns false if input is NULL or `val` is object or array.
	set_strn :: #force_inline proc(val: ^val, str: cstring, len: c.size_t) -> bool ---


	mut_set_arr :: #force_inline proc(val: ^mut_val) -> bool ---
	mut_set_bool :: #force_inline proc(val: ^mut_val, v: bool) -> bool ---
	mut_set_int :: #force_inline proc(val: ^mut_val, num: c.int) -> bool ---
	mut_set_null :: #force_inline proc(val: ^mut_val) -> bool ---
	mut_set_obj :: #force_inline proc(val: ^mut_val) -> bool ---
	mut_set_raw :: #force_inline proc(val: ^mut_val, raw: cstring, len: c.size_t) -> bool ---
	mut_set_real :: #force_inline proc(val: ^mut_val, num: c.double) -> bool ---
	mut_set_sint :: #force_inline proc(val: ^mut_val, num: c.int64_t) -> bool ---
	mut_set_str :: #force_inline proc(val: ^mut_val, str: cstring) -> bool ---
	mut_set_strn :: #force_inline proc(val: ^mut_val, str: cstring, len: c.size_t) -> bool ---
	mut_set_uint :: #force_inline proc(val: ^mut_val, num: c.uint64_t) -> bool ---


	/* get ----------------------------- */

	// Returns the JSON value's type. Returns YYJSON_TYPE_NONE if `val` is NULL.
	get_type :: #force_inline proc(val: ^val) -> type ---

	// Returns the JSON value's subtype. Returns YYJSON_SUBTYPE_NONE if `val` is NULL.
	get_subtype :: #force_inline proc(val: ^val) -> subtype ---

	// Returns the JSON value's tag. Returns 0 if `val` is NULL.
	get_tag :: #force_inline proc(val: ^val) -> c.uint8_t ---

	// Returns the JSON value's type description. The return value should be one of these strings: "raw", "null", "string", "array", "object", "true", "false", "uint", "sint", "real", "unknown".
	get_type_desc :: #force_inline proc(val: ^val) -> cstring ---

	// Returns the content if the value is raw. Returns NULL if `val` is NULL or type is not raw.
	get_raw :: #force_inline proc(val: ^val) -> cstring ---

	// Returns the content if the value is bool. Returns NULL if `val` is NULL or type is not bool.
	get_bool :: #force_inline proc(val: ^val) -> bool ---

	// Returns the content and cast to uint64_t. Returns 0 if `val` is NULL or type is not integer(sint/uint).
	get_uint :: #force_inline proc(val: ^val) -> c.uint64_t ---

	// Returns the content and cast to int64_t. Returns 0 if `val` is NULL or type is not integer(sint/uint).
	get_sint :: #force_inline proc(val: ^val) -> c.int64_t ---

	// Returns the content and cast to int. Returns 0 if `val` is NULL or type is not integer(sint/uint).
	get_int :: #force_inline proc(val: ^val) -> c.int ---

	// Returns the content if the value is real number, or 0.0 on error. Returns 0.0 if `val` is NULL or type is not real(double).
	get_real :: #force_inline proc(val: ^val) -> c.double ---

	// Returns the content and typecast to `double` if the value is number. Returns 0.0 if `val` is NULL or type is not number(uint/sint/real).
	get_num :: #force_inline proc(val: ^val) -> c.double ---

	// Returns the content if the value is string. Returns NULL if `val` is NULL or type is not string.
	get_str :: #force_inline proc(val: ^val) -> cstring ---

	// Returns the content length (string length, array size, object size. Returns 0 if `val` is NULL or type is not string/array/object.
	get_len :: #force_inline proc(val: ^val) -> c.size_t ---

	// Returns whether the JSON value is equals to a string. Returns false if input is NULL or type is not string.
	equals_str :: #force_inline proc(val: ^val, str: cstring) -> bool ---

	// Returns whether the JSON value is equals to a string. The `str` should be a UTF-8 string, null-terminator is not required. Returns false if input is NULL or type is not string.
	equals_strn :: #force_inline proc(val: ^val, str: cstring, len: c.size_t) -> bool ---


	/* obj ----------------------------- */

	obj_get :: #force_inline proc(obj: ^val, key: cstring) -> ^val ---
	obj_getn :: #force_inline proc(obj: ^val, key: cstring, key_len: c.size_t) -> ^val ---
	obj_size :: #force_inline proc(obj: ^val) -> c.size_t ---

	obj_iter_init :: #force_inline proc(obj: ^val, iter: ^obj_iter) -> bool ---
	obj_iter_with :: #force_inline proc(obj: ^val) -> obj_iter ---
	obj_iter_has_next :: #force_inline proc(iter: ^obj_iter) -> bool ---
	obj_iter_next :: #force_inline proc(iter: ^obj_iter) -> ^val ---
	obj_iter_get_val :: #force_inline proc(key: ^val) -> ^val ---
	obj_iter_get :: #force_inline proc(iter: ^obj_iter, key: cstring) -> ^val ---
	obj_iter_getn :: #force_inline proc(iter: ^obj_iter, key: cstring, key_len: c.size_t) -> ^val ---

	/* predicates ----------------------------- */

	// Returns whether the JSON value is raw. Returns false if `val` is NULL.
	is_raw :: #force_inline proc(val: ^val) -> bool ---

	// Returns whether the JSON value is `null`. Returns false if `val` is NULL.
	is_null :: #force_inline proc(val: ^val) -> bool ---

	// Returns whether the JSON value is `true`. Returns false if `val` is NULL.
	is_true :: #force_inline proc(val: ^val) -> bool ---

	// Returns whether the JSON value is `false`. Returns false if `val` is NULL.
	is_false :: #force_inline proc(val: ^val) -> bool ---

	// Returns whether the JSON value is bool (true/false). Returns false if `val` is NULL.
	is_bool :: #force_inline proc(val: ^val) -> bool ---

	// Returns whether the JSON value is unsigned integer (uint64_t). Returns false if `val` is NULL.
	is_uint :: #force_inline proc(val: ^val) -> bool ---

	// Returns whether the JSON value is signed integer (int64_t). Returns false if `val` is NULL.
	is_sint :: #force_inline proc(val: ^val) -> bool ---

	// Returns whether the JSON value is integer (uint64_t/int64_t). Returns false if `val` is NULL.
	is_int :: #force_inline proc(val: ^val) -> bool ---

	// Returns whether the JSON value is real number (double). Returns false if `val` is NULL.
	is_real :: #force_inline proc(val: ^val) -> bool ---

	// Returns whether the JSON value is number (uint64_t/int64_t/double). Returns false if `val` is NULL.
	is_num :: #force_inline proc(val: ^val) -> bool ---

	// Returns whether the JSON value is string. Returns false if `val` is NULL.
	is_str :: #force_inline proc(val: ^val) -> bool ---

	// Returns whether the JSON value is array. Returns false if `val` is NULL.
	is_arr :: #force_inline proc(val: ^val) -> bool ---

	// Returns whether the JSON value is object. Returns false if `val` is NULL.
	is_obj :: #force_inline proc(val: ^val) -> bool ---

	// Returns whether the JSON value is container (array/object). Returns false if `val` is NULL.
	is_ctn :: #force_inline proc(val: ^val) -> bool ---


	mut_get_bool :: #force_inline proc(val: ^mut_val) -> bool ---

	mut_get_int :: #force_inline proc(val: ^mut_val) -> c.int ---

	mut_get_len :: #force_inline proc(val: ^mut_val) -> c.size_t ---
	mut_get_num :: #force_inline proc(val: ^mut_val) -> c.double ---
	mut_get_raw :: #force_inline proc(val: ^mut_val) -> cstring ---
	mut_get_real :: #force_inline proc(val: ^mut_val) -> c.double ---
	mut_get_sint :: #force_inline proc(val: ^mut_val) -> c.int64_t ---
	mut_get_str :: #force_inline proc(val: ^mut_val) -> cstring ---
	mut_get_subtype :: #force_inline proc(val: ^mut_val) -> subtype ---
	mut_get_tag :: #force_inline proc(val: ^mut_val) -> c.uint8_t ---
	mut_get_type :: #force_inline proc(val: ^mut_val) -> type ---
	mut_get_type_desc :: #force_inline proc(val: ^mut_val) -> cstring ---
	mut_get_uint :: #force_inline proc(val: ^mut_val) -> c.uint64_t ---

	mut_is_arr :: #force_inline proc(val: ^mut_val) -> bool ---
	mut_is_bool :: #force_inline proc(val: ^mut_val) -> bool ---
	mut_is_ctn :: #force_inline proc(val: ^mut_val) -> bool ---
	mut_is_false :: #force_inline proc(val: ^mut_val) -> bool ---
	mut_is_int :: #force_inline proc(val: ^mut_val) -> bool ---
	mut_is_null :: #force_inline proc(val: ^mut_val) -> bool ---
	mut_is_num :: #force_inline proc(val: ^mut_val) -> bool ---
	mut_is_obj :: #force_inline proc(val: ^mut_val) -> bool ---
	mut_is_raw :: #force_inline proc(val: ^mut_val) -> bool ---
	mut_is_real :: #force_inline proc(val: ^mut_val) -> bool ---
	mut_is_sint :: #force_inline proc(val: ^mut_val) -> bool ---
	mut_is_str :: #force_inline proc(val: ^mut_val) -> bool ---
	mut_is_true :: #force_inline proc(val: ^mut_val) -> bool ---
	mut_is_uint :: #force_inline proc(val: ^mut_val) -> bool ---


	/* mut doc ----------------------------- */

	// Creates and returns a new mutable JSON document, returns NULL on error. If allocator is NULL, the default allocator will be used.
	mut_doc_new :: proc(alc: ^alc = nil) -> ^mut_doc ---

	// Release the JSON document and free the memory. After calling this function, the doc and all values from the doc are no longer available. This function will do nothing if the doc is NULL.
	mut_doc_free :: proc(doc: ^mut_doc) ---

	// Sets the root value of this JSON document. Pass NULL to clear root value of the document.
	mut_doc_set_root :: proc(doc: ^mut_doc, root: ^mut_val) ---

	// Returns the root value of this JSON document. Returns NULL if doc is NULL.
	mut_doc_get_root :: #force_inline proc(doc: ^mut_doc) -> ^mut_val ---

	// Copies and returns a new immutable document from input, returns NULL on error. This makes a deep-copy on the mutable document. The returned document should be freed with yyjson_doc_free().
	mut_doc_imut_copy :: proc(doc_: ^mut_doc, alc: ^alc = nil) -> ^doc ---

	// Copies and returns a new mutable document from input, returns NULL on error. This makes a deep-copy on the mutable document. If allocator is NULL, the default allocator will be used.
	mut_doc_mut_copy :: proc(doc: ^mut_doc, alc: ^alc = nil) -> ^mut_doc ---

	val_mut_copy :: proc(doc: ^mut_doc, val: ^val) -> ^mut_val ---

	mut_val_mut_copy :: proc(doc: ^mut_doc, val: ^mut_val) -> ^mut_val ---

	mut_doc_set_str_pool_size :: proc(doc: ^mut_doc, len: c.size_t) -> bool ---
	mut_doc_set_val_pool_size :: proc(doc: ^mut_doc, count: c.size_t) -> bool ---

	/* mut arr ----------------------------- */

	// Creates and returns an empty mutable array. Returns the new array or NULL if input is NULL or memory allocation failed.
	mut_arr :: #force_inline proc(doc: ^mut_doc) -> ^mut_val ---

	// Creates and adds a new array at the end of the array. Returns the new array, or NULL on error.
	mut_arr_add_arr :: #force_inline proc(doc: ^mut_doc, array: ^mut_val, key: cstring) -> ^mut_val ---

	// Adds a bool value at the end of the array. Returns whether successful
	mut_arr_add_bool :: #force_inline proc(doc: ^mut_doc, array: ^mut_val, key: cstring, val: bool) -> bool ---

	// Creates and adds a new object at the end of the array. Returns the new object, or NULL on error.
	mut_arr_add_obj :: #force_inline proc(doc: ^mut_doc, array: ^mut_val) -> ^mut_val ---

	mut_arr_add_false :: #force_inline proc(doc: ^mut_doc, array: ^mut_val) -> bool ---
	mut_arr_add_int :: #force_inline proc(doc: ^mut_doc, array: ^mut_val, num: c.int64_t) -> bool ---
	mut_arr_add_null :: #force_inline proc(doc: ^mut_doc, array: ^mut_val) -> bool ---
	mut_arr_add_real :: #force_inline proc(doc: ^mut_doc, array: ^mut_val, num: c.double) -> bool ---
	mut_arr_add_sint :: #force_inline proc(doc: ^mut_doc, array: ^mut_val, num: c.int64_t) -> bool ---
	mut_arr_add_str :: #force_inline proc(doc: ^mut_doc, array: ^mut_val, str: cstring) -> bool ---
	mut_arr_add_strcpy :: #force_inline proc(doc: ^mut_doc, array: ^mut_val, str: cstring) -> bool ---
	mut_arr_add_strn :: #force_inline proc(doc: ^mut_doc, array: ^mut_val, str: cstring, len: c.size_t) -> bool ---
	mut_arr_add_strncpy :: #force_inline proc(doc: ^mut_doc, array: ^mut_val, str: cstring, len: c.size_t) -> bool ---
	mut_arr_add_true :: #force_inline proc(doc: ^mut_doc, array: ^mut_val) -> bool ---
	mut_arr_add_uint :: #force_inline proc(doc: ^mut_doc, array: ^mut_val, num: c.uint64_t) -> bool ---
	mut_arr_add_val :: #force_inline proc(array: ^mut_val, val: ^^mut_val) -> bool ---
	mut_arr_append :: #force_inline proc(array: ^mut_val, val: ^mut_val) -> bool ---
	mut_arr_clear :: #force_inline proc(array: ^mut_val) -> bool ---
	mut_arr_get :: #force_inline proc(array: ^mut_val, idx: c.size_t) -> ^mut_val ---
	mut_arr_get_first :: #force_inline proc(array: ^mut_val) -> ^mut_val ---
	mut_arr_get_last :: #force_inline proc(array: ^mut_val) -> ^mut_val ---
	mut_arr_insert :: #force_inline proc(array: ^mut_val, val: ^mut_val, idx: c.size_t) -> bool ---
	mut_arr_iter_has_next :: #force_inline proc(iter: ^mut_arr_iter) -> bool ---
	mut_arr_iter_init :: #force_inline proc(array: ^mut_val, iter: ^mut_arr_iter) -> bool ---
	mut_arr_iter_next :: #force_inline proc(iter: ^mut_arr_iter) -> ^mut_val ---
	mut_arr_iter_remove :: #force_inline proc(iter: ^mut_arr_iter) -> ^mut_val ---
	mut_arr_iter_with :: #force_inline proc(array: ^mut_val) -> mut_arr_iter ---
	mut_arr_prepend :: #force_inline proc(array: ^mut_val, val: ^mut_val) -> bool ---
	mut_arr_remove :: #force_inline proc(array: ^mut_val, idx: c.size_t) -> ^mut_val ---
	mut_arr_remove_first :: #force_inline proc(array: ^mut_val) -> ^mut_val ---
	mut_arr_remove_last :: #force_inline proc(array: ^mut_val) -> ^mut_val ---
	mut_arr_remove_range :: #force_inline proc(array: ^mut_val, idx: c.size_t, len: c.size_t) -> bool ---
	mut_arr_replace :: #force_inline proc(array: ^mut_val, idx: c.size_t, val: ^mut_val) -> ^mut_val ---
	mut_arr_rotate :: #force_inline proc(array: ^mut_val, idx: c.size_t) -> bool ---
	mut_arr_size :: #force_inline proc(array: ^mut_val) -> c.size_t ---
	mut_arr_with_bool :: #force_inline proc(doc: ^mut_doc, vals: [^]bool, count: c.size_t) -> ^mut_val ---
	mut_arr_with_double :: #force_inline proc(doc: ^mut_doc, vals: [^]c.double, count: c.size_t) -> ^mut_val ---
	mut_arr_with_float :: #force_inline proc(doc: ^mut_doc, vals: [^]c.float, count: c.size_t) -> ^mut_val ---
	mut_arr_with_real :: #force_inline proc(doc: ^mut_doc, vals: [^]c.double, count: c.size_t) -> ^mut_val ---
	mut_arr_with_sint :: #force_inline proc(doc: ^mut_doc, vals: [^]c.int64_t, count: c.size_t) -> ^mut_val ---
	mut_arr_with_sint16 :: #force_inline proc(doc: ^mut_doc, vals: [^]c.int16_t, count: c.size_t) -> ^mut_val ---
	mut_arr_with_sint32 :: #force_inline proc(doc: ^mut_doc, vals: [^]c.int32_t, count: c.size_t) -> ^mut_val ---
	mut_arr_with_sint64 :: #force_inline proc(doc: ^mut_doc, vals: [^]c.int64_t, count: c.size_t) -> ^mut_val ---
	mut_arr_with_sint8 :: #force_inline proc(doc: ^mut_doc, vals: [^]c.int8_t, count: c.size_t) -> ^mut_val ---
	mut_arr_with_str :: #force_inline proc(doc: ^mut_doc, vals: [^]cstring, count: c.size_t) -> ^mut_val ---
	mut_arr_with_strcpy :: #force_inline proc(doc: ^mut_doc, vals: [^]cstring, count: c.size_t) -> ^mut_val ---
	mut_arr_with_strn :: #force_inline proc(doc: ^mut_doc, vals: [^]cstring, lens: [^]c.size_t, count: c.size_t) -> ^mut_val ---
	mut_arr_with_strncpy :: #force_inline proc(doc: ^mut_doc, vals: [^]cstring, lens: [^]c.size_t, count: c.size_t) -> ^mut_val ---

	mut_arr_with_uint :: #force_inline proc(doc: ^mut_doc, vals: [^]c.uint64_t, count: c.size_t) -> ^mut_val ---
	mut_arr_with_uint16 :: #force_inline proc(doc: ^mut_doc, vals: [^]c.uint16_t, count: c.size_t) -> ^mut_val ---
	mut_arr_with_uint32 :: #force_inline proc(doc: ^mut_doc, vals: [^]c.uint32_t, count: c.size_t) -> ^mut_val ---
	mut_arr_with_uint64 :: #force_inline proc(doc: ^mut_doc, vals: [^]c.uint64_t, count: c.size_t) -> ^mut_val ---
	mut_arr_with_uint8 :: #force_inline proc(doc: ^mut_doc, vals: [^]c.uint8_t, count: c.size_t) -> ^mut_val ---


	/* mut obj ----------------------------- */

	// Creates and returns a mutable object, returns NULL on error.
	mut_obj :: #force_inline proc(doc: ^mut_doc) -> ^mut_val ---

	// Adds a key-value pair at the end of the object. This function allows duplicated key in one object. Returns whether successful.
	// The key should be a string which is created by yyjson_mut_str(), yyjson_mut_strn(), yyjson_mut_strcpy() or yyjson_mut_strncpy().
	mut_obj_add :: #force_inline proc(obj: ^mut_val, key: ^mut_val, val: ^mut_val) -> bool ---

	// Creates and adds a new array to the target object. The key should be a null-terminated UTF-8 string. This function allows duplicated key in one object.
	mut_obj_add_arr :: #force_inline proc(doc: ^mut_doc, obj: ^mut_val, key: cstring) -> ^mut_val ---

	// Adds a bool value at the end of the object. The key should be a null-terminated UTF-8 string. This function allows duplicated key in one object.
	mut_obj_add_bool :: #force_inline proc(doc: ^mut_doc, obj: ^mut_val, key: cstring, val: bool) -> bool ---

	// Adds a false value at the end of the object. The key should be a null-terminated UTF-8 string. This function allows duplicated key in one object.
	mut_obj_add_false :: #force_inline proc(doc: ^mut_doc, array: ^mut_val, key: cstring) -> bool ---

	// Adds an int value at the end of the object. The key should be a null-terminated UTF-8 string. This function allows duplicated key in one object.
	mut_obj_add_int :: #force_inline proc(doc: ^mut_doc, obj: ^mut_val, key: cstring, val: c.int64_t) -> bool ---

	// Adds a null value at the end of the object. The key should be a null-terminated UTF-8 string. This function allows duplicated key in one object.
	mut_obj_add_null :: #force_inline proc(doc: ^mut_doc, obj: ^mut_val, key: cstring) -> bool ---

	// Creates and adds a new object to the target object. The key should be a null-terminated UTF-8 string. This function allows duplicated key in one object.
	mut_obj_add_obj :: #force_inline proc(doc: ^mut_doc, obj: ^mut_val, key: cstring) -> ^mut_val ---

	// Adds a double value at the end of the object. The key should be a null-terminated UTF-8 string. This function allows duplicated key in one object.
	mut_obj_add_real :: #force_inline proc(doc: ^mut_doc, obj: ^mut_val, key: cstring, val: c.double) -> bool ---

	// Adds a signed integer value at the end of the object. The key should be a null-terminated UTF-8 string. This function allows duplicated key in one object.
	mut_obj_add_sint :: #force_inline proc(doc: ^mut_doc, obj: ^mut_val, key: cstring, val: c.int64_t) -> bool ---

	// Adds a string value at the end of the object. The key and val should be null-terminated UTF-8 strings. This function allows duplicated key in one object.
	// The key/value strings are not copied, you should keep these strings unmodified for the lifetime of this JSON document.
	mut_obj_add_str :: #force_inline proc(doc: ^mut_doc, obj: ^mut_val, key: cstring, val: cstring) -> bool ---

	// Adds a string value at the end of the object. The key and val should be null-terminated UTF-8 strings. The value string is copied. This function allows duplicated key in one object.
	mut_obj_add_strcpy :: #force_inline proc(doc: ^mut_doc, obj: ^mut_val, key: cstring, val: cstring) -> bool ---

	// Adds a string value at the end of the object. The key should be a null-terminated UTF-8 string. The val should be a UTF-8 string, null-terminator is not required. The len should be the length of the val, in bytes. This function allows duplicated key in one object.
	mut_obj_add_strn :: #force_inline proc(doc: ^mut_doc, obj: ^mut_val, key: cstring, val: cstring, len: c.size_t) -> bool ---

	// Adds a string value at the end of the object. The key should be a null-terminated UTF-8 string. The val should be a UTF-8 string, null-terminator is not required. The len should be the length of the val, in bytes. This function allows duplicated key in one object.
	mut_obj_add_strncpy :: #force_inline proc(doc: ^mut_doc, obj: ^mut_val, key: cstring, val: cstring, len: c.size_t) -> bool ---

	// Adds a true value at the end of the object. The key should be a null-terminated UTF-8 string. This function allows duplicated key in one object.
	mut_obj_add_true :: #force_inline proc(doc: ^mut_doc, obj: ^mut_val, key: cstring) -> bool ---

	// Adds an unsigned integer value at the end of the object. The key should be a null-terminated UTF-8 string. This function allows duplicated key in one object.
	mut_obj_add_uint :: #force_inline proc(doc: ^mut_doc, obj: ^mut_val, key: cstring, val: c.uint64_t) -> bool ---

	// Adds a JSON value at the end of the object. The key should be a null-terminated UTF-8 string. This function allows duplicated key in one object.
	mut_obj_add_val :: #force_inline proc(doc: ^mut_doc, obj: ^mut_val, key: cstring, val: ^mut_val) -> bool ---

	// Removes all key-value pairs in this object.
	mut_obj_clear :: #force_inline proc(obj: ^mut_val) -> bool ---

	// Returns the value to which the specified key is mapped. Returns NULL if this object contains no mapping for the key. Returns NULL if obj/key is NULL, or type is not object.
	mut_obj_get :: #force_inline proc(obj: ^mut_val, key: cstring) -> ^mut_val ---

	// Returns the value to which the specified key is mapped. Returns NULL if this object contains no mapping for the key. Returns NULL if obj/key is NULL, or type is not object.
	// The key should be a UTF-8 string, null-terminator is not required. The key_len should be the length of the key, in bytes.
	mut_obj_getn :: #force_inline proc(obj: ^mut_val, key: cstring, key_len: c.size_t) -> ^mut_val ---

	// Inserts a key-value pair to the object at the given position. This function allows duplicated key in one object.
	mut_obj_insert :: #force_inline proc(obj: ^mut_val, key: ^mut_val, val: ^mut_val, idx: c.size_t) -> bool ---

	// Iterates to a specified key and returns the value.
	mut_obj_iter_get :: #force_inline proc(iter: ^mut_obj_iter, key: cstring) -> ^mut_val ---

	// Returns the value for key inside the iteration. If iter is NULL, this function will return NULL.
	mut_obj_iter_get_val :: #force_inline proc(key: ^mut_val) -> ^mut_val ---

	// Iterates to a specified key and returns the value.
	// This function does the same thing as yyjson_mut_obj_getn() but is much faster if the ordering of the keys is known at compile-time and you are using the same order to look up the values. If the key exists in this object, then the iterator will stop at the next key, otherwise the iterator will not change and NULL is returned.
	mut_obj_iter_getn :: #force_inline proc(iter: ^mut_obj_iter, key: cstring, key_len: c.size_t) -> ^mut_val ---

	// Returns whether the iteration has more elements. If iter is NULL, this function will return false.
	mut_obj_iter_has_next :: #force_inline proc(iter: ^mut_obj_iter) -> bool ---

	// Initialize an iterator for this object.
	mut_obj_iter_init :: #force_inline proc(obj: ^mut_val, iter: ^mut_obj_iter) -> bool ---

	// Returns the next key in the iteration, or NULL on end. If iter is NULL, this function will return NULL.
	mut_obj_iter_next :: #force_inline proc(iter: ^mut_obj_iter) -> ^mut_val ---

	// Removes current key-value pair in the iteration, returns the removed value. If iter is NULL, this function will return NULL.
	mut_obj_iter_remove :: #force_inline proc(iter: ^mut_obj_iter) -> ^mut_val ---

	// Create an iterator with an object, same as yyjson_obj_iter_init().
	mut_obj_iter_with :: #force_inline proc(obj: ^mut_val) -> mut_obj_iter ---

	// Sets a key-value pair at the end of the object. This function may remove all key-value pairs for the given key before add.
	mut_obj_put :: #force_inline proc(obj: ^mut_val, key: ^mut_val, val: ^mut_val) -> bool ---

	// Removes all key-value pair from the object with given key.
	mut_obj_remove :: #force_inline proc(obj: ^mut_val, key: ^mut_val) -> ^mut_val ---

	// Removes all key-value pair from the object with given key.
	mut_obj_remove_key :: #force_inline proc(obj: ^mut_val, key: cstring) -> ^mut_val ---

	// Removes all key-value pair from the object with given key.
	mut_obj_remove_keyn :: #force_inline proc(obj: ^mut_val, key: cstring, key_len: c.size_t) -> ^mut_val ---

	// Removes all key-value pairs for the given key. Returns the first value to which the specified key is mapped or NULL if this object contains no mapping for the key. The key should be a null-terminated UTF-8 string.
	mut_obj_remove_str :: #force_inline proc(obj: ^mut_val, key: cstring) -> ^mut_val ---

	// Removes all key-value pairs for the given key. Returns the first value to which the specified key is mapped or NULL if this object contains no mapping for the key. The key should be a UTF-8 string, null-terminator is not required. The len should be the length of the key, in bytes.
	mut_obj_remove_strn :: #force_inline proc(obj: ^mut_val, key: cstring, len: c.size_t) -> ^mut_val ---

	// Replaces all matching keys with the new key. Returns true if at least one key was renamed. The key and new_key should be a null-terminated UTF-8 string. The new_key is copied and held by doc.
	mut_obj_rename_key :: #force_inline proc(doc: ^mut_doc, obj: ^mut_val, key: cstring, new_key: cstring) -> bool ---

	// Replaces all matching keys with the new key. Returns true if at least one key was renamed. The key and new_key should be a UTF-8 string, null-terminator is not required. The new_key is copied and held by doc.
	mut_obj_rename_keyn :: #force_inline proc(doc: ^mut_doc, obj: ^mut_val, key: cstring, len: c.size_t, new_key: cstring, new_len: c.size_t) -> bool ---

	// Replaces value from the object with given key. If the key is not exist, or the value is NULL, it will fail.
	mut_obj_replace :: #force_inline proc(obj: ^mut_val, key: ^mut_val, val: ^mut_val) -> bool ---

	// Rotates key-value pairs in the object for the given number of times. For example: {"a":1,"b":2,"c":3,"d":4} rotate 1 is {"b":2,"c":3,"d":4,"a":1}.
	mut_obj_rotate :: #force_inline proc(obj: ^mut_val, idx: c.size_t) -> bool ---

	// Returns the number of key-value pairs in this object. Returns 0 if obj is NULL or type is not object.
	mut_obj_size :: #force_inline proc(obj: ^mut_val) -> c.size_t ---

	// Creates and returns a mutable object with key-value pairs and pair count, returns NULL on error. The keys and values are not copied. The strings should be a null-terminated UTF-8 string.
	mut_obj_with_kv :: #force_inline proc(doc: ^mut_doc, kv_pairs: [^]cstring, pair_count: c.size_t) -> ^mut_val ---

	// Creates and returns a mutable object with keys and values, returns NULL on error. The keys and values are not copied. The strings should be a null-terminated UTF-8 string.
	mut_obj_with_str :: #force_inline proc(doc: ^mut_doc, keys: [^]cstring, vals: [^]cstring, count: c.size_t) -> ^mut_val ---


	/* mut ptr ----------------------------- */

	mut_ptr_add :: #force_inline proc(val: ^mut_val, ptr: cstring, new_val: ^mut_val, doc: ^mut_doc) -> bool ---
	mut_ptr_addn :: #force_inline proc(val: ^mut_val, ptr: cstring, len: c.size_t, new_val: ^mut_val, doc: ^mut_doc) -> bool ---
	mut_ptr_addx :: #force_inline proc(val: ^mut_val, ptr: cstring, len: c.size_t, new_val: ^mut_val, doc: ^mut_doc, create_parent: bool, ctx: ^ptr_ctx = nil, err: ^ptr_err = nil) -> bool ---
	mut_ptr_get :: #force_inline proc(val: ^mut_val, ptr: cstring) -> ^mut_val ---
	mut_ptr_getn :: #force_inline proc(val: ^mut_val, ptr: cstring, len: c.size_t) -> ^mut_val ---
	mut_ptr_getx :: #force_inline proc(val: ^mut_val, ptr: cstring, len: c.size_t, ctx: ^ptr_ctx = nil, err: ^ptr_err = nil) -> ^mut_val ---
	mut_ptr_remove :: #force_inline proc(val: ^mut_val, ptr: cstring) -> ^mut_val ---
	mut_ptr_removen :: #force_inline proc(val: ^mut_val, ptr: cstring, len: c.size_t) -> ^mut_val ---
	mut_ptr_removex :: #force_inline proc(val: ^mut_val, ptr: cstring, len: c.size_t, ctx: ^ptr_ctx = nil, err: ^ptr_err = nil) -> ^mut_val ---
	mut_ptr_replace :: #force_inline proc(val: ^mut_val, ptr: cstring, new_val: ^mut_val) -> ^mut_val ---
	mut_ptr_replacen :: #force_inline proc(val: ^mut_val, ptr: cstring, len: c.size_t, new_val: ^mut_val) -> ^mut_val ---
	mut_ptr_replacex :: #force_inline proc(val: ^mut_val, ptr: cstring, len: c.size_t, new_val: ^mut_val, ctx: ^ptr_ctx = nil, err: ^ptr_err = nil) -> ^mut_val ---
	mut_ptr_set :: #force_inline proc(val: ^mut_val, ptr: cstring, new_val: ^mut_val, doc: ^mut_doc) -> bool ---
	mut_ptr_setn :: #force_inline proc(val: ^mut_val, ptr: cstring, len: c.size_t, new_val: ^mut_val, doc: ^mut_doc) -> bool ---
	mut_ptr_setx :: #force_inline proc(val: ^mut_val, ptr: cstring, len: c.size_t, new_val: ^mut_val, doc: ^mut_doc, create_parent: bool, ctx: ^ptr_ctx = nil, err: ^ptr_err = nil) -> bool ---


	/* mut val ----------------------------- */


	/** Creates and returns a raw value, returns NULL on error.
    The `str` should be a null-terminated UTF-8 string.

    @warning The input string is not copied, you should keep this string
        unmodified for the lifetime of this JSON document. */
	mut_raw :: #force_inline proc(doc: ^mut_doc, str: cstring) -> ^mut_val ---

	/** Creates and returns a raw value, returns NULL on error.
	    The `str` should be a UTF-8 string, null-terminator is not required.

	    @warning The input string is not copied, you should keep this string
	        unmodified for the lifetime of this JSON document. */
	mut_rawn :: #force_inline proc(doc: ^mut_doc, str: cstring, len: c.size_t) -> ^mut_val ---

	/** Creates and returns a raw value, returns NULL on error.
	    The `str` should be a null-terminated UTF-8 string.
	    The input string is copied and held by the document. */
	mut_rawcpy :: #force_inline proc(doc: ^mut_doc, str: cstring) -> ^mut_val ---

	/** Creates and returns a raw value, returns NULL on error.
	    The `str` should be a UTF-8 string, null-terminator is not required.
	    The input string is copied and held by the document. */
	mut_rawncpy :: #force_inline proc(doc: ^mut_doc, str: cstring, len: c.size_t) -> ^mut_val ---

	/** Creates and returns a null value, returns NULL on error. */
	mut_null :: #force_inline proc(doc: ^mut_doc) -> ^mut_val ---

	/** Creates and returns a true value, returns NULL on error. */
	mut_true :: #force_inline proc(doc: ^mut_doc) -> ^mut_val ---

	/** Creates and returns a false value, returns NULL on error. */
	mut_false :: #force_inline proc(doc: ^mut_doc) -> ^mut_val ---

	/** Creates and returns a bool value, returns NULL on error. */
	mut_bool :: #force_inline proc(doc: ^mut_doc, val: bool) -> ^mut_val ---

	/** Creates and returns an unsigned integer value, returns NULL on error. */
	mut_uint :: #force_inline proc(doc: ^mut_doc, num: c.uint64_t) -> ^mut_val ---

	/** Creates and returns a signed integer value, returns NULL on error. */
	mut_sint :: #force_inline proc(doc: ^mut_doc, num: c.int64_t) -> ^mut_val ---

	/** Creates and returns a signed integer value, returns NULL on error. */
	mut_int :: #force_inline proc(doc: ^mut_doc, num: c.int64_t) -> ^mut_val ---

	/** Creates and returns an real number value, returns NULL on error. */
	mut_real :: #force_inline proc(doc: ^mut_doc, num: c.double) -> ^mut_val ---

	/** Creates and returns a string value, returns NULL on error.
	    The `str` should be a null-terminated UTF-8 string.
	    @warning The input string is not copied, you should keep this string
	        unmodified for the lifetime of this JSON document. */
	mut_str :: #force_inline proc(doc: ^mut_doc, str: cstring) -> ^mut_val ---

	/** Creates and returns a string value, returns NULL on error.
	    The `str` should be a UTF-8 string, null-terminator is not required.
	    @warning The input string is not copied, you should keep this string
	        unmodified for the lifetime of this JSON document. */
	mut_strn :: #force_inline proc(doc: ^mut_doc, str: cstring, len: c.size_t) -> ^mut_val ---

	/** Creates and returns a string value, returns NULL on error.
	    The `str` should be a null-terminated UTF-8 string.
	    The input string is copied and held by the document. */
	mut_strcpy :: #force_inline proc(doc: ^mut_doc, str: cstring) -> ^mut_val ---

	/** Creates and returns a string value, returns NULL on error.
	    The `str` should be a UTF-8 string, null-terminator is not required.
	    The input string is copied and held by the document. */
	mut_strncpy :: #force_inline proc(doc: ^mut_doc, str: cstring, len: c.size_t) -> ^mut_val ---

	mut_equals_str :: #force_inline proc(val: ^mut_val, str: cstring) -> bool ---
	mut_equals_strn :: #force_inline proc(val: ^mut_val, str: cstring, len: c.size_t) -> bool ---
	mut_equals :: #force_inline proc(lhs: ^mut_val, rhs: ^mut_val) -> bool ---


	/* mut write ----------------------------- */

	// Write a document to JSON string. Thread-safe when: The doc is not modified by other threads.
	// Returns a new JSON string, or NULL if an error occurs. This string is encoded as UTF-8 with a null-terminator. When it's no longer needed, it should be freed with libc.free().
	mut_write :: #force_inline proc(doc: ^mut_doc, flg: write_flag, len: ^c.size_t = nil) -> cstring ---

	// Write a document to JSON string. Thread-safe when: The file is not accessed by other threads, doc is not modified by other threads and The alc is thread-safe or NULL.
	mut_write_file :: proc(path: cstring, doc: ^mut_doc, flg: write_flag, alc: ^alc = nil, err: ^write_err = nil) -> bool ---

	// Write a document to file pointer with options.
	mut_write_fp :: proc(fp: ^libc.FILE, doc: ^mut_doc, flg: write_flag, alc: ^alc = nil, err: ^write_err = nil) -> bool ---

	// Write a document to JSON string with options. This function is thread-safe when: The alc is thread-safe or NULL.
	mut_write_opts :: proc(doc: ^mut_doc, flg: write_flag, alc: ^alc = nil, err: ^write_err = nil) -> cstring ---

	mut_val_write_opts :: proc(val: ^mut_val, flg: write_flag, alc: ^alc = nil, len: ^c.size_t = nil, err: ^write_err = nil) -> cstring ---
	mut_val_write :: #force_inline proc(val: ^mut_val, flg: write_flag, len: ^c.size_t = nil) -> cstring ---
	mut_val_write_file :: proc(path: cstring, val: mut_val, flg: write_flag, alc: ^alc = nil, err: ^write_err = nil) -> bool ---
	mut_val_write_fp :: proc(fp: ^libc.FILE, val: ^mut_val, flg: write_flag, alc: ^alc = nil, err: ^write_err = nil) -> bool ---

	/* write ----------------------------- */

	write :: #force_inline proc(doc: ^doc, flg: write_flag, len: ^c.size_t = nil) -> cstring ---
	write_file :: proc(path: cstring, doc: ^doc, flg: write_flag, alc: ^alc = nil, err: ^write_err = nil) -> bool ---
	write_fp :: proc(fp: ^libc.FILE, doc: ^doc, flg: write_flag, alc: ^alc = nil, err: ^write_err = nil) -> bool ---
	write_opts :: proc(doc: ^doc, flg: write_flag, alc: ^alc = nil, len: ^c.size_t = nil, err: ^write_err = nil) -> cstring ---
	val_write :: #force_inline proc(val: ^val, flg: write_flag, len: ^c.size_t = nil) -> cstring ---
	val_write_file :: proc(path: cstring, val: ^val, flg: write_flag, alc: ^alc = nil, err: ^write_err = nil) -> bool ---
	val_write_fp :: proc(fp: ^libc.FILE, val: ^val, flg: write_flag, alc: ^alc = nil, err: ^write_err = nil) -> bool ---
	val_write_opts :: proc(val: ^val, flg: write_flag, alc: ^alc = nil, len: ^c.size_t = nil, err: ^write_err = nil) -> cstring ---


	/* read ----------------------------- */

	read :: #force_inline proc(data: cstring, len: c.size_t, flg: read_flag) -> ^doc ---
	read_opts :: proc(dat: ^c.char, len: c.size_t, flg: read_flag, alc: ^alc = nil, err: ^read_err = nil) -> ^doc ---
	read_file :: proc(path: cstring, flg: read_flag, alc: ^alc = nil, err: ^read_err = nil) -> ^doc ---
	read_fp :: proc(fp: ^libc.FILE, flg: read_flag, alc: ^alc = nil, err: ^read_err = nil) -> ^doc ---
	read_max_memory_usage :: proc(len: c.size_t, flg: read_flag) -> c.size_t ---
	read_number :: proc(dat: cstring, val: val, flg: read_flag, alc: ^alc = nil, err: ^read_err = nil) -> cstring ---
	mut_read_number :: #force_inline proc(dat: cstring, val: ^mut_val, flg: read_flag, alc: ^alc = nil, err: ^read_err = nil) -> cstring ---

}
