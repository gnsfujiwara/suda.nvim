## Contributing Guide

Thank you for taking the time to contribute to **suda.nvim**. The goal of this document is to describe how to get involved and what is expected throughout the contribution process.

### Reporting Bugs

When you encounter a bug, please include the following details to help us reproduce and fix the issue quickly:

1. The full output of `:checkhealth suda`.
2. A clear description of the expected behaviour versus what actually happened.
3. Step-by-step reproduction instructions.
4. Information about your environment (Neovim version, operating system, sudo implementation, and anything else that might be relevant).

### Suggesting Enhancements

Improvement ideas are always welcome. Explain the problem your idea solves or the benefit it provides. Share concrete examples when possible so we can better understand the workflow you have in mind.

### Pull Requests

Before opening a pull request:

1. Fork the repository and branch from `main`.
2. Implement your changes following the existing code style (see `stylua.toml`).
3. Update or add tests where appropriate.
4. Update the documentation (`README.md`, `doc/suda.txt`, examples, etc.) if behaviour changes.
5. Run the available quality checks (`make format`, `make lint`, `make test`).
6. Write clear, descriptive commit messages.

Pull requests should remain focused. If you plan a large refactor or feature, open an issue first so we can align on scope before any code is written.

### Development Environment

Minimum tooling:

- [stylua](https://github.com/JohnnyMorganz/StyLua) for formatting (`cargo install stylua`)
- [luacheck](https://github.com/mpeterv/luacheck) for linting (`luarocks install luacheck`)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) for running the automated tests

Clone the repository, install the tools above, and you are ready to start hacking.

### Running Tests

Execute the test suite with:

```bash
make test
```

Ensure `plenary.nvim` is available on your runtime path. The test runner automatically uses `tests/minimal_init.lua`.

### Formatting and Linting

- `make format` runs stylua over the Lua sources.
- `make lint` executes luacheck with the configuration defined in `.luacheckrc`.

Please run both commands before submitting a pull request.

### Project Structure

- `lua/suda/` — core modules (`config`, `core`, `init`, `util`, `health`)
- `plugin/` — plugin entry point that defines user commands
- `doc/` — Vim help documentation
- `examples/` — sample configurations
- `tests/` — automated tests

### Coding Style

- Prefer small, focused functions with descriptive names.
- Use LuaLS annotations (`---@param`, `---@return`) where they add clarity.
- Add comments only when the behaviour is not immediately clear from the code itself.
- Follow the existing modular structure; avoid mixing unrelated responsibilities.

### Code Review

All pull requests receive a review. Be prepared to discuss your approach and make adjustments based on feedback. We aim for constructive, respectful communication throughout the process.

### Code of Conduct

We expect all contributors to treat each other with respect. Disagreements happen—resolve them calmly and focus on improving the project for everyone.

### Questions?

Open an issue if you are unsure about anything. We appreciate every contribution and are happy to help you get started.
