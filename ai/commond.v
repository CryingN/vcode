module ai

import os
//import regex

struct GrepResult {
mut:
	lines []string
}

struct FindResult {
mut:
	files []string
}

fn ask_error(error_line string) string {
	println(error_line)
	return error_line
}

// ls ./path
fn ls_commond(args []string) !string {
	path := if args.len > 0 { args[0] } else { '.' }
	entries := os.ls(path) or { return error('Error: cannot list path "${path}".') }
	mut lines := []string{}
	for entry in entries {
		full := os.join_path(path, entry)
		if os.is_dir(full) {
			lines << ' [DIR] ${entry}'
			continue
		}
		if !os.is_file(full) {
			lines << ' [FILE] ${entry}'
			continue
		}
		data := os.read_bytes(full) or {
			lines << ' [FILE] ${entry}\n(unreadable)'
			continue
		}
		size := data.len
		if is_binary_content(data) {
			lines << ' [BIN] ${entry}\nsize: ${size}'
			continue
		}
		line_count := wc_file(full) or {
			lines << ' [FILE] ${entry}\n(unreadable)'
			continue
		}
		lines << ' [FILE] ${entry}\nsize: ${size} lines: ${line_count}'
	}
	return '<|ls ${path}|>\n' + lines.join('\n')
}

// bin check.
fn is_binary_content(data []u8) bool {
    if data.len == 0 { return false }

    // 常见二进制魔数（与 file 命令原理类似）
    if data.len >= 4 {
        if data[0] == 0x7f && data[1] == 0x45 && data[2] == 0x4c && data[3] == 0x46 {
            return true // ELF
        }
    }
    if data.len >= 2 && data[0] == 0x4d && data[1] == 0x5a {
        return true // PE (MZ)
    }
    if data.len >= 4 && data[0] == 0x89 && data[1] == 0x50 && data[2] == 0x4e && data[3] == 0x47 {
        return true // PNG
    }
    if data.len >= 3 && data[0] == 0xff && data[1] == 0xd8 && data[2] == 0xff {
        return true // JPEG
    }
    if data.len >= 4 && data[0] == 0x50 && data[1] == 0x4b && data[2] == 0x03 && data[3] == 0x04 {
        return true // ZIP
    }

    // 回退：采样前 4096 字节，不可打印比例 > 30% 判为二进制
    sample_len := if data.len < 4096 { data.len } else { 4096 }
    mut non_text := 0
    for i in 0 .. sample_len {
        b := data[i]
        // 允许 \t(9) \n(10) \r(13) 以及可打印 ASCII 32~126
        if !(b == 9 || b == 10 || b == 13 || (b >= 32 && b <= 126)) {
            non_text++
        }
    }
    return f64(non_text) / f64(sample_len) > 0.3
}


// grep ./path "keyword"
fn grep_commond(args []string) !string {
	if args.len < 2 {
		return error('Error: missing keyword. Got ${args.len} argument(s): ${args}.\nUsage: <|grep ./path [keyword]|>.')
	}
	path := args[0]
	keyword := args[1..].join(' ')
	mut result := &GrepResult{}
	os.walk(path, fn [keyword, mut result] (file string) {
		if !os.is_file(file) {
			return
		}
		content := os.read_file(file) or { return }
		for i, l in content.split_into_lines() {
			if l.contains(keyword) {
				result.lines << '${file}:${i + 1}:${l}'
			}
		}
	})
	return '<|grep ${path} ${keyword}|>\n' + result.lines.join('')
}

// cat ./file [x]-[y]
/*
fn cat_commond(args []string) !string {
	if args.len < 2 {
		return error('ai/commond.v cat_commond(): usage: <|cat ./file [10-20]|>')
	}
	path := args[0]
	line_range := args[1].split('-')
	x := line_range[0].int()
	y := line_range[1].int()
	content := os.read_file(path) or { return error('ai/commond.v cat_commond(): ${err}') }
	lines := content.split_into_lines()
	return '<|cat ${path} ${x}-${y}|>\n' + lines[x..y].join('\n')
}
*/

fn cat_commond(args []string) !string {
	if args.len < 2 {
		return error('Error: missing line range for "${args}". The range is required by the current implementation.\nUsage: <|cat ./file [x]-[y]|>')
	}
	path := args[0]
	line_range := args[1].split('-')
	if line_range.len < 2 {
		return error('Error: invalid range "${args[1]}". Expected format x-y, and x <= y.\nUsage: <|cat ./file [x]-[y]|>')
	}
	x := line_range[0].int()
	y := line_range[1].int()
	content := os.read_file(path) or { return error('Error: file "${path}" does not read.') }
	lines := content.split_into_lines()

	start := if x < 0 { 0 } else { x }
	end := if y > lines.len { lines.len } else { y }

	if start >= end {
		return error('Error: empty or out-of-bounds range ${x}-${y}; file "${path}" has ${lines.len} line(s).\nUsage: <|cat ./file [x]-[y]|>')
	}

	return '<|cat ${path} ${x}-${y}|>\n' + lines[start..end].join('\n')
}


