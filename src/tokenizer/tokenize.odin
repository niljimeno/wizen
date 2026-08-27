package tokenizer

import "core:fmt"
Opener :: enum {
	Paren,
	Quote,
	None,
}

State :: enum {
	ReadingVar,
	ReadingString,
	Waiting,
}

Space :: enum {}

word_char :: proc(c: byte) -> bool {
	return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

var_char :: proc(c: byte) -> bool {
	return word_char(c) || c == '-' || c == ')'
}

opener_char :: proc(c: byte) -> bool {
	return c == '(' || c == '[' || c == '{'
}

closer_char :: proc(c: byte) -> bool {
	return c == ')' || c == ']' || c == '}'
}

transition :: proc(transitor: byte) -> State {
	if var_char(transitor) {
		return .ReadingVar
	}

	if opener_char(transitor) || closer_char(transitor) {
		return .Waiting
	}

	if transitor == '"' {
		return .ReadingString
	}

	return .Waiting
}

tokenize :: proc(input: []byte) -> [][]byte {
	starting: int
	state: State = .Waiting


	tokenized_text := [dynamic][]byte{}

	i: int
	for i = 0; i < len(input); i += 1 {

		fmt.printf("%v\n", state)

		switch state {
		case .Waiting:
			if input[i] == ' ' {
				continue
			}
			starting = i
			state = transition(input[i])

		case .ReadingVar:
			if var_char(input[i]) {
				continue
			}

			append(&tokenized_text, input[starting:i])
			state = .Waiting

		case .ReadingString:
			if input[i] != '"' {
				continue
			}

			append(&tokenized_text, input[starting:i + 1])
			state = .Waiting
		}
	}

	switch state {
	case .Waiting:
		break
	case .ReadingVar:
	case .ReadingString:
		append(&tokenized_text, input[starting:i])
	}

	for v in tokenized_text {
		fmt.printf("%s|", v)
	}

	response := make([][]byte, len(tokenized_text))
	copy_slice(response, tokenized_text[:])

	return response
}
