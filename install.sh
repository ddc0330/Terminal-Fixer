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
    echo "run: sudo apt update && sudo apt install -y python3 python3-pip"
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

# Create fixerror script
cat > "$SCRIPT_DIR/fixerror" << 'EOF'
#!/bin/bash

# 獲取腳本所在目錄的絕對路徑
REAL_PATH=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$REAL_PATH")

# 檢查是否有提供 API 金鑰
if [ "$1" == "--api-key" ] && [ -n "$2" ]; then
    export GEMINI_API_KEY="$2"
    shift 2
fi

# 執行 fixerror.py
cd "$SCRIPT_DIR" && python3 "$SCRIPT_DIR/fixerror.py" "$@"
EOF

# Make fixerror script executable
chmod +x "$SCRIPT_DIR/fixerror"

# Ensure fixerror.py has execution permission
chmod +x "$SCRIPT_DIR/fixerror.py"

# Create symbolic link to /usr/local/bin
if [ -d "/usr/local/bin" ]; then
    sudo ln -sf "$SCRIPT_DIR/fixerror" /usr/local/bin/fixerror
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
    ln -sf "$SCRIPT_DIR/fixerror" "$HOME/.local/bin/fixerror"
    echo "✅ Global command 'fixerror' created in ~/.local/bin"
fi

# ============ Step 4: Set up .env file ============
echo "Setting up .env file..."

# Ask for API key
echo "Please enter your Google Gemini API key:"
read -r API_KEY

if [ -z "$API_KEY" ]; then
    echo "⚠️ No API key provided. You can set it later by editing the .env file."
else
    echo "✅ API key received."
fi

# Create .env file
if [ ! -f "$SCRIPT_DIR/.env" ]; then
    if [ -f "$SCRIPT_DIR/.env.example" ]; then
        cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env"
        echo "✅ .env file created from .env.example"
    else
        echo "⚠️ .env.example file not found, creating .env file manually"
        echo "GEMINI_API_KEY=" > "$SCRIPT_DIR/.env"
    fi
fi

# Update API key in .env file
if [ -n "$API_KEY" ]; then
    # Check if GEMINI_API_KEY already exists in .env
    if grep -q "GEMINI_API_KEY=" "$SCRIPT_DIR/.env"; then
        # Replace existing API key
        sed -i "s/GEMINI_API_KEY=.*/GEMINI_API_KEY=$API_KEY/" "$SCRIPT_DIR/.env"
    else
        # Add API key to .env
        echo "GEMINI_API_KEY=$API_KEY" >> "$SCRIPT_DIR/.env"
    fi
    echo "✅ API key set in .env file"
    
    # Also set it as an environment variable for the current session
    export GEMINI_API_KEY="$API_KEY"
    echo "✅ API key set as environment variable for the current session"
else
    echo "⚠️ Please edit $SCRIPT_DIR/.env file to set your Gemini API key"
fi

# ============ Step 5: Create log directory ============
echo "Creating log directory..."
mkdir -p "$SCRIPT_DIR/logs"
echo "✅ Log directory created"

echo "===== Installation Complete ====="
echo "Please run 'source $SHELL_RC' or restart your terminal to use the 'fixerror' command."
echo "Before first use, make sure you have set your Gemini API key in the .env file."