package pixore

import "internals"


update_entities :: proc(pixore: ^internals.Pixore) {
	internals.update_spritor(pixore)
}
