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
	SUCCESS                       = 0,
	/** Invalid parameter, such as NULL input string or 0 input length. */
	ERROR_INVALID_PARAMETER       = 1,
	/** Memory allocation failed. */
	ERROR_MEMORY_ALLOCATION       = 2,
	/** Input JSON string is empty. */
	ERROR_EMPTY_CONTENT           = 3,
	/** Unexpected content after document, such as `[123]abc`. */
	ERROR_UNEXPECTED_CONTENT      = 4,
	/** Unexpected end of input, the parsed part is valid, such as `[123`. */
	ERROR_UNEXPECTED_END          = 5,
	/** Unexpected character inside the document, such as `[abc]`. */
	ERROR_UNEXPECTED_CHARACTER    = 6,
	/** Invalid JSON structure, such as `[1,]`. */
	ERROR_JSON_STRUCTURE          = 7,
	/** Invalid comment, deprecated, use `ERROR_UNEXPECTED_END` for unclosed comment. */
	ERROR_INVALID_COMMENT         = 8,
	/** Invalid number, such as `123.e12`, `000`. */
	ERROR_INVALID_NUMBER          = 9,
	/** Invalid string, such as invalid escaped character inside a string. */
	ERROR_INVALID_STRING          = 10,
	/** Invalid JSON literal, such as `truu`. */
	ERROR_LITERAL                 = 11,
	/** Failed to open a file. */
	ERROR_FILE_OPEN               = 12,
	/** Failed to read a file. */
	ERROR_FILE_READ               = 13,
	/** Incomplete input during incremental parsing; parsing state is preserved. */
	ERROR_MORE                    = 14,
	/** Read depth limit exceeded. */
	ERROR_DEPTH                   = 15,
}

// Hand-written enum for yyjson_patch_code, as it's defined as static const values in C
Patch_Code :: enum c.uint32_t {
	/** Success, no error. */
	SUCCESS                  = 0,
	/** Invalid parameter, such as NULL input or non-array patch. */
	ERROR_INVALID_PARAMETER  = 1,
	/** Memory allocation failure occurs. */
	ERROR_MEMORY_ALLOCATION  = 2,
	/** JSON patch operation is not object type. */
	ERROR_INVALID_OPERATION  = 3,
	/** JSON patch operation is missing a required key. */
	ERROR_MISSING_KEY        = 4,
	/** JSON patch operation member is invalid. */
	ERROR_INVALID_MEMBER     = 5,
	/** JSON patch operation `test` not equal. */
	ERROR_EQUAL              = 6,
	/** JSON patch operation failed on JSON pointer. */
	ERROR_POINTER            = 7,
}

// Hand-written enum for yyjson_ptr_code, as it's defined as static const values in C
Ptr_Code :: enum c.uint32_t {
	/** No JSON pointer error. */
	ERR_NONE                 = 0,
	/** Invalid input parameter, such as NULL input. */
	ERR_PARAMETER            = 1,
	/** JSON pointer syntax error, such as invalid escape, token no prefix. */
	ERR_SYNTAX               = 2,
	/** JSON pointer resolve failed, such as index out of range, key not found. */
	ERR_RESOLVE              = 3,
	/** Document's root is NULL, but it is required for the function call. */
	ERR_NULL_ROOT            = 4,
	/** Cannot set root as the target is not a document. */
	ERR_SET_ROOT             = 5,
	/** The memory allocation failed and a new value could not be created. */
	ERR_MEMORY_ALLOCATION    = 6,
}

// Hand-written enum for yyjson_read_flag, as it's defined as bit flags in C
Read_Flag :: enum c.uint32_t {
	/** Read the input data in-situ. */
	INSITU                    = 0,
	/** Stop when done instead of issuing an error if there's additional content after a JSON document. */
	STOP_WHEN_DONE            = 1,
	/** Allow single trailing comma at the end of an object or array (non-standard). */
	ALLOW_TRAILING_COMMAS     = 2,
	/** Allow C-style single-line and mult-line comments (non-standard). */
	ALLOW_COMMENTS            = 3,
	/** Allow inf/nan number and literal, case-insensitive (non-standard). */
	ALLOW_INF_AND_NAN         = 4,
	/** Read all numbers as raw strings. */
	NUMBER_AS_RAW             = 5,
	/** Allow reading invalid unicode when parsing string values (non-standard). */
	ALLOW_INVALID_UNICODE     = 6,
	/** Read big numbers as raw strings (non-standard). */
	BIGNUM_AS_RAW             = 7,
	/** Allow UTF-8 BOM and skip it before parsing if any (non-standard). */
	ALLOW_BOM                 = 8,
	/** Allow extended number formats (non-standard). */
	ALLOW_EXT_NUMBER          = 9,
	/** Allow extended escape sequences in strings (non-standard). */
	ALLOW_EXT_ESCAPE          = 10,
	/** Allow extended whitespace characters (non-standard). */
	ALLOW_EXT_WHITESPACE      = 11,
	/** Allow strings enclosed in single quotes (non-standard). */
	ALLOW_SINGLE_QUOTED_STR   = 12,
	/** Allow object keys without quotes (non-standard). */
	ALLOW_UNQUOTED_KEY        = 13,
}

