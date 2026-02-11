#+feature using-stmt

package tests
import "../pixore/config"
import "core:fmt"
import "core:log"
import "core:testing"

@(test)
test_number_property :: proc(t: ^testing.T) {
	using config
	parser := make_parser("test=123", context.temp_allocator)
	defer destroy_parser(&parser)

	parse(&parser)

	testing.expect(
		t,
		len(parser.errors) == 0,
		fmt.tprint("expect no errors, got:", len(parser.errors)),
	)

	value, ok := parser.values["test"].(f32)
	testing.expect(t, ok, "value should be f32")
	testing.expect_value(t, value, 123)
}

@(test)
test_string_property :: proc(t: ^testing.T) {
	using config
	parser := make_parser(`test="123"`, context.temp_allocator)
	defer destroy_parser(&parser)

	parse(&parser)

	testing.expect(
		t,
		len(parser.errors) == 0,
		fmt.tprint("expect no errors, got:", len(parser.errors)),
	)
	value, ok := parser.values["test"].(string)
	testing.expect(t, ok, "value should be string")
	testing.expect_value(t, value, "123")
}

@(test)
test_multiline_property :: proc(t: ^testing.T) {
	using config

	parser := make_parser(`test="""
123
345
"""
`, context.temp_allocator)
	defer destroy_parser(&parser)

	parse(&parser)

	testing.expect(
		t,
		len(parser.errors) == 0,
		fmt.tprint("expect no errors, got:", len(parser.errors)),
	)
	// testing.expect_value(t, parser.values["test"], "123\n345")
	value, ok := parser.values["test"].(string)
	testing.expect(t, ok, "value should be string")
	testing.expect_value(t, value, `123
345`)
}

@(test)
test_array_property :: proc(t: ^testing.T) {
	using config
	parser := make_parser(`test=[1, 2, 3,4]`, context.temp_allocator)
	defer destroy_parser(&parser)

	parse(&parser)

	value, ok := parser.values["test"].([dynamic]PrimitiveValue)
	testing.expect(t, ok, "value should be an array")

	for item, i in value {
		item_val, ok := item.(f32)
		testing.expect(t, ok, "value should be f32")
		testing.expect_value(t, item_val, f32(i + 1))
	}
}
