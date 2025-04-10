# 🐧 Terminal Fixer: Powered Linux Terminal Error Fixer

**A debugging assistant for WSL/Linux users.**

## Features

*   Auto capture last terminal error
*   One-command AI fixing (Google Gemini 1.5 Flash)
*   Local SQLite database caching
*   Custom error/solution management
*   Export/Import error database
*   Dockerized — no need to install Python
*   Ready for personal use and WSL users

## Installation

This tool provides two installation methods: direct clone installation and Docker installation.

### Method 1: Direct Clone Installation 

#### Requirements

- Python 3.6 or higher
- pip (Python package manager)
- bash shell

#### Installation Steps

1. Clone this repository:
```bash
git clone https://github.com/yourusername/terminal-fixer.git
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

4. Set up your Gemini API key:
   - Edit the `.env` file
   - Set `GEMINI_API_KEY=your_api_key_here`

### Method 2: Docker Installation (Recommended)

#### Requirements

- Docker
- Docker Compose
- bash shell

#### Installation Steps

1. Create working directory:
```bash
mkdir terminal-fixer; cd terminal-fixer
```

2. Download release assets:
```bash
curl -LO https://github.com/ddc0330/terminal-fixer/releases/download/v1.0.0/terminal-fixer-release.zip; unzip terminal-fixer-release.zip
```

3. Setup:
```bash
bash install.sh; source ~/.bashrc
```

4. Set up your API key:
   - `cp .env.example .env`
   - `vim .env`
   - Set `GEMINI_API_KEY=your_actual_key`

## Normal Workflow

1. Trigger an error (e.g., `ls /notfound`)
2. Fix it: `fixerror` (Detects last error, checks local database, queries Gemini if not cached, saves if confirmed)

## Available Commands

| Command             | Description                                      |
|----------------------|--------------------------------------------------|
| `fixerror --help`    | List all commands                                |
| `fixerror`           | Fix last error                                   |
| `fixerror --force`   | Force query Gemini even if cached                 |
| `fixerror --history` | View saved errors & solutions                     |
| `fixerror --add`     | Manually add an error/solution                   |
| `fixerror --delete`  | Delete an error from database                     |
| `fixerror --clear`   | Clear the entire database                         |
| `fixerror --search "keyword"` | Search error history                            |
| `fixerror --export json/md` | Export database to json/markdown                 |
| `fixerror --import file.json` | Import errors from json file                   |

## Notes

This tool is intended for personal or WSL users who frequently encounter terminal errors. It is lightweight, fully dockerized, and AI-powered. If you need to contribute, fork this repo and use `Dockerfile` + `Makefile` to build.
