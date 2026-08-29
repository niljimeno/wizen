package generator

import "../parser"
import "core:bytes"
import "core:fmt"

into_static :: proc(input: [dynamic]byte) -> []byte {
	response := make([]byte, len(input))
	copy_slice(response, input[:])
	return response
}

get_base_function :: proc(name: string) -> string {
	switch name {
	case "print":
		return "console.log"
	case "+":
		return "_add"
	}

	return ""
}

generate_thread :: proc(args: []parser.Variable) -> string {
	new_args := make([][]byte, len(args))
	initial_value := args[0]

	for i := len(args) - 1; i > 0; i += 1 {
		if args[i].type == .Function {
			// get it into a group, otherwise add to existing group
			_ = parser.Variable {
				type  = .Group,
				value = []parser.Variable{args[0]},
			}
		}
	}

	return ""
}

get_advanced_function :: proc(name: string, args: []parser.Variable) -> string {
	switch name {
	case "->":
		return generate_thread(args)
	}

	return ""
}

generate_group :: proc(input: parser.Variable) -> [dynamic]byte {
	generated_code := [dynamic]byte{}
	elements: []parser.Variable = input.value.?
	if len(elements) < 1 {
		fmt.println("too few elements!")
		return nil
	}

	first := &elements[0]
	function: parser.Variable

	#partial switch first.type {
	case .Function:
		function = first^
	}

	elements_code := [dynamic][]byte{}
	for element in elements[1:] {
		append(&elements_code, generate_from_variable(element))
	}

	separator := []byte{',', ' '}
	inner_code := bytes.join(elements_code[:], separator)

	if function.type != .Function {
		fmt.println("No function :c")
		return nil
	}


	function_name: string = elements[0].value.?
	base_function := get_base_function(function_name)
	if base_function != "" {
		content := fmt.tprintf("%s(%s)\n", base_function, inner_code)
		append(&generated_code, content)
		return generated_code
	}

	advanced_function := get_advanced_function(function_name, elements[1:])
	if advanced_function != "" {
		content := fmt.tprintf("%s(%s)\n", advanced_function, inner_code)
		append(&generated_code, content)
		return generated_code
	}

	return generated_code
}

generate_from_variable :: proc(input: parser.Variable) -> []byte {
	// !todo use context for code gen
	generated_code: [dynamic]byte

	switch input.type {
	case .Group:
		generated_code = generate_group(input)

	case .String:
		element: string = input.value.?
		append(&generated_code, fmt.tprintf("\"%s\"", element))

	case .Int:
		element: int = input.value.?
		append(&generated_code, fmt.tprintf("%d", element))

	case .Float:
		element: int = input.value.?
		append(&generated_code, fmt.tprintf("%d", element))

	case .Function:
		element: string = input.value.?
		append(&generated_code, element)
	}

	return into_static(generated_code)
}

generate :: proc(input: []parser.Variable) -> []byte {
	generated_code := [dynamic]byte{}
	append(&generated_code, ..#load("../js/core.js"))

	for el in input {
		append(&generated_code, ..generate_from_variable(el))
	}

	return into_static(generated_code)
}
