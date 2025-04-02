#!/bin/bash

echo "===== Fixerror Installer ====="

ALIAS_CMD="alias fixerror='docker-compose run --rm fixerror'"

# 檢測 shell
if [ -n "$ZSH_VERSION" ]; then
    SHELL_RC=~/.zshrc
else
    SHELL_RC=~/.bashrc
fi

# ============ Step 1: 安裝 alias ============

if grep -q "alias fixerror=" "$SHELL_RC"; then
    echo "❌ Alias already exists in $SHELL_RC"
else
    echo "$ALIAS_CMD" >> "$SHELL_RC"
    echo "✅ Alias added to $SHELL_RC"
fi

# ============ Step 2: 安裝 Error Logger Block ============

if grep -q "# ===== Terminal Fixer Error Logger =====" "$SHELL_RC"; then
    echo "❌ Error Logger already exists in $SHELL_RC"
else
    cat << 'EOF' >> "$SHELL_RC"

# ===== Terminal Fixer Error Logger =====

# Project Path
export FIXER_PROJECT_DIR="$HOME/terminal-fixer"

# log DIR
export FIXER_LOG_DIR="\$FIXER_PROJECT_DIR/logs"
mkdir -p "\$FIXER_LOG_DIR"

# Makes this variable accessible to all subshells and functions
export FIXER_LOG_FILE="\$FIXER_LOG_DIR/last_error.log"

function record_last_command() {
    export LAST_COMMAND="\$BASH_COMMAND"
}

function capture_error() {
    local exit_status=\$?
    if [ \$exit_status -ne 0 ]; then
        local error_output=\$(eval "\$LAST_COMMAND" 2>&1 > /dev/null)
        {
            echo "[Command]      \$LAST_COMMAND"
            echo "[Exit Code]    \$exit_status"
            echo "[Error Output] \$error_output"
        } > "\$FIXER_LOG_FILE"
    fi
}

trap 'record_last_command' DEBUG
trap 'capture_error' ERR

export PATH="\$HOME/.local/bin:\$PATH"

# ===== Terminal Fixer End =====
EOF
    echo "✅ Error Logger block added to $SHELL_RC"
fi

# ============ Step 3: .env

if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo "✅ .env file created from .env.example"
    else
        echo "⚠️  No .env.example found, please create .env manually."
    fi
else
    echo "✅ .env already exists"
fi

echo "Done! Please run: source $SHELL_RC"
