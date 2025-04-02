# 🐧 Terminal Fixer: Powered Linux Terminal Error Fixer

**A debugging assistant for WSL/Linux users.**

## ✨ Features

*   Auto capture last terminal error
*   One-command AI fixing (Google Gemini 1.5 Flash)
*   Local SQLite database caching
*   Custom error/solution management
*   Export/Import error database
*   Dockerized — no need to install Python
*   Ready for personal use and WSL users


## 🟣 Requirements

*   Docker
*   Docker Compose
*   Google Gemini API Key


## 🟣 Installation (Recommended)

1.  Create working directory: `mkdir terminal-fixer; cd terminal-fixer`
2.  Download Release Assets: `curl -LO https://github.com/ddc0330/terminal-fixer/releases/download/v1.0.0/terminal-fixer-release.zip; unzip terminal-fixer-release.zip`
3.  Setup: `bash install.sh; source ~/.bashrc`  (or `source ~/.zshrc`)
4.  Setup your API Key:
    *   `cp .env.example .env`
    *   `vim .env`
    *   Set `GEMINI_API_KEY=your_actual_key`

## 🟣 Normal Workflow

1.  Trigger an error (e.g., `ls /notfound`)
2.  Fix it: `fixerror` (Detects last error, checks local database, queries Gemini if not cached, saves if confirmed)


## 🟣 Available Commands

| Command             | Description                                      |
|----------------------|--------------------------------------------------|
| `fixerror --help`    | List all commands                                |
| `fixerror`           | Fix last error                                   |
| `fixerror --refresh` | Force query Gemini even if cached                 |
| `fixerror --history` | View saved errors & solutions                     |
| `fixerror --add`     | Manually add an error/solution                   |
| `fixerror --delete`  | Delete an error from database                     |
| `fixerror --clear`   | Clear the entire database                         |
| `fixerror --search "keyword"` | Search error history                            |
| `fixerror --export json/md` | Export database to json/markdown                 |
| `fixerror --import file.json` | Import errors from json file                   |

## 🟣 Notes

This tool is intended for personal or WSL users who frequently encounter terminal errors. It is lightweight, fully dockerized, and AI-powered.  If you need to contribute, fork this repo and use `Dockerfile` + `Makefile` to build.
