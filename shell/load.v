module shell

import os
import toml
import model_type { Model }

const config_text = $embed_file('../config/config.toml')
const toml_null = toml.Any(toml.Null{})

pub fn print_model_names(config string) ! {
	toml_doc := load_config(config)
	doc := toml.parse_text(toml_doc) or { panic(err) }
	models := doc.value('model').array()
	if models.len == 0 {
		println('shell/load.v print_model_names(): Failed to find models')
		return
	}
	for m in models {
		name := m.value('name').string()
		comment := m.value('comment').string()
		model_id := m.value('model_id').string()
		if comment == 'Any(toml.Null{})' {
			println('${name}\'s ID: ${model_id}\n')
		} else {
			println('${name}\'s ID: ${model_id}\nComment: ${comment}\n')
		}
	}
}

fn init_config(vcode string, history string, config string) string {
	mut result := config_text.to_string()
	if !os.exists(vcode) {
		os.mkdir(vcode) or {}
		os.mkdir(history) or {}
	}
	if os.exists(config) {
		result = os.read_file(config) or {
			panic('Failed to read config file: ${err}')
		}
	} else {
		os.write_file(config, result) or {
			panic('Failed to write config file: ${err}')
		}
	}
	return result
}

fn load_config(config string) string {
	mut result := config_text.to_string()
	if os.exists(config) {
		result = os.read_file(config) or {
			panic('Failed to read config file: ${err}')
		}
	} else {
		os.write_file(config, result) or {
			panic('Failed to write config file: ${err}')
		}
	}
	return result
}

fn to_load(toml_any toml.Any) string {
	if toml_any == toml_null {
		return ''
		//return none
	}
	return toml_any.string()
}

fn load_model(toml_doc string) !Model {
	doc := toml.parse_text(toml_doc) or { panic(err) }
	model_id := to_load(doc.value('main.default_model_id'))
	model := find_model(toml_doc, model_id) or { return error('shell/load.v load_model(): Failed to find default model') }
	return model
}

