package pixore

import "base"
import "editors/sprite"

update_editors :: proc(pixore: ^base.Pixore) {
	sprite.update(pixore)
}
