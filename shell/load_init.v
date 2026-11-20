module shell

import term
import model_type { Model }

pub fn load_init(version string, vcode string, history string, config string) Model {
	toml_doc := init_config(vcode, history, config)
	model := load_model(toml_doc) or { panic(err) }
	println('${term.bright_blue('━━━')} ${term.bold(term.bright_cyan('Vcode'))} ${term.dim(version)} ${term.bright_blue('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')}')
	println('${term.bright_blue('  ')}See ${term.dim('https://github.com/cryingn/vcode')}')
	println('${term.bright_blue('  ')}	if you like it, give it a star! ⭐')
	println('')
	println('${term.bright_blue('  ')}${term.bold('Model:')}  ${model.model_name}')
	println('${term.bright_blue('  ')}${term.bold('Help:')}')
	println('${term.bright_blue('  ')}	${term.bright_blue('/model')} to show model.')
	println('${term.bright_blue('  ')}	${term.bright_blue('/help')}  for available commands.')
	println('${term.bright_blue('  ')}	${term.bright_blue('/exit')}  to exit.')
	println('${term.bright_blue('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')}')
	println('')
	return model
}
