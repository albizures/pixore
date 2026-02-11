package config

import "core:fmt"
import "core:log"
import "core:mem"


Parser :: struct {
	tokenizer: Tokenizer,
	current:   Token,
	errors:    [dynamic]Error,
	values:    map[string]Value,
	next:      Token,
	allocator: mem.Allocator,
}

Error :: struct {
	message: string,
}


PrimitiveValue :: union {
	string,
	f32,
}

Value :: union {
	string,
	f32,
	[dynamic]PrimitiveValue,
}

make_parser :: proc(content: string, allocator := context.allocator) -> Parser {
	parser := Parser {
		tokenizer = make_tokenizer(content),
		values    = make(map[string]Value, allocator),
		errors    = make([dynamic]Error, allocator),
	}

	parser.next = get_token(&parser.tokenizer)

	return parser
}

destroy_parser :: proc(parser: ^Parser) {
	delete(parser.errors)
	for key, item in parser.values {
		if arr, ok := item.([dynamic]PrimitiveValue); ok {
			delete(arr)
		}
	}
	delete(parser.values)
}

parse :: proc(parser: ^Parser) {
	for {
		// log.warn("/////", parser)
		_, ok := parser.current.(EOF_Token)
		if ok {
			break
		}

		next(parser)

		switch t in parser.current {
		case Ident_Token:
			parse_property(parser)
		case Invalid_Token:
		// nothing yet
		case EOF_Token:
			break
		case Equal_Token,
		     Number_Token,
		     String_Token,
		     End_Arr_Token,
		     Start_Arr_Token,
		     Comma_Token,
		     SOF_Token:
			append(&parser.errors, Error{message = "Invalid syntax, not expected token"})
		}
	}
}

next :: proc(parser: ^Parser) -> ^Token {
	parser.current = parser.next
	parser.next = get_token(&parser.tokenizer)

	return &parser.current
}


parse_property :: proc(parser: ^Parser) {
	ident := assert_token(
		&parser.current,
		Ident_Token,
		"Invalid call of parser_property, expects identifier",
	)

	if _, ok := next(parser).(Equal_Token); !ok {
		append(&parser.errors, Error{message = "Missing equal"})
	}

	switch token in next(parser) {
	case String_Token:
		parser.values[ident.value] = token.value
	case Number_Token:
		parser.values[ident.value] = token.value
	case Start_Arr_Token:
		parse_array(ident.value, parser)
	case Ident_Token, Equal_Token, Invalid_Token, End_Arr_Token, EOF_Token, SOF_Token, Comma_Token:
		append(&parser.errors, Error{message = "Invalid value"})
	}
}


parse_array :: proc(name: string, parser: ^Parser) {
	assert_token(
		&parser.current,
		Start_Arr_Token,
		"Invalid call of parser_array, expects start of array",
	)

	if _, ok := parser.next.(Comma_Token); ok {
		append(&parser.errors, Error{message = "Invalid syntax: unexpected comma"})
		next(parser) // skip comma
	}

	values := make([dynamic]PrimitiveValue, parser.allocator)

	loop: for {
		switch t in next(parser) {
		case EOF_Token:
			break loop
		case String_Token:
			append(&values, t.value)
		case Number_Token:
			append(&values, t.value)
		case SOF_Token,
		     End_Arr_Token,
		     Comma_Token,
		     Invalid_Token,
		     Equal_Token,
		     Start_Arr_Token,
		     Ident_Token:
			append(&parser.errors, Error{message = "Invalid syntax in array"})
		}

		#partial switch n in parser.next {
		case Comma_Token:
			next(parser)
		case End_Arr_Token:
			break loop
		case:
			append(&parser.errors, Error{message = "Invalid syntax: unexpected comma"})
		}
	}

	parser.values[name] = values
}

assert_token :: proc(
	token: ^Token,
	$Kind: typeid,
	message: string,
	loc := #caller_location,
) -> Kind {
	token, ok := token.(Kind)
	assert(ok, message, loc)

	return token
}
