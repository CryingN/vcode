# vcode

中文|[English](./README.md)

通用 Agent CLI（如 opencode）功能齐全，但工具协议复杂、系统提示词冗长，通常只有旗舰模型才能稳定驱动，每一轮对话的 token 开销也很可观。vcode 把交互协议压到极简：模型通过 `<|ls|>`、`<|grep|>`、`<|cat|>` 等纯文本命令按需获取上下文，完整规则只占十几行提示词，**7B 级量化小模型也能稳定使用**。

- **按需取上下文**：只取需要的目录列表与行数，不塞目录树，不整读文件
- **精简提示词**：全部规则十几行提示词，小模型也能正确输出
- **零运行依赖**：单一程序，配置内嵌，无需安装，首次运行自动释放
- **模型无关**：任何 OpenAI 兼容 API 均可接入（DeepSeek / Ollama / vLLM / llama.cpp server 等）

## 安装

### 方式一：直接下载二进制

到 [**Releases**](https://atomgit.com/cryingn/vcode/releases/release) 页面，按平台下载对应文件后运行

### 方式二：从源码编译

仅当你需要修改代码，或官方 Release 没有对应平台的二进制时：

```sh
git clone https://atomgit.com/cryingn/vcode
cd vcode
v vcode.v
```

编译需要 [V 编译器](https://github.com/vlang/v)。

## 快速开始

**第一次运行**会自动在 `~/.vcode/config.toml` 生成配置文件，填入 API 地址和密钥即可：

```toml
default_model_id = 'model-1'
max_history_len = 20

[[model]]
name = 'deepseek'
model_id = 'model-1'
model_name = 'deepseek-chat'
default_mode = 'plan'
model_api = 'https://api.deepseek.com/v1'
model_key = 'sk-xxx'
```

启动：

```sh
vcode
```

进入交互后直接说需求，例如：

```
帮我看看 src/ 下面有哪些文件，并概括 main.v 前 40 行做了什么
```

模型会自行组织 `<|ls|>`、`<|cat|>` 命令，只把需要的内容取回来，而不是把整个项目塞进上下文。

## 两种模式

| 模式 | 模型能做什么 | 适合场景 |
|------|--------------|----------|
| **plan**（默认） | 只能读：`ls` / `grep` / `cat` / `wc` / `find` | 读代码、摸清项目、出方案，安全可控 |
| **build** | 额外可写：`mkdir` / `write` | 确认方案后真正改代码(警告：当前未兼容回退功能，使用build前需做好备份工作) |

## 交互命令

| 命令 | 作用 |
|------|------|
| `/model` | 列出可用模型 |
| `/model <id>` | 切换模型 |
| `/plan` | 修改模型为plan模式 |
| `/build` | 修改模型为build模式 |
| `/history` | 列出历史会话 |
| `/history <id>` | 恢复会话（ID 为开始时间 `YYYYMMDD_HHmm`） |
| `/new` | 开始新会话 |
| `/up` | 自动更新 |
| `/help` | 帮助 |
| `/exit` | 退出 |

命令行直接调用：`vcode up`（更新）、`vcode help`、`vcode history`。

## 适用场景

- **SSH / 容器里快速摸代码**：不装 Node、不装 Python，一个二进制直接跑
- **内网离线**：对接 Ollama / llama.cpp 本地模型，私有代码不出内网
- **低配机器 + 小模型**：日常读码问答，token 花费为零
- **先侦查再动手**：用 plan 模式让模型出方案，确认后切 build 改代码

## 反馈

欢迎提交 Issue 与 PR。
