module ai

import os
import json2
import strings
import time
import tools
import net.http
import model_type {
	Model,
	ChatMessage,
	SaveMessage,
}

// import v_llama_cpp

const plan_mode = $embed_file('../config/plan.txt')
const build_mode = $embed_file('../config/build.txt')

struct ChatRequest {
	model    string
	messages []ChatMessage
	stream   bool
}

struct RespMessage {
	role    string
	content string
}

struct Choice {
	message RespMessage
}

struct ChatResponse {
	choices []Choice
}

struct StreamDelta {
	content string
}

struct StreamChoice {
	delta StreamDelta
}

struct StreamResponse {
	choices []StreamChoice
}

pub fn load_model(model Model, user_input string, history string, path string, message_path string) string {
	mut file_path := os.join_path(history, path)
	mut prompts := []ChatMessage{}
	mut mode_content := ''
	match model.default_mode {
		'plan' {
			mode_content = plan_mode.to_string()
			prompts << ChatMessage {
				role:	'system'
				content:mode_content
			}
		}
		'build' {
			mode_content = build_mode.to_string()
			prompts << ChatMessage {
				role:	'system'
				content:mode_content
			}
		}
		else {}
	}
	if path == '' {
		file_path = os.join_path(history, '${time.now().custom_format('YYYYMMDD_HHmm')}.jsonl')
		os.write_file(file_path, '') or {
			println('Error: Failed to create new JSON file storage.')
		}
	} else {
		for chat_message in load_history(file_path) {
			prompts << chat_message
		}
	}
	prompts << ChatMessage {
		role:		'user'
		content:	model.prompt_template.replace('\${question}', user_input)
	}
	tools.save_message(file_path, prompts[prompts.len - 1], mode_content, '', 'question') or {}
	if os.exists(model.model_path) {
		/*w
		ctx := v_llama_cpp.ez_load_model(model_path, -1, 2048, 512) or {
			println('load model failed.')
			return
		}
		input_buffer := os.input('>')
		prompt := '<start_of_turn>user\n${input_buffer}<end_of_turn>\n<start_of_turn>model\n'
		print('gemma: ')
		ctx.ez_response(prompt, 512, 256, print_token) or { println('response failed.') }
		print('\n')
		*/
	} else {
		for {
			answer := ask(model.model_api, model.model_key, model.model_name, prompts) or { ask_error('ai/load_model.v load_model(): Failed to asked the model') }
			prompts << ChatMessage {
				role:		'assistant'
				content:	answer
			}
			ret := execute(answer, model.default_mode) or {
				tools.save_message(file_path, prompts[prompts.len - 1], mode_content, '', 'answer') or {}
				return os.file_name(file_path)
			}
			message_type := handle(ret)
			tools.save_message(file_path, prompts[prompts.len - 1], mode_content, message_path , message_type) or {}
			println(ret)
			prompts << ChatMessage {
				role:		'user'
				content:	ret
			}
			tools.save_message(file_path, prompts[prompts.len - 1], mode_content, message_path, message_type) or {}
		}
	}
	return os.file_name(file_path)
}

fn ask(model_api string, model_key string, model_name string, prompts []ChatMessage) !string {
	url := model_api.trim_right('/') + '/chat/completions'
	payload := ChatRequest{
		model:    model_name
		messages: prompts
		stream:   true
	}
	body := json2.encode(payload, time_as_unix: true)

	mut header := http.new_header()
	header.add(.authorization, 'Bearer ${model_key}')
	header.add(.content_type, 'application/json')

	mut buffer := strings.new_builder(1024)
	shared full := []string{}

	_ := http.fetch(
		url:         url
		method:      .post
		data:        body
		header:      header
		on_progress: fn [mut buffer, shared full] (req &http.Request, chunk []u8, read_so_far u64) ! {
			buffer.write(chunk)!
			mut content := buffer.str()
			for {
				idx := content.index('\n') or { break }
				line := content[..idx].trim_space()
				content = content[idx + 1..]

				if line == '' { continue }
				if line == 'data: [DONE]' { break }
				if line.starts_with('data: ') {
					json_str := line[6..]
					resp := json2.decode[StreamResponse](json_str) or { continue }
					if resp.choices.len > 0 {
						piece := resp.choices[0].delta.content
						if piece != '' {
							print(piece)
							full << piece
						}
					}
				}
			}
			buffer.go_back(buffer.len)
			buffer.write_string(content)
		}
	)!

	println('')
	rlock full {
		return full.join('')
	}
}

fn handle(ret string) string {
	if ret.starts_with('<|ls ') ||
	   ret.starts_with('<|grep ') ||
	   ret.starts_with('<|cat ') ||
	   ret.starts_with('<|wc ') ||
	   ret.starts_with('<|find ') {
		return 'read'
	}
	return 'error'
}

pub fn load_history(file_path string) []ChatMessage {
	content := os.read_file(file_path) or {
		return []ChatMessage{}
	}
	mut result := []ChatMessage{}

	for line in content.split_into_lines() {
		trimmed := line.trim_space()
		if trimmed == '' {
			continue
		}
		saved := json2.decode[SaveMessage](trimmed) or { continue }
		if saved.message_type in tools.effect_type {
			result << saved.chat_message
		}
	}
	return result
}

