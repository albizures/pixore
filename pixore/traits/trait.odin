package traits

import rl "vendor:raylib"

// Basically a component but with a short name
Trait :: union #no_nil {
	Rec,
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

Rec :: struct {
	value: rl.Rectangle,
}

Parent :: struct {
	traits: []Trait,
}

Position :: enum {
	Relative,
	Absolute,
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

	value, ok := anchor_trait.?
	anchor := value.value if ok else {0, 0}

	return anchor
}
