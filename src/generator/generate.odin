package generator

import "../parser"
import "core:fmt"

into_static :: proc(input: [dynamic]byte) -> []byte {
	response := make([]byte, len(input))
	copy_slice(response, input[:])
	return response
}

generate_nested :: proc(input: parser.Variable) -> []byte {
	// !todo use context for code gen
	generated_code := [dynamic]byte{}

	#partial switch input.type {
	case .Group:
		function_name := "console.log"
		output := "\"hello world\""

		// import inner contents: tprintf, separate by commas !todo
		content := fmt.tprintf("%s(%s)", function_name, output)

		append(&generated_code, content)
	}

	return into_static(generated_code)
}

generate :: proc(input: []parser.Variable) -> []byte {
	generated_code := [dynamic]byte{}
	for el in input {
		append(&generated_code, ..generate_nested(el))
	}

	return into_static(generated_code)
}