// wc ./file
fn wc_commond(args []string) !string {
	if args.len < 1 {
		return error('Error: missing file path.')
	}
	path := args[0]
	line_count := wc_file(path)!
	return  '<|wc ${path}|>\n$line: ${line_count}'
}

fn wc_file(path string) !int {
	content := os.read_file(path) or { return error('Error: file "${path}" does not read.') }
	line_count := content.split_into_lines().len
	return line_count
}

// find ./ pattern
fn find_commond(args []string) !string {
	if args.len < 2 {
		return error('Error: missing pattern. Got ${args.len} argument(s): ${args}, provide a glob pattern, use * to match all files.\nUsage: <|find ./path [pattern]|>')
	}
	path := args[0]
	pattern := args[1]

	if !os.is_dir(path) {
		return error('Error: path "${path}" is not a directory.')
	}

	mut result := &FindResult{}
	/*
	mut re := regex.regex_opt(pattern) or { regex.RE{} }
	use_regex := pattern != '' && re.get_query() != ''

	os.walk(path, fn [pattern, use_regex, mut re, mut result] (file string) {
		name := os.file_name(file)
		matched := if pattern == '' {
			true
		} else if use_regex {
			mut rr := re
			rr.matches_string(name)
		} else {
			name.match_glob(pattern)
		}
		if !matched {
			return
		}
		kind := if os.is_dir(file) { ' [DIR]' } else { ' [FILE]' }
		result.files << '${kind} ${file}'
	})
	*/

	os.walk(path, fn [pattern, mut result] (file string) {
		name := os.file_name(file)
		matched := if pattern == '' { true } else { name.match_glob(pattern) }
		if !matched {
			return
		}
		kind := if os.is_dir(file) { '[DIR] ' } else { '[FILE]' }
		result.files << '${kind} ${file}'
	})

	if result.files.len == 0 {
		return '<|find ${path} ${pattern}|>\n(no match: no file under "${path}" matches pattern "${pattern}").'
	}
	return '<|find ${path} ${pattern}|>\n' + result.files.join('\n')
}

//mkdir ./
fn mkdir_commond(args []string) !string {
	if args.len < 1 {
                return error('Error: missing folder path.\nUsage: <|mkdir ./newfolder|>')
        }
	path := args[0]
	if os.exists(path) {
                return error('Error: path "${path}" already exists.')
        }
	os.mkdir(path) or {
		return error('Error: failed to create folder "${path}": ${err}.')
	}

        return '<|mkdir ${path}|>\ncreated folder ${path}'
}

//write ./ '''<| '''|>
fn write_commond(args []string, lines []string, i int) !string {
	if args.len < 1 {
                return error('Error: missing file path.\nUsage: <|write ./file [x]-[y]|> or <|write ./newfile|>')
        }
	mut content := []string{}
	mut opened := false
	mut closed := false
	for j := i + 1; j < lines.len; j++ {
                marker := lines[j].trim_space()
                if !opened {
                        if marker.starts_with('```<') {
                                opened = true
                        }
                        continue
                }
                if marker.ends_with('```|>') {
                        closed = true
                        break
                }
                content << lines[j]
        }
        if !opened || !closed {
                return error('Error: missing or unterminated content block.\nExpected:\n```<|\ncontent\n```|>')
        }

	if args.len == 2 {
		// 1. <|write ./file x-y|>
		return write_commond_revised(args[0], args[1], content)!
	}
	// 2.<|write ./file|>
	return write_commond_new(args[0], content)!
}

//write ./ [start]-[end]
fn write_commond_revised(path string, arg string, content []string) !string {
	line_range := arg.split('-')
	if line_range.len < 2 {
                        return error('Error: invalid range "${arg}". Expected x-y.\nUsage: <|write ${path} [x]-[y]|>')
        }
	x := line_range[0].int()
	if x < 0 {
		return error('Error: invalid start line ${x}. Line numbers are 0-based and must be >= 0, but got a negative value "${line_range[0]}".')
	}
	y := line_range[1].int()
	if y < x {
		return error('Error:invalid line range "${arg}": start line ${x} is greater than end line ${y}. The range must satisfy x <= y.')
	}
	old_file := os.read_lines(path) or {
		return error('Error: file "${path}" does not exist.')
	}
	if y > old_file.len {
		return error('Error:end line ${y} is out of bounds: file "${path}" has only ${old_file.len} line(s), so the valid end line is at most ${old_file.len}.')
	}
	mut new_file := old_file[..x].clone()
	new_file << content
	new_file << old_file[y..]
	os.write_lines(path, new_file) or {
                        return error('Error: failed to write file "${path}": ${err}.')
        }
	return '<|write ${path} ${x}-${y}|>\nwrited lines ${x}-${y} of ${path} with ${content.len} line(s).'
}


//write ./
fn write_commond_new(path string, content []string) !string {
        if os.exists(path) {
                return error('Error: file "${path}" already exists, refuse to overwrite.')
        }
        dir := os.dir(path)
        if dir != '' && !os.exists(dir) {
                return error('Error: parent directory "${dir}" does not exist, cannot create file "${path}".')
        }
        os.write_lines(path, content) or {
                return error('Error: failed to create file "${path}": ${err}.')
        }
        return '<|write ${path}|>\nCreated file ${path} with ${content.len} line(s).'
}


