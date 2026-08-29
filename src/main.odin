package main

import "core:bufio"
import "core:fmt"
import "core:os"

import "./generator"
import "./parser"
import "./tokenizer"

process :: proc(data: []byte) -> []byte {
	tokenized_text, err := tokenizer.tokenize(data)
	if err != nil {
		fmt.printf("Syntax error: %v\n", err)
		return nil
	}

	parsed_data := parser.parse(tokenized_text)
	js_code := generator.generate(parsed_data)

	return js_code
}

main :: proc() {
	data, err := os.read_entire_file("tests/1.scm", context.allocator)
	if err != nil {
		fmt.println(err)
		return
	}
	defer delete(data)

	fmt.printf("%s\n", process(data))
	run_interpreter()
}

run_interpreter :: proc() {
	reader: bufio.Reader
	bufio.reader_init(&reader, os.to_reader(os.stdin))

	for {
		fmt.print("wizen> ")
		line, err := bufio.reader_read_string(&reader, '\n')
		if err != nil {
			fmt.println()
			break
		}

		fmt.printf("%s\n", process(transmute([]byte)line))
	}
}
