module shell

import os
import tools
import model_type { SaveMessage }

pub fn print_history_file(history string, history_id string) ! {
	id := load_history_file(history, history_id)!
	sms := os.read_lines(os.join_path(history, id)) or {
                return error('shell/history.v load_history_file(): Failed to find history file.')
	}
	for sm in sms {
		trimmed := sm.trim_space()
		if trimmed == '' {
			continue
		}
		saved := json2.decode[SaveMessage](trimmed) or { continue }
		if saved.message_type in tools.effect_type {
			println(saved.chat_message)
		}
	}
}

