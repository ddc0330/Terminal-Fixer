#!/bin/bash

echo "===== Terminal Fixer WSL Installer ====="

# Get the absolute path of the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORK_DIR="$HOME/terminal-fixer"
SHELL_RC="$HOME/.bashrc"

# ============ Step 1: Check Dependencies ============
echo "Checking dependencies..."

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker first:"
    echo "curl -fsSL https://get.docker.com -o get-docker.sh"
    echo "sudo sh get-docker.sh"
    exit 1
fi

# Check Docker Compose
if ! command -v docker compose &> /dev/null; then
    echo "❌ Docker Compose not found. Installing Docker Compose..."
    sudo apt-get update
    sudo apt-get install -y docker-compose-plugin
    if ! command -v docker compose &> /dev/null; then
        echo "❌ Failed to install Docker Compose. Please install it manually:"
        echo "sudo apt-get update && sudo apt-get install -y docker-compose-plugin"
        exit 1
    fi
fi

echo "✅ Dependencies checked successfully"

# ============ Step 2: Create Working Directory ============
echo "Creating working directory..."
mkdir -p "$WORK_DIR"
mkdir -p "$WORK_DIR/logs"
touch "$WORK_DIR/logs/last_error.log"
touch "$WORK_DIR/fixerror.db"
chmod 666 "$WORK_DIR/logs/last_error.log"
chmod 666 "$WORK_DIR/fixerror.db"
echo "✅ Working directory created at $WORK_DIR"

# ============ Step 3: Add Error Capture to .bashrc ============
echo "Adding error capture to .bashrc..."

# Check if error capture is already added
if ! grep -q "# ===== Terminal Fixer Error Capture =====" "$SHELL_RC"; then
    cat << 'EOF' >> "$SHELL_RC"

# ===== Terminal Fixer Error Capture =====
export FIXER_PROJECT_DIR="$HOME/terminal-fixer"
export FIXER_LOG_DIR="$FIXER_PROJECT_DIR/logs"
export FIXER_LOG_FILE="$FIXER_LOG_DIR/last_error.log"

# Record the last executed command
function record_last_command() {
    export LAST_COMMAND="$BASH_COMMAND"
}

# Capture errors
function capture_error() {
    local exit_status=$?
    if [ $exit_status -ne 0 ]; then
        local error_output=$(eval "$LAST_COMMAND" 2>&1 > /dev/null)
        {
            echo "[Command]      $LAST_COMMAND"
            echo "[Exit Code]    $exit_status"
            echo "[Error Output] $error_output"
        } > "$FIXER_LOG_FILE"
    fi
}

trap 'record_last_command' DEBUG
trap 'capture_error' ERR
# ===== Terminal Fixer Error Capture End =====
EOF
    echo "✅ Error capture added to .bashrc"
else
    echo "✅ Error capture already exists in .bashrc"
fi

# ============ Step 4: Create Docker Compose File ============
echo "Creating Docker Compose file..."
cat > "$WORK_DIR/docker-compose.yml" << EOF
services:
  fixerror:
    image: ddc0330/terminal-fixer:latest
    volumes:
      - $WORK_DIR/logs:/app/logs
      - $WORK_DIR/fixerror.db:/app/fixerror.db
    environment:
      - GEMINI_API_KEY=\${GEMINI_API_KEY}
      - FIXER_PROJECT_DIR=/app
      - FIXER_LOG_DIR=/app/logs
      - FIXER_LOG_FILE=/app/logs/last_error.log
      - DB_PATH=/app/fixerror.db
    working_dir: /app
    entrypoint: ["python3", "/app/fixerror.py"]
    restart: unless-stopped
EOF
echo "✅ Docker Compose file created"

# ============ Step 5: Create Global Command ============
echo "Creating global command..."

# Create fixerror script
cat > "$WORK_DIR/fixerror" << EOF
#!/bin/bash

# Get the absolute path of the script directory
SCRIPT_DIR="$WORK_DIR"

# Check if API key is provided
if [ "\$1" == "--api-key" ] && [ -n "\$2" ]; then
    export GEMINI_API_KEY="\$2"
    shift 2
fi

# Execute the command using Docker
cd "\$SCRIPT_DIR" && docker compose -f "\$SCRIPT_DIR/docker-compose.yml" run --rm fixerror "\$@"
EOF

# Make fixerror script executable
chmod +x "$WORK_DIR/fixerror"

# Create symbolic link to /usr/local/bin
if [ -d "/usr/local/bin" ]; then
    sudo ln -sf "$WORK_DIR/fixerror" /usr/local/bin/fixerror
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
    ln -sf "$WORK_DIR/fixerror" "$HOME/.local/bin/fixerror"
    echo "✅ Global command 'fixerror' created in ~/.local/bin"
fi

# ============ Step 6: Set up .env file ============
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
echo "GEMINI_API_KEY=$API_KEY" > "$WORK_DIR/.env"
echo "✅ .env file created"

# ============ Step 7: Pull Docker Image ============
echo "Pulling Docker image..."
docker pull ddc0330/terminal-fixer:latest
echo "✅ Docker image pulled successfully"

# ============ Step 8: Start Docker Service ============
echo "Starting Docker service..."
cd "$WORK_DIR" && docker compose up -d
echo "✅ Docker service started"

echo "===== Installation Complete ====="
echo "Please run 'source $SHELL_RC' or restart your terminal to use the 'fixerror' command."
echo "Before first use, make sure you have set your Gemini API key in the .env file."