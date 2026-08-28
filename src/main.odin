package main

import "core:bufio"
import "core:fmt"
import "core:os"

import "./generator"
import "./parser"
import "./tokenizer"

main :: proc() {
	data, err := os.read_entire_file("tests/1.scm", context.allocator)
	if err != nil {
		fmt.println(err)
		return
	}
	defer delete(data)

	fmt.printf("%s\n", data)

	tokenized_text, tokErr := tokenizer.tokenize(data)
	if err != nil {
		fmt.panicf("%v\n", err)
	}

	for token in tokenized_text {
		fmt.printf("%s , ", token)
	}
	fmt.println()

	parsed_data := parser.parse(tokenized_text)
	fmt.printf("%v\n", parsed_data)

	js_code := generator.generate(parsed_data)
	fmt.printf("%s\n", js_code)
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

		fmt.printf("%s", line)
	}
}
