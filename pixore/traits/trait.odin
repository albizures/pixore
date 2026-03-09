package traits

import rl "vendor:raylib"

// Basically a component but with a short name
Trait :: union #no_nil {
	Rect,
	Pos,
	Size,
	Anchor,
	Border,
	Background,
	Margin,
	Padding,
	Position,
	Parent,
}

Rect :: rl.Rectangle

Parent :: struct {
	traits: []Trait,
}

Position :: enum {
	Relative,
	Absolute,
}

Pos :: distinct rl.Vector2

Size :: distinct rl.Vector2

Anchor :: distinct rl.Vector2


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

find_trait_ptr :: proc(traits: []Trait, $Type: typeid) -> Maybe(^Type) {
	for &trait in traits {
		#partial switch &v in trait {
		case Type:
			return &v
		}
	}

	return nil
}

expect_trait_ptr :: proc(
	traits: []Trait,
	$Type: typeid,
	msg: string,
	loc := #caller_location,
) -> ^Type {
	return find_trait_ptr(traits, Type).? or_else panic(msg, loc)
}

// anchor should always be defaulted into {0, 0}
get_anchor :: proc(traits: []Trait) -> rl.Vector2 {
	anchor_trait := find_trait(traits, Anchor)

	anchor, ok := anchor_trait.?

	return rl.Vector2(anchor)
}
