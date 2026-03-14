package traits_test

import "core:testing"
import "../../traits"

@test
test_destroy_entities :: proc(t: ^testing.T) {
    world := traits.create(auto_load=true)
    
    e1 := traits.create(&world)
    traits.add(&world, e1, Position{1, 2})
    traits.add(&world, e1, Velocity{3, 4})
    
    e2 := traits.create(&world)
    traits.add(&world, e2, Position{5, 6})
    
    e3 := traits.create(&world)
    traits.add(&world, e3, Velocity{7, 8})
    
    traits.remove_entities_with(&world, Position)
    
    // e1 should be completely removed (no Velocity)
    _, has_vel1 := traits.get(&world, e1, Velocity)
    testing.expect(t, !has_vel1, "e1 should not have Velocity anymore")
    
    // e2 should be completely removed (no Position)
    _, has_pos2 := traits.get(&world, e2, Position)
    testing.expect(t, !has_pos2, "e2 should not have Position anymore")
    
    // e3 should still exist (no Position originally)
    _, has_vel3 := traits.get(&world, e3, Velocity)
    testing.expect(t, has_vel3, "e3 should still have Velocity")
}
