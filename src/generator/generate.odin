package generator

import "../parser"
import "core:bytes"
import "core:fmt"

into_static :: proc(input: [dynamic]byte) -> []byte {
	response := make([]byte, len(input))
	copy_slice(response, input[:])
	defer delete(input)

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

add_first_argument :: proc(fn: parser.Variable, arg: parser.Variable) -> parser.Variable {
	new_fn: parser.Variable

	if fn.type == .Function {
		new_fn_values := make([]parser.Variable, 2)
		new_fn_values[0] = fn
		new_fn_values[1] = arg

		new_fn = parser.Variable {
			type  = .Group,
			value = new_fn_values,
		}

		return new_fn
	}

	fn_values: []parser.Variable = fn.value.?
	defer delete(fn_values)

	new_fn_values := make([]parser.Variable, len(fn_values) + 1)

	new_fn_values[0] = fn_values[0]
	new_fn_values[1] = arg
	for i := 1; i < len(fn_values); i += 1 {
		new_fn_values[i + 1] = fn_values[i]
	}

	new_fn = parser.Variable {
		type  = .Group,
		value = new_fn_values,
	}

	return new_fn
}

generate_basic_thread :: proc(args: []parser.Variable) -> []u8 {
	value := args[0]

	for i := 1; i < len(args); i += 1 {
		new_value := add_first_argument(args[i], value)
		value = new_value
	}

	return generate_from_variable(value)
}

get_advanced_function :: proc(name: string, args: []parser.Variable) -> []u8 {
	switch name {
	case "->":
		return generate_basic_thread(args)
	}

	return nil
}

generate_group :: proc(input: parser.Variable) -> [dynamic]byte {
	generated_code := [dynamic]byte{}
	elements: []parser.Variable = input.value.?
	defer delete(elements)

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

	if function.type != .Function {
		fmt.println("No function :c")
		return nil
	}

	function_name: string = elements[0].value.?
	base_function := get_base_function(function_name)

	if base_function != "" {
		elements_code := [dynamic][]byte{}
		for element in elements[1:] {
			append(&elements_code, generate_from_variable(element))
		}

		separator := []byte{',', ' '}
		inner_code := bytes.join(elements_code[:], separator)
		defer delete(inner_code)

		for e in elements_code {
			delete(e)
		}
		delete(elements_code)

		content := fmt.tprintf("%s(%s)\n", base_function, inner_code)
		append(&generated_code, content)
		return generated_code
	}

	advanced_function_content := get_advanced_function(function_name, elements[1:])
	if advanced_function_content != nil {
		append(&generated_code, ..advanced_function_content)
		delete(advanced_function_content)
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
