module shell

const help_file = $embed_file('../config/help.txt')

pub fn help(version string, config string) {
	println('config file: ${config}\n')
	println(help_file.to_string())
}
