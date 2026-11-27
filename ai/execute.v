module ai

const ai_commonds = [
	'ls',
	'grep',
	'cat',
	'wc',
	'find',
	'mkdir',
	'write',
]

pub fn execute(answer string, default_mode string) !string {
	lines := answer.split('\n')
	for i, raw_line in lines {
		line := raw_line.trim_space()
		comm, args := check_commond(line) or {
			continue
		}
		match comm {
			'ls' { return ls_commond(args) or { err.str() } }
			'grep' { return grep_commond(args) or { err.str() } }
			'cat' { return cat_commond(args) or { err.str() } }
			'wc' { return wc_commond(args) or { err.str() } }
			'find' { return find_commond(args) or { err.str() } }
			'mkdir' {
				if default_mode == 'build' {
					return mkdir_commond(args) or { err.str() }
				}
			}
			'write' {
				if default_mode == 'build' {
					return write_commond(args, lines, i) or { err.str() }
				}
			}
			else { continue }
		}
	}
	return error('ai/execute.v execute(): Unexpected commond.')
}

fn check_commond(line string) !(string, []string) {
	if !line.starts_with('<|') {
		return error('ai/execute.v check_commond(): Not commond.')
	}
	end := line.index('|>') or { 0 }
	if end == 0 {
		return error('ai/execute.v check_commond(): Not commond.')
	}
	inner := line[2..end]
	for comm in ai_commonds {
		if !inner.starts_with(comm + ' ') { continue }
		arg := inner[comm.len + 1..].trim_space().split(' ')
		return comm, arg
	}
	return '', []string{}
}
