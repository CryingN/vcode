module tools

import os

fn C.system(cmd &char) int

pub fn system(cmd string) int {
	wrapped := wrap_cmd(cmd)
	ret := C.system(wrapped.str)

	$if !windows {
		if ret == -1 {
			return -1
		}
		if (ret & 0x7f) != 0 {
			return 128 + (ret & 0x7f)
		}
		return (ret >> 8) & 0xff
	} $else {
		return ret
	}
}

fn wrap_cmd(cmd string) string {
	$if windows {
		// Windows：cmd /c 会读取 AutoRun，基本继承用户配置
		return 'cmd /c "${cmd}"'
	} $else {
		escaped := cmd.replace('"', '\\"')
		// 优先 bash：-i 强制交互式，加载 ~/.bashrc，别名生效
		if os.exists('/bin/bash') || os.exists('/usr/bin/bash') {
			return 'bash -i -c "${escaped}"'
		}
		if os.exists('/bin/zsh') || os.exists('/usr/bin/zsh') {
		    return 'zsh -i -c "${escaped}"'
		}
		if os.exists('/usr/bin/fish') {
		    return 'fish -i -c "${escaped}"'
		}
		return cmd
	}
}

