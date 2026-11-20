module shell

import os
import time
import net.http
import sync

const git_urls = [
	'https://atomgit.com/cryingn/vcode/releases/download/release/',
	'https://github.com/cryingn/vcode/releases/download/release/',
]

struct ProbeResult {
	base string
	ms   int
}

pub fn up() {
	exe_path := os.executable()
	new_path := '${exe_path}.${time.unix_now()}'
	mut exe_name := ''
	$if windows {
		exe_name = 'vcode.exe'
	} $else {
		exe_name = 'vcode.x86_64'
	}
	fastest_base := select_fastest_url(git_urls, exe_name)
	if fastest_base == '' {
		println('All update sources unreachable by probe, fallback to default.')
		return
	}
	download_url := fastest_base + exe_name

	http.download_file(download_url, new_path) or {
		println('Update failed. ${err}')
		return
	}

	$if !windows {
		mut mode := 0o755
		if orig := os.stat(exe_path) {
			mode = orig.mode & 0o7777
		}
		os.chmod(new_path, mode) or {
			println('Cannot set executable permission: ${err}.')
			return
		}
	}

	os.mv(new_path, exe_path) or {
		println('Cannot move current binary: ${err}.')
		return
	}
	println('Update complete. Please restart the program to use.')
}

fn probe_url(url string) int {
	sw := time.new_stopwatch()
	resp := http.head(url) or { return -1 }
	if resp.status_code != 200 {
		return -1
	}
	return int(sw.elapsed().milliseconds())
}

fn select_fastest_url(base_urls []string, exe_name string) string {
    if base_urls.len == 0 {
        return ''
    }
    if base_urls.len == 1 {
        return base_urls[0]
    }

    ch := chan ProbeResult{cap: base_urls.len}

    mut wg := sync.new_waitgroup()
    for base in base_urls {
        wg.add(1)
        spawn fn [base, exe_name] (mut wg sync.WaitGroup, ch chan ProbeResult) {
            defer { wg.done() }
            url := base + exe_name
            ms := probe_url(url)
            if ms < 0 {
                return
            }
            ch <- ProbeResult{
                base: base
                ms:   ms
            }
        }(mut wg, ch)
    }

    spawn fn (mut wg sync.WaitGroup, ch chan ProbeResult) {
        wg.wait()
        ch.close()
    }(mut wg, ch)

    mut best_base := ''
    mut best_ms := 1 << 30
    for {
        res := <-ch or { break }
        if res.ms < best_ms {
            best_ms = res.ms
            best_base = res.base
        }
    }
    return best_base
}

