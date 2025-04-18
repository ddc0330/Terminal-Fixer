# 🐧 Terminal Fixer: Powered Linux Terminal Error Fixer

**A debugging assistant for WSL/Linux users.**

## Features

*   Auto capture last terminal error
*   One-command AI fixing (Google Gemini 1.5 Flash)
*   Local SQLite database caching
*   Custom error/solution management
*   Export error database
*   Dockerized — no need to install Python
*   Ready for personal use and WSL users

## Installation

This tool provides two installation methods: direct clone installation and Docker installation.

### Method 1: Direct Clone Installation 

1. Clone this repository:
```bash
git clone https://github.com/ddc0330/terminal-fixer.git
cd terminal-fixer
```

2. Run the installation script:
```bash
bash install.sh
```

3. Reload bash configuration:
```bash
source ~/.bashrc
```

### Method 2: Docker Installation

1. Pull the Docker image:
```bash
docker pull ddc0330/terminal-fixer:latest
```

2. Run the installation script:
```bash
# For Linux
chmod +x release/wsl-install.sh
./release/wsl-install.sh
```

3. Reload bash configuration:
```bash
source ~/.bashrc
```

## Normal Workflow

1. Trigger an error (e.g., `ls /notfound`)
2. Fix it: `fixerror` (Detects last error, checks local database, queries Gemini if not cached, saves if confirmed)

## Available Commands

| Command             | Description                                      |
|----------------------|--------------------------------------------------|
| `fixerror -h, --help`    | List all commands                                |
| `fixerror`           | Fix last error                                   |
| `fixerror --force`   | Force query Gemini even if cached                 |
| `fixerror --history` | View saved errors & solutions                     |
| `fixerror --add`     | Manually add an error/solution                   |
| `fixerror --delete`  | Delete an error from database                     |
| `fixerror --clear`   | Clear the entire database                         |
| `fixerror --search "keyword"` | Search error history                            |
| `fixerror --export json/md` | Export database to json/markdown                 |
## Future Plans

1. **Import File Support**: Support importing error solutions from various file formats (JSON, YAML, CSV)

2. **Multi-Terminal Support**: Add support for different terminal emulators (zsh, fish, PowerShell)

3.  **Direct Solution Execution**: Enable one-click execution of Gemini's suggested solutions
