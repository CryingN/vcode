# vcode

[中文](./README_CN.md)|English

General-purpose Agent CLIs (such as opencode) are fully featured, but their tool protocols are complex and their system prompts are lengthy. Usually, only flagship models can drive them reliably, and the token overhead per conversation round is also considerable. vcode compresses the interaction protocol to a minimum: the model obtains context on demand through plain-text commands such as `<|ls|>`, `<|grep|>`, and `<|cat|>`, and the complete rules occupy only a dozen or so lines of prompt text. **Even 7B-level quantized small models can use it stably.**

- **Retrieve context on demand**: fetch only the needed directory listings and line counts; do not stuff in a directory tree, and do not read entire files
- **Minimal prompts**: all rules fit in a dozen or so lines of prompt text, so even small models can output correctly
- **Zero runtime dependencies**: a single program with embedded configuration, no installation required, automatically extracted on first run
- **Model-agnostic**: any OpenAI-compatible API can be connected (DeepSeek / Ollama / vLLM / llama.cpp server, etc.)

## Installation

### Option 1: Download the binary directly

Go to the [**Releases**](https://github.com/cryingn/vcode/releases/release) page, download the file for your platform, and run it.

### Option 2: Compile from source

Only if you need to modify the code, or if the official Release does not include a binary for your platform:

```sh
git clone https://github.com/cryingn/vcode
cd vcode
v vcode.v
```

Compilation requires the [V compiler](https://github.com/vlang/v).

## Quick Start

**The first run** automatically generates a configuration file at `~/.vcode/config.toml`. Fill in the API address and key:

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

Start:

```sh
vcode
```

After entering the interactive session, simply state your request, for example:

```
Help me see what files are under src/, and summarize what the first 40 lines of main.v do
```

The model will organize `<|ls|>` and `<|cat|>` commands on its own and retrieve only the needed content, instead of stuffing the entire project into the context.

## Two Modes

| Mode | What the model can do | Suitable scenarios |
|------|--------------|----------|
| **plan** (default) | Read-only: `ls` / `grep` / `cat` / `wc` / `find` | Reading code, understanding a project, producing plans; safe and controllable |
| **build** | Additionally writable: `mkdir` / `write` | Actually modifying code after confirming a plan (Warning: rollback functionality is not currently supported; back up before using build) |

## Interactive Commands

| Command | Purpose |
|------|------|
| `/model` | List available models |
| `/model <id>` | Switch models |
| `/plan` | Change the model to plan mode |
| `/build` | Change the model to build mode |
| `/history` | List historical sessions |
| `/history <id>` | Restore a session (ID is the start time `YYYYMMDD_HHmm`) |
| `/new` | Start a new session |
| `/up` | Automatically update |
| `/help` | Help |
| `/exit` | Exit |

Direct command-line invocation: `vcode up` (update), `vcode help`, `vcode history`.

## Suitable Scenarios

- **Quickly exploring code in SSH / containers**: no Node, no Python; run a single binary directly
- **Offline intranet**: connect to local Ollama / llama.cpp models; private code never leaves the intranet
- **Low-spec machines + small models**: everyday code reading and Q&A with zero token cost
- **Reconnaissance before action**: use plan mode to let the model produce a plan, then switch to build to modify code after confirmation

## Feedback

Issues and PRs are welcome.
