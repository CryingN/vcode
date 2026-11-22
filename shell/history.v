module shell

import os
import toml
import model_type { SaveMessage }

pub fn print_history_names(history string, config string) ! {
        files := os.ls(history) or {
                return error('shell/history.v print_history_names(): Failed to read history directory.')
        }
	mut names := files.filter(it.ends_with('.jsonl'))
        names.sort()
        if names.len == 0 {
                println('Not found history files.')
                return
        }
        for name in names {
		id := name.replace('.jsonl', '')
		full_path := os.join_path(history, name)
		lines := os.read_lines(full_path) or {
			println('${id}\t<读取失败>')
			continue
		}
		if lines.len > 0 {
			first_line := lines[0]
			save_message := json2.decode[SaveMessage](first_line) or { continue }
			save_content := save_message.chat_message.content.runes()
			max_len := find_max_history_len(config)
			if save_content.len > max_len {
				println('content:${save_content[..max_len].string()}...')
			} else {
				println('content:${save_content.string()}')
			}
		}
		println('id:${id}\n')
        }
}

pub fn load_history_file(history string, history_id string) !string {
	mut id := history_id.trim_space()
        if id.ends_with('.jsonl') {
                id = id.replace('.jsonl', '')
        }
        file_path := os.join_path(history, '${id}.jsonl')
        if !os.exists(file_path) {
                return error('shell/history.v load_history_file(): Failed to find history file.')
        }
	return '${id}.jsonl'
}

fn find_max_history_len(config string) int {
        toml_doc := load_config(config)
        doc := toml.parse_text(toml_doc) or { panic(err) }
        max_history_len := doc.value('main.max_history_len')
	return max_history_len.int()
}

