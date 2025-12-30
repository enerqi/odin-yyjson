// yyjson examples similar to the sample code within the yyjson readme
package yyjson_example

import "core:c"
import "core:c/libc"
import "core:log"
import "core:os"
import "core:time"

import yyj ".."


read_json_string :: proc() {
	json := cstring(`{"name":"Mash","star":4,"hits":[2,2,1,3]}`)
	doc := yyj.read(json, len(json), {})
	defer yyj.doc_free(doc)

	root := yyj.doc_get_root(doc)

	// Get root["name"]
	// yyjson_val *name = yyjson_obj_get(root, "name");
	name := yyj.obj_get(root, "name")
	log.info("name:", yyj.get_str(name))
	log.info("name length:", yyj.get_len(name))

	// Get root["star"]
	star := yyj.obj_get(root, "star")
	log.info("star:", yyj.get_int(star))

	// Get root["hits"], iterate over the array
	hits := yyj.obj_get(root, "hits")
	for iter := yyj.arr_iter_with(hits); yyj.arr_iter_has_next(&iter); {
		hit := yyj.arr_iter_next(&iter)
		log.info("hit:", yyj.get_int(hit))
	}
}

write_json_string :: proc() {
	doc := yyj.mut_doc_new()
	defer yyj.mut_doc_free(doc)
	root := yyj.mut_obj(doc)
	yyj.mut_doc_set_root(doc, root)

	// Set root["name"] and root["star"]
	yyj.mut_obj_add_str(doc, root, "name", "Mash")
	yyj.mut_obj_add_int(doc, root, "star", 4)

	// Set root["hits"] with an array
	hits_arr := [?]c.int32_t{2, 2, 1, 3}
	hits := yyj.mut_arr_with_sint32(doc, raw_data(&hits_arr), 4)
	yyj.mut_obj_add_val(doc, root, "hits", hits)

	// To string, minified
	len: c.size_t
	json := yyj.mut_write(doc, {}, &len)
	if json != nil {
		log.info("json:", json)
		libc.free(rawptr(json))
	}
}


TEMP_FILE_PATH :: "temp.json"

write_json_file_with_options :: proc() {
	json := cstring(`{"foo": true, "bar": "こんにちは", "baz":null,} // comment`)
	// Need to allow comments and trailing commas (bit 3 and bit 2)
	flg := yyj.Read_Flags{.ALLOW_TRAILING_COMMAS, .ALLOW_COMMENTS}
	idoc := yyj.read(json, len(json), flg)
	defer yyj.doc_free(idoc)

	// As mutable doc
	doc := yyj.doc_mut_copy(idoc)
	defer yyj.mut_doc_free(doc)
	obj := yyj.mut_doc_get_root(doc)

	// Remove null values in root object
	for iter := yyj.mut_obj_iter_with(obj); yyj.mut_obj_iter_has_next(&iter); {
		key := yyj.mut_obj_iter_next(&iter)
		val := yyj.mut_obj_iter_get_val(key)
		if yyj.mut_is_null(val) {
			yyj.mut_obj_iter_remove(&iter)
		}
	}

	// Write the json pretty, escape unicode
	err: yyj.Write_Err
	yyj.mut_write_file(TEMP_FILE_PATH, doc, yyj.Write_Flags{}, nil, &err)
	if err.code != .SUCCESS {
		log.error("write error:", err.code, err.msg)
	}
}

read_json_file_with_options :: proc() {
	err: yyj.Read_Err
	doc := yyj.read_file(TEMP_FILE_PATH, {}, nil, &err)
	defer yyj.doc_free(doc)

	// iterate over root object
	if doc != nil {
		obj := yyj.doc_get_root(doc)
		for iter := yyj.obj_iter_with(obj); yyj.obj_iter_has_next(&iter); {
			key := yyj.obj_iter_next(&iter)
			val := yyj.obj_iter_get_val(key)

			log.infof("%s: %s\n", yyj.get_str(key), yyj.get_type_desc(val))
		}
	} else {
		log.errorf("read error (%v): %v at position: %v", err.code, err.msg, err.pos)
	}
}


main :: proc() {
	start_time := time.now()

	logger := log.create_console_logger()
	defer log.destroy_console_logger(logger)
	context.logger = logger
	defer {
		run_time := time.since(start_time)
		log.info("example program duration: ", run_time)
	}

	log.info("yyjson version is: ", yyj.version())

	read_json_string()
	write_json_string()

	tempf, err := os.open(TEMP_FILE_PATH, os.O_CREATE, 0o664)
	have_temp_file := (err == os.ERROR_NONE)
	if have_temp_file do os.close(tempf)
	defer if have_temp_file {
		os.remove(TEMP_FILE_PATH)
	}

	write_json_file_with_options()
	read_json_file_with_options()
}
