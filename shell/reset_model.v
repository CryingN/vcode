module shell

import toml
import model_type { Model }

pub fn reset_model(model_id string, config string) !Model {
	toml_doc := load_config(config)
	model := find_model(toml_doc, model_id) or {
		return error('shell/reset_model.v reset_model(): Failed to find model.')
	}
	return model
}

fn find_model(toml_doc string, model_id string) !Model {
	doc := toml.parse_text(toml_doc) or { panic(err) }
	mut model := Model{}
	model.prompt_template = '\${question}'
	for i := 0; ; i++ {
		if doc.value('model[${i}]') == toml_null {
			return error('shell/find_model.v find_model(): Failed to find default model.')
		}
		if to_load(doc.value('model[${i}].model_id')) == model_id {
			model.name = to_load(doc.value('model[${i}].name'))
			model.comment = to_load(doc.value('model[${i}].comment'))
			model.model_id = to_load(doc.value('model[${i}].model_id'))
			model.model_name = to_load(doc.value('model[${i}].model_name'))
			model.default_mode = to_load(doc.value('model[${i}].default_mode'))
			model.model_path = to_load(doc.value('model[${i}].model_path'))
			model.model_api = to_load(doc.value('model[${i}].model_api'))
			model.model_key = to_load(doc.value('model[${i}].model_key'))
			prompt := doc.value('model[${i}].prompt_template')
			if prompt != toml_null {
				model.prompt_template = prompt.string()
			}
			break
		}
	}
	return model
}
