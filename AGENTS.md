# Project Commands

## Building yyjson bindings

To generate the Odin bindings for yyjson, use `odin-c-bindgen`:

```bash
../odin-c-bindgen/bindgen.exe .
```

This command uses the `bindgen.sjson` configuration file to generate the bindings. The bindgen program translates the yyjson.h and .c source files in the `src/` directory into the `yyjson.odin` file.

The `procedure_type_overrides` setting in `bindgen.sjson` allows customizing the generated types for parameters. This is used to:
- Provide default nil values for optional parameters (alc, err, ctx)
- Functions with pointer parameters documented as "can be NULL" or "NULL if not needed" have overrides with `= nil` defaults

After regenerating the bindings, run these commands to verify quality:

```bash
just lint      # Check for style and potential bugs
just format    # Format the generated code
just run       # Build and run the example test
```

This ensures the generated bindings compile, pass linting checks, are properly formatted, and work correctly with the example code.

## Prelude and Footer files

The bindgen tool uses two special Odin files to customize the bindings:

### Prelude (`src/prelude.odin`)
- Injected near the top of the generated `yyjson.odin` file
- Used for foreign library imports and hand-written type definitions
- Contains all enum types that replace auto-generated C types (Read_Code, Write_Code, Type, Subtype, etc.)
- Contains all bit_set types (Read_Flags, Write_Flags)
- Configured in `bindgen.sjson` via the `imports_file` setting

### Footer (`src/yyjson_footer.odin`)
- Appended at the end of the generated `yyjson.odin` file
- Used for Odin procedures that wrap or enhance the C API (like `write_flags_add_write_fp_to_fixed_precision_bits`)
- Should be minimal - most custom code belongs in the prelude

### Using the remove setting

The `remove` setting in `bindgen.sjson` suppresses auto-generated definitions so hand-written versions can be used instead:
- Add the C type name (before Ada casing) to suppress it from generation
- Example: `"yyjson_read_code"` removes auto-generated Read_Code so the prelude version is used
- Example: `"yyjson_read_flag"` removes auto-generated Read_Flag/Read_Flags so prelude versions are used
- Only C names should be in the remove list, not Odin type names

### Checking for new constants when updating yyjson

When updating yyjson to a new version, hand-written enum definitions in `src/prelude.odin` must be checked for new constants:

1. **Identify affected enums**: Look at comments in prelude.odin for enums defined from C constants:
   - `Read_Code`, `Write_Code`, `Patch_Code`, `Ptr_Code` (error/status codes)
   - `Read_Flag`, `Write_Flag` (bit flags)
   - `Type`, `Subtype` (JSON value types)

2. **Compare with C source**: Check `src/yyjson.h` for new `YYJSON_*` #define constants that belong to these enums

3. **Update the enum**: Add new constants with correct values and documentation

4. **Update the remove list**: If a new enum type was added to yyjson.h, add its C name to the `remove` setting in `bindgen.sjson` to prevent auto-generation

5. **Verify**: Run `just lint` and `just run` to ensure the updated definitions compile correctly

## Linting

To lint the generated output, use:

```bash
just lint
```

## Formatting

To format the output, use:

```bash
just format
```
