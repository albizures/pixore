package events

import "core:fmt"
import "core:log"
import "core:mem"

Store :: struct {
	// Points to [dynamic]T
	listeners: rawptr,
}

Dispatcher :: struct {
	// A map where each Event_Type has a list of procedures
	stores:    map[typeid]^Store,
	allocator: mem.Allocator,
}

create :: proc(allocator := context.allocator) -> Dispatcher {
	return Dispatcher {
		allocator = allocator, //
		stores    = make(map[typeid]^Store, allocator),
	}
}

on :: proc(dispatcher: ^Dispatcher, $Data: typeid, listener: proc(data: Data)) {
	store := dispatcher.stores[Data]
	if store == nil {
		listeners := new([dynamic]proc(data: Data), dispatcher.allocator)
		listeners^ = make([dynamic]proc(data: Data), dispatcher.allocator)
		store = new(Store, dispatcher.allocator)
		store.listeners = rawptr(listeners)

		log.error("no listeners for event type: ", store)
		dispatcher.stores[Data] = store
	}
	listeners := (^[dynamic]proc(data: Data))(store.listeners)
	append(listeners, listener)
}

fire :: proc(dispatcher: Dispatcher, data: $Data) {
	ti := typeid_of(type_of(data))
	store := dispatcher.stores[ti]
	if store == nil {
		info := type_info_of(ti)
		panic(fmt.tprintln("no listeners for event type", info.id))
	}

	listeners := (^[dynamic]proc(data: Data))(store.listeners)

	for listener in listeners^ {
		listener(data)
	}
}
