module main

import os
import shell
import ai
import readline { Readline }

const version = 'v0.1.0'

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

	path := shorten_path(os.getwd())
	host_name := os.hostname() or { '' }
	mut model := shell.load_init(version, vcode, history, config)
	mut line := Readline{ skip_empty: true }
	mut file_path := ''

	if check_args(version, config, history) {
		return
	}

	for {
		prompt := '[${model.name}@${host_name} ${path}]> '
		data := (line.read_line(prompt) or { '\n' }).trim_space()
		if data == '/exit' {
			return
		} else if data == '/model' {
			shell.print_model_names(config) or { println('vcode.v main(): Not found model names.') }
		} else if data.starts_with('/model ') {
			model_id := data['/model '.len..]
			model = shell.reset_model(model_id, config) or { model }
		} else if data == '/plan' {
			model.default_mode = 'plan'
		} else if data == '/build' {
			model.default_mode = 'build'
		} else if data == '/history' {
			shell.print_history_names(history, config) or { println('vcode.v main(): Not found model names.') }
		} else if data.starts_with('/history ') {
			history_id := data['/history '.len..]
			file_path = shell.load_history_file(history, history_id) or {
				println('Error: Not found history file: ${history_id}.jsonl .')
				file_path
			}
		} else if data == '/up' {
			shell.up()
		} else if data == '/help' {
			shell.help(version, config)
		} else if data == '/new' {
			file_path = ''
		} else if data.starts_with('/') {
			shell.help(version, config)
			println('Error commond.')
		} else {
			file_path = ai.load_model(model, data, history, file_path, path)
		}
	}
}

fn check_args(version string, config string, history string) bool {
	args := os.args
	if args.len > 1 {
		if args[1] == 'up' {
			shell.up()
			return true
		} else if args[1] == 'help' {
			shell.help(version, config)
			return true
		} else if args[1] == 'history' {
			shell.print_history_names(history, config) or { println('vcode.v main(): Not found model names.') }
		}
	}
	return false
}
