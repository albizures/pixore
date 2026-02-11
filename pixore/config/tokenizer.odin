package config

import "core:fmt"
import "core:log"
import "core:strconv"
import "core:strings"
import "core:unicode/utf8"

MULTILINE :: `"""`
CUTSET :: "\n"

Span :: struct {
	start, end: int,
}

Token_Kind :: enum {
	Ident,
	Equal,
	Number,
	String,
}

Ident_Token :: struct {
	value: string,
	span:  Span,
}

Equal_Token :: struct {
	span: Span,
}

Number_Token :: struct {
	span:  Span,
	value: f32,
}

String_Token :: struct {
	span:  Span,
	value: string,
}

Start_Arr_Token :: struct {
	span: Span,
}

End_Arr_Token :: struct {
	span: Span,
}

Comma_Token :: struct {
	span: Span,
}

SOF_Token :: struct {
	span: Span,
}

EOF_Token :: struct {
	span: Span,
}

Invalid_Token :: struct {
	span:  Span,
	value: string,
}

Token :: union #no_nil {
	SOF_Token,
	Invalid_Token,
	Ident_Token,
	Equal_Token,
	Number_Token,
	String_Token,
	Start_Arr_Token,
	End_Arr_Token,
	Comma_Token,
	EOF_Token,
}


is_letter :: proc(r: rune) -> bool {
	c := u8(r)
	return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

is_number :: proc(r: rune) -> bool {
	c := u8(r)
	return c >= '0' && c <= '9'
}


Tokenizer :: struct {
	data:    string,
	current: rune,
	index:   int,
	width:   int,
}

make_tokenizer :: proc(data: string) -> Tokenizer {
	t := Tokenizer {
		data = data,
	}

	consume_rune(&t)

	return t
}

consume_rune :: proc(t: ^Tokenizer) -> rune #no_bounds_check {
	if t.index >= len(t.data) {
		t.current = utf8.RUNE_EOF
		t.index = len(t.data) - 1
	} else {
		t.index += t.width
		t.current, t.width = utf8.decode_rune_in_string(t.data[t.index:])
		if t.index >= len(t.data) {
			t.current = utf8.RUNE_EOF
		}
	}
	return t.current
}

skip_runes :: proc(t: ^Tokenizer, amount: int) {
	for index in 0 ..= amount {
		consume_rune(t)
	}
}

get_token :: proc(t: ^Tokenizer, loc := #caller_location) -> (token: Token) {
	switch t.current {
	case 'A' ..= 'Z', 'a' ..= 'z', '_':
		start := t.index

		con_ident(t)
		end := t.index
		token = Ident_Token {
			span  = {start, end},
			value = t.data[start:end],
		}
	case '0' ..= '9':
		start := t.index
		num := con_number(t)
		end := t.index
		value, ok := strconv.parse_f32(num)
		assert(ok, fmt.tprint("Invalid number:", num))
		token = Number_Token {
			span  = {start, end},
			value = value,
		}
	case '"':
		start := t.index
		value := con_string(t)
		end := t.index
		token = String_Token {
			span  = {start, end},
			value = value,
		}
	case '=':
		token = Equal_Token {
			span = {t.index, t.index + 1},
		}
		consume_rune(t)
	case '[':
		token = Start_Arr_Token {
			span = {t.index, t.index + 1},
		}
		consume_rune(t)
	case ']':
		token = End_Arr_Token {
			span = {t.index, t.index + 1},
		}
		consume_rune(t)
	case utf8.RUNE_EOF:
		token = EOF_Token {
			span = {t.index, t.index},
		}
		consume_rune(t)
	case ',':
		token = Comma_Token {
			span = {t.index, t.index},
		}
		consume_rune(t)
	case '\n', ' ':
		consume_rune(t)
		// maybe it would be better to ignore whitespace in the beginning
		return get_token(t)
	case:
		token = Invalid_Token {
			span = {t.index, t.index},
		}
		consume_rune(t)
	}

	return
}


con_ident :: proc(t: ^Tokenizer) {
	for is_letter(t.current) || is_number(t.current) || t.current == '_' {
		consume_rune(t)
	}
}

con_string :: proc(t: ^Tokenizer) -> string {
	if strings.starts_with(t.data[t.index:], MULTILINE) {
		return con_multiline_string(t)
	}

	quote := t.current
	consume_rune(t)
	start := t.index
	end := t.index
	for t.current != utf8.RUNE_EOF {
		r := t.current
		end = t.index
		consume_rune(t)
		if r == '\n' || r < 0 {
			// just considering the string as finished
			break
		}
		if r == quote {
			break
		}
		if r == '\\' {
			scan_escape(t)
		}
	}

	return string(t.data[start:end])
}

con_number :: proc(t: ^Tokenizer) -> string {
	start := t.index
	with_decimal_point := false
	for t.current != utf8.RUNE_EOF {
		switch consume_rune(t) {
		case '0' ..= '9':
		// okay
		case '.':
			assert(!with_decimal_point, "already has a decimal point")
			with_decimal_point = true
			continue
		case:
			return t.data[start:t.index]
		}
	}

	return t.data[start:]
}

con_multiline_string :: proc(t: ^Tokenizer) -> string {
	// let's consume the first 3 quotes
	skip_runes(t, len(MULTILINE) - 1)
	start := t.index
	for t.current != utf8.RUNE_EOF {
		current := t.data[t.index:]
		if len(current) == 0 {
			break
		}
		switch {
		case strings.starts_with(current, MULTILINE):
			value := strings.trim(t.data[start:t.index], CUTSET)
			skip_runes(t, len(MULTILINE) - 1)
			return value
		case:
			consume_rune(t)
		}
	}

	return t.data[start:]
}


scan_escape :: proc(t: ^Tokenizer) -> bool {
	switch t.current {
	case '"', '\'', '\\', '/', 'b', 'n', 'r', 't', 'f':
		consume_rune(t)
		return true
	case 'u':
		// Expect 4 hexadecimal digits
		for i := 0; i < 4; i += 1 {
			r := consume_rune(t)
			switch r {
			case '0' ..= '9', 'a' ..= 'f', 'A' ..= 'F':
			// Okay
			case:
				return false
			}
		}
		return true
	case:
		// Ignore the next rune regardless
		consume_rune(t)
	}
	return false
}
