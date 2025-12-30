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
