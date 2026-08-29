package tokenizer

Group :: enum {
	None,
	Paren,
	Curlie,
	Square,
}

State :: enum {
	ReadingVar,
	ReadingString,
	ReadingComment,
	Normal,
}

TokenizerData :: struct {
	input:       []byte,
	state:       State,
	start:       int,
	group_stack: [dynamic]Group,
	tokens:      [dynamic][]byte,
}

TokenizerError :: enum {
	Ok,
	UnclosedParentheses,
	UnclosedQuotes,
	ParenthesesMismatch,
}

Space :: enum {}

word_char :: proc(c: byte) -> bool {
	return(
		(c >= 'a' && c <= 'z') ||
		(c >= 'A' && c <= 'Z') ||
		(c >= '0' && c <= '9') ||
		c == '.' ||
		c == ',' ||
		c == '-' ||
		c == '>' ||
		c == '<' ||
		c == '=' ||
		c == '+' ||
		c == '*' ||
		c == '/' \
	)
}

var_char :: proc(c: byte) -> bool {
	return word_char(c) || c == '-'
}

opener_char :: proc(c: byte) -> bool {
	return c == '(' || c == '[' || c == '{'
}

closer_char :: proc(c: byte) -> bool {
	return c == ')' || c == ']' || c == '}'
}

empty_char :: proc(c: byte) -> bool {
	return c == ' ' || c == '\n' || c == '\r'
}

get_group :: proc(c: byte) -> Group {
	switch c {
	case '(', ')':
		return .Paren
	case '[', ']':
		return .Square
	case '{', '}':
		return .Curlie
	}

	return nil
}

open_stack :: proc(c: byte, stack: ^[dynamic]Group) {
	opener := get_group(c)
	append(stack, opener)
}

close_stack :: proc(c: byte, stack: ^[dynamic]Group) -> TokenizerError {
	stack_count := len(stack)
	if stack_count == 0 {
		return .ParenthesesMismatch
	}

	last := stack[len(stack) - 1]
	if get_group(c) != last {
		return .ParenthesesMismatch
	}

	pop(stack)
	return nil
}

transition :: proc(transitor: byte) -> State {
	if var_char(transitor) {
		return .ReadingVar
	}

	if transitor == '"' {
		return .ReadingString
	}

	if transitor == ';' {
		return .ReadingComment
	}

	return .Normal
}

process_tokenizer :: proc(data: ^TokenizerData, i: int) -> TokenizerError {
	c := data.input[i]

	switch data.state {
	case .Normal:
		if empty_char(c) {
			return nil
		}
		data.start = i

		if opener_char(c) {
			open_stack(c, &data.group_stack)
			append(&data.tokens, data.input[i:i + 1])
		}

		if closer_char(c) {
			err := close_stack(c, &data.group_stack)
			if err != nil {
				return err
			}

			append(&data.tokens, data.input[i:i + 1])
			return nil
		}

		err: TokenizerError
		data.state = transition(c)
		if err != nil {
			return err
		}

	case .ReadingComment:
		if c != '\n' {
			return nil
		}
		data.state = .Normal

	case .ReadingVar:
		if var_char(c) {
			return nil
		}

		append(&data.tokens, data.input[data.start:i])
		data.state = .Normal
		process_tokenizer(data, i)

	case .ReadingString:
		if c != '"' {
			return nil
		}

		append(&data.tokens, data.input[data.start:i + 1])
		data.state = .Normal
	}

	return nil
}

tokenize :: proc(input: []byte) -> ([][]byte, TokenizerError) {
	data := TokenizerData {
		state = .Normal,
		start = 0,
		input = input,
	}

	i: int
	for ; i < len(input); i += 1 {
		process_tokenizer(&data, i)
	}

	if len(data.group_stack) != 0 {
		return nil, .UnclosedParentheses
	}

	if data.state == .ReadingString {
		return nil, .UnclosedQuotes
	}

	response := make([][]byte, len(data.tokens))
	copy_slice(response, data.tokens[:])

	return response, nil
}
