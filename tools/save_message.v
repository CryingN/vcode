module tools

import os
import json2
import model_type {
	ChatMessage,
	SaveMessage,
}

pub fn save_message(file_path string, chat_message ChatMessage, mode_content string, message_path string, message_type string) ! {
	mut f := os.open_append(file_path)!
	defer { f.close() }
	sm := SaveMessage{
		mode_content:	mode_content
		message_path:	message_path
		message_type:	message_type
		chat_message:	chat_message
	}
	line := json2.encode(sm)
	f.writeln(line)!
}
