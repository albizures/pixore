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

	// connections
	Parent2,
	Child,

	// flags
	Is_Mouse_Interactive,
}

Rect :: rl.Rectangle

Parent2 :: distinct Entity_Id

Child :: distinct Entity_Id

Position :: enum {
	Relative,
	Absolute,
}

Pos :: distinct rl.Vector2

Size :: distinct rl.Vector2

Anchor :: distinct rl.Vector2

find_trait :: proc {
	find_trait_by_id,
	find_trait_in,
}

find_trait_by_id :: proc(world: World, entity_id: Entity_Id, $Type: typeid) -> Maybe(Trait) {
	traits := get_traits(world, entity_id)

	return find_trait_in(traits, Type)
}

find_trait_in :: proc(traits: []Trait, $Type: typeid) -> Maybe(Type) {
	for trait in traits {
		#partial switch v in trait {
		case Type:
			return v
		}
	}

	return nil
}

expect_trait :: proc {
	expect_trait_by_id,
	expect_trait_in,
}

expect_trait_by_id :: proc(
	world: World,
	entity_id: Entity_Id,
	$Type: typeid,
	msg: string,
	loc := #caller_location,
) -> Type {
	traits := get_traits(world, entity_id)
	return expect_trait_in(traits, Type, msg, loc)
}

expect_trait_in :: proc(
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

has_trait :: proc(traits: []Trait, $Type: typeid) -> bool {
	return find_trait(traits, Type) != nil
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