Read_Flags :: bit_set[Read_Flag; c.uint32_t]

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
JSON5 :: Read_Flags{.ALLOW_TRAILING_COMMAS, .ALLOW_COMMENTS, .ALLOW_INF_AND_NAN, .ALLOW_EXT_NUMBER, .ALLOW_EXT_ESCAPE, .ALLOW_EXT_WHITESPACE, .ALLOW_SINGLE_QUOTED_STR, .ALLOW_UNQUOTED_KEY}

// Hand-written enum for yyjson_write_flag, as it's defined as bit flags in C
Write_Flag :: enum c.uint32_t {
	/** Write JSON pretty with 4 space indent. */
	PRETTY                    = 0,
	/** Escape unicode as `uXXXX`, make the output ASCII only. */
	ESCAPE_UNICODE            = 1,
	/** Escape '/' as '\/'. */
	ESCAPE_SLASHES            = 2,
	/** Write inf and nan number as 'Infinity' and 'NaN' literal (non-standard). */
	ALLOW_INF_AND_NAN         = 3,
	/** Write inf and nan number as null literal.
	    This flag will override `ALLOW_INF_AND_NAN` flag. */
	INF_AND_NAN_AS_NULL       = 4,
	/** Allow invalid unicode when encoding string values (non-standard).
	    Invalid characters in string value will be copied byte by byte.
	    If `ESCAPE_UNICODE` flag is also set, invalid character will be
	    escaped as `U+FFFD` (replacement character).
	    This flag does not affect the performance of correctly encoded strings. */
	ALLOW_INVALID_UNICODE     = 5,
	/** Write JSON pretty with 2 space indent.
	    This flag will override `PRETTY` flag. */
	PRETTY_TWO_SPACES         = 6,
	/** Adds a newline character `\n` at the end of the JSON.
	    This can be helpful for text editors or NDJSON. */
	NEWLINE_AT_END            = 7,
	/** Write floating-point numbers using single-precision (float).
	    This casts `double` to `float` before serialization.
	    This will produce shorter output, but may lose some precision.
	    This flag is ignored if `FP_TO_FIXED(prec)` is also used. */
	FP_TO_FLOAT               = 27,
}

Write_Flags :: bit_set[Write_Flag; u32]

// Hand-written enum for yyjson_write_code, as it's defined as static const values in C
Write_Code :: enum c.uint32_t {
	/** Success, no error. */
	SUCCESS                     = 0,
	/** Invalid parameter, such as NULL document. */
	ERROR_INVALID_PARAMETER     = 1,
	/** Memory allocation failure occurs. */
	ERROR_MEMORY_ALLOCATION     = 2,
	/** Invalid value type in JSON document. */
	ERROR_INVALID_VALUE_TYPE    = 3,
	/** NaN or Infinity number occurs. */
	ERROR_NAN_OR_INF            = 4,
	/** Failed to open a file. */
	ERROR_FILE_OPEN             = 5,
	/** Failed to write a file. */
	ERROR_FILE_WRITE            = 6,
	/** Invalid unicode in string. */
	ERROR_INVALID_STRING        = 7,
}

// Hand-written enum for yyjson_type, as it's defined as #define constants in C
Type :: enum u8 {
	/** No type, invalid. */
	NONE                        = 0,
	/** Raw string type, no subtype. */
	RAW                         = 1,
	/** Null type: `null` literal, no subtype. */
	NULL                        = 2,
	/** Boolean type, subtype: TRUE, FALSE. */
	BOOL                        = 3,
	/** Number type, subtype: UINT, SINT, REAL. */
	NUM                         = 4,
	/** String type, subtype: NONE, NOESC. */
	STR                         = 5,
	/** Array type, no subtype. */
	ARR                         = 6,
	/** Object type, no subtype. */
	OBJ                         = 7,
}

// Hand-written enum for yyjson_subtype, as it's defined as #define constants in C
Subtype :: enum u8 {
	/** No subtype. */
	NONE                        = 0,
	/** False subtype: `false` literal. */
	FALSE                       = 0,
	/** Unsigned integer subtype: `uint64_t`. */
	UINT                        = 0,
	/** True subtype: `true` literal. */
	TRUE                        = 8,
	/** Signed integer subtype: `int64_t`. */
	SINT                        = 8,
	/** String that does not need to be escaped for writing (internal use). */
	NOESC                       = 8,
	/** Real number subtype: `double`. */
	REAL                        = 16,
}
