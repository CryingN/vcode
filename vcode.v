module main

import os
import shell
import ai
import tools
import readline { Readline }

const version = 'v0.1.2'

fn shorten_path(path string) string {
	home := os.home_dir()
	if path.starts_with(home) {
		return path.replace(home, '~')
	}
	return path
}

fn main() {
	home_dir := os.home_dir()
	vcode := os.join_path(home_dir, '.vcode')
	config := os.join_path(vcode, 'config.toml')
	history := os.join_path(vcode, 'history')

	mut path := shorten_path(os.getwd())
	mut model := shell.load_init(version, vcode, history, config)
	mut line := Readline{ skip_empty: true }
	mut file_path := ''

	if check_args(version, config, history) {
		return
	}

	for {
		prompt := '[${model.name}@${model.default_mode} ${path}]> '
		data := (line.read_line(prompt) or { '\n' }).trim_space()
		if data == '/exit' {
			return
		} else if data == '/model' {
			shell.print_model_names(config) or { println('vcode.v main(): Not found model names.') }
			continue
		} else if data.starts_with('/model ') {
			model_id := data['/model '.len..]
			model = shell.reset_model(model_id, config) or { model }
			continue
		} else if data == '/plan' {
			model.default_mode = 'plan'
			continue
		} else if data == '/build' {
			model.default_mode = 'build'
			continue
		} else if data == '/history' {
			shell.print_history_names(history, config) or { println('vcode.v main(): Not found model names.') }
			continue
		} else if data.starts_with('/history ') {
			history_id := data['/history '.len..]
			file_path = shell.load_history_file(history, history_id) or {
				println('Error: Not found history file: ${history_id}.jsonl .')
				file_path
			}
			continue
		} else if data.starts_with('/print ') {
			history_id := data['/history '.len..]
			shell.print_history_file(history, history_id) or {
				println('Error: Not found history file: ${history_id}.jsonl .')
			}
			continue
		} else if data == '/up' {
			shell.up()
			continue
		} else if data == '/help' {
			shell.help(version, config)
			continue
		} else if data == '/new' {
			file_path = ''
			continue
		} else if data.starts_with('/') {
			shell.help(version, config)
			println('Error commond.')
			continue
		} else if data == 'cd' || data == 'cd ~'  {
			os.chdir(os.home_dir()) or {
				println('Error: cannot cd to home: ${err}')
				continue
			}
			path = shorten_path(os.getwd())
			continue
		} else if data.starts_with('cd ') && data.split(' ').len == 2 {
			mut target := data['cd '.len..].trim_space()
			if target.starts_with('~') {
				target = os.home_dir() + target[1..]
			}
			if os.is_dir(target) {
				os.chdir(target) or {
					println('Error: cannot cd to ${target}: ${err}')
					continue
				}
				path = shorten_path(os.getwd())
				continue
			}
		} else {
			first_word := data.split(' ')[0]
			if os.exists_in_system_path(first_word) {
				ret := tools.system(data)
				if ret != 0 {
					println('Command exited with code ${ret}')
				}
				continue
			}
		}
		file_path = ai.load_model(model, data, history, file_path, path)
	}
}

fn check_args(version string, config string, history string) bool {
	args := os.args
	if args.len > 2 {
		if args[1] == 'print' {
			history_id := args[2].trim_space()
			shell.print_history_file(history, history_id) or { println('Error: Not found history file: ${history_id}.jsonl .') }
			return true
		}
	}
	if args.len > 1 {
		if args[1] == 'up' {
			shell.up()
			return true
		} else if args[1] == 'help' {
			shell.help(version, config)
			return true
		} else if args[1] == 'history' {
			shell.print_history_names(history, config) or { println('vcode.v main(): Not found model names.') }
			return true
		}
	}
	return false
}
