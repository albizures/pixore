package traits

import rl "vendor:raylib"

Trait :: union {
	Pos,
	Size,
	Anchor,
	Border,
	Background,
	Margin,
	Padding,
}


Pos :: struct {
	value: rl.Vector2,
}

Size :: struct {
	value: rl.Vector2,
}

Anchor :: struct {
	value: rl.Vector2,
}


find_trait :: proc(traits: []Trait, $Type: typeid) -> Maybe(Type) {
	for trait in traits {
		#partial switch v in trait {
		case Type:
			return v
		}
	}

	return nil
}

expect_trait :: proc(
	traits: []Trait,
	$Type: typeid,
	msg: string,
	loc := #caller_location,
) -> Type {
	return find_trait(traits, Type).? or_else panic(msg, loc)
}
