package main

import "core:bufio"
import "core:fmt"
import "core:os"

import "./tokenizer"

main :: proc() {
	data, err := os.read_entire_file("tests/1.scm", context.allocator)
	if err != nil {
		fmt.println(err)
		return
	}
	defer delete(data)

	tokenized_text := tokenizer.tokenize(data)

	fmt.printf("%s\n", data)
	fmt.printf("%v\n", tokenized_text)
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
