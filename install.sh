#!/bin/bash

echo "===== Terminal Fixer Installer ====="

# Get the absolute path of the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SHELL_RC="$HOME/.bashrc"

# ============ Step 1: Install Dependencies ============
echo "Installing dependencies..."
if command -v pip &> /dev/null; then
    pip install -r "$SCRIPT_DIR/requirements.txt"
    echo "✅ Dependencies installed successfully"
else
    echo "❌ pip command not found, please install Python and pip first"
    exit 1
fi

# ============ Step 2: Set Environment Variables ============
echo "Setting environment variables..."

# Set project path and log directory
if ! grep -q "FIXER_PROJECT_DIR" "$SHELL_RC"; then
    cat << EOF >> "$SHELL_RC"

# ===== Terminal Fixer =====
export FIXER_PROJECT_DIR="$SCRIPT_DIR"
export FIXER_LOG_DIR="\$FIXER_PROJECT_DIR/logs"
export FIXER_LOG_FILE="\$FIXER_LOG_DIR/last_error.log"

# Create log directory
mkdir -p "\$FIXER_LOG_DIR"

# Record the last executed command
function record_last_command() {
    export LAST_COMMAND="\$BASH_COMMAND"
}

# Capture errors
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
# ===== Terminal Fixer End =====
EOF
    echo "✅ Environment variables and error logging functions added to $SHELL_RC"
else
    echo "✅ Environment variables and error logging functions already exist in $SHELL_RC"
fi

# ============ Step 3: Create Global Command ============
echo "Creating global command..."

# Ensure fixerror.py has execution permission
chmod +x "$SCRIPT_DIR/fixerror.py"

# Create symbolic link to /usr/local/bin
if [ -d "/usr/local/bin" ]; then
    sudo ln -sf "$SCRIPT_DIR/fixerror.py" /usr/local/bin/fixerror
    echo "✅ Global command 'fixerror' created"
else
    echo "⚠️ /usr/local/bin directory not found, trying ~/.local/bin"
    
    # Create ~/.local/bin directory if it doesn't exist
    mkdir -p "$HOME/.local/bin"
    
    # Add to PATH if not already added
    if ! grep -q "export PATH=\$PATH:\$HOME/.local/bin" "$SHELL_RC"; then
        echo "export PATH=\$PATH:\$HOME/.local/bin" >> "$SHELL_RC"
        echo "✅ Added ~/.local/bin to PATH"
    fi
    
    # Create symbolic link
    ln -sf "$SCRIPT_DIR/fixerror.py" "$HOME/.local/bin/fixerror"
    echo "✅ Global command 'fixerror' created in ~/.local/bin"
fi

# ============ Step 4: Set up .env file ============
echo "Setting up .env file..."

if [ ! -f "$SCRIPT_DIR/.env" ]; then
    if [ -f "$SCRIPT_DIR/.env.example" ]; then
        cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env"
        echo "✅ .env file created from .env.example"
        echo "⚠️ Please edit $SCRIPT_DIR/.env file to set your Gemini API key"
    else
        echo "⚠️ .env.example file not found, please create .env file manually"
    fi
else
    echo "✅ .env file already exists"
fi

# ============ Step 5: Create log directory ============
echo "Creating log directory..."
mkdir -p "$SCRIPT_DIR/logs"
echo "✅ Log directory created"

echo "===== Installation Complete ====="
echo "Please run 'source $SHELL_RC' or restart your terminal to use the 'fixerror' command."
echo "Before first use, make sure you have set your Gemini API key in the .env file." 