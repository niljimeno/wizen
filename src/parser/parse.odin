package parser

import "../tokenizer"
import "core:bytes"
import "core:strconv"


VariableType :: enum {
	Group,
	String,
	Int,
	Float,
	Function,
}

Variable :: struct {
	type:  VariableType,
	value: union {
		[]Variable,
		string,
		int,
		f32,
	},
}

get_opener :: proc(s: []byte) -> tokenizer.Group {
	if bytes_are_equal(s, []byte{'('}) {
		return .Paren
	}

	if bytes_are_equal(s, []byte{'['}) {
		return .Square
	}

	if bytes_are_equal(s, []byte{'{'}) {
		return .Curlie
	}

	return nil
}

get_closer :: proc(s: []byte) -> tokenizer.Group {
	if bytes_are_equal(s, []byte{')'}) {
		return .Paren
	}

	if bytes_are_equal(s, []byte{']'}) {
		return .Square
	}

	if bytes_are_equal(s, []byte{'}'}) {
		return .Curlie
	}

	return nil
}

bytes_are_equal :: proc(a, b: []byte) -> bool {
	return bytes.compare(a, b) == 0
}

Parser :: struct {
	parsed_data: []Variable,
}

manual_append_first :: proc(og: []Variable, first: Variable) -> []Variable {
	new_array := make([]Variable, len(og) + 1)
	new_array[0] = first

	for v, i in og {
		new_array[i + 1] = v
	}

	return new_array
}

list_function: Variable = Variable {
	type  = .Function,
	value = "list",
}

distance_from_next_group :: proc(input: [][]byte) -> int {
	moves: int

	opener := get_opener(input[0])
	if opener == nil {
		return moves
	}

	stack := [dynamic]tokenizer.Group{}
	stack_size := 1
	append(&stack, opener)

	for {
		moves += 1
		if (get_closer(input[moves]) != nil) {
			stack_size -= 1
			pop(&stack)

			if (stack_size == 0) {
				break
			}
			continue
		}

		if (get_opener(input[moves]) != nil) {
			stack_size += 1
			append(&stack, opener)
		}
	}

	return moves
}

count_groups :: proc(input: [][]byte) -> int {
	i: int
	count: int

	for i = 0; i < len(input); i += 1 {
		count += 1
		distance := distance_from_next_group(input[i:])
		i += distance
	}

	return count
}

parse_step :: proc(input: [][]byte) -> (Variable, int) {
	index := 0
	opener := get_opener(input[index])
	if opener != nil {
		starting_point := index + 1
		stack := [dynamic]tokenizer.Group{}
		append(&stack, opener)
		stack_size := 1

		for {
			index += 1
			if (get_closer(input[index]) != nil) {
				stack_size -= 1
				pop(&stack)

				if (stack_size == 0) {
					break
				}
				continue
			}

			if (get_opener(input[index]) != nil) {
				stack_size += 1
				append(&stack, opener)
			}
		}

		inner_group := parse(input[starting_point:index])

		#partial switch opener {
		case .Square:
			inner_group = manual_append_first(
				inner_group,
				Variable{type = .Function, value = "list"},
			)
		case .Curlie:
			inner_group = manual_append_first(
				inner_group,
				Variable{type = .Function, value = "struct"},
			)
		}

		return Variable{type = .Group, value = inner_group}, index
	}

	if input[index][0] == '"' && len(input[index]) > 1 {
		return Variable{type = .String, value = string(input[index][1:len(input[index]) - 1])},
			index
	}

	if input[index][0] == ':' {
		return Variable{type = .String, value = string(input[index][1:])}, index
	}

	ok: bool
	int_attempt: int
	int_attempt, ok = strconv.parse_int(string(input[index]))
	if ok {
		return Variable{type = .Int, value = int_attempt}, index
	}

	float_attempt: f32
	float_attempt, ok = strconv.parse_f32(string(input[index]))
	if ok {
		return Variable{type = .Float, value = float_attempt}, index
	}

	return Variable{type = .Function, value = string(input[index])}, index
}


parse :: proc(input: [][]byte) -> []Variable {
	count := count_groups(input)
	data: []Variable = make([]Variable, count)

	count = -1
	i: int
	moves: int
	for i = 0; i < len(input); i += 1 {
		count += 1
		data[count], moves = parse_step(input[i:])
		i += moves
	}

	return data
}
