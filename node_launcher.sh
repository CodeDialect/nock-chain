#!/bin/bash
set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}
 
 ______              _         _                                             
|  ___ \            | |       | |                   _                        
| |   | |  ___    _ | |  ____ | | _   _   _  ____  | |_   ____   ____  _____ 
| |   | | / _ \  / || | / _  )| || \ | | | ||  _ \ |  _) / _  ) / ___)(___  )
| |   | || |_| |( (_| |( (/ / | | | || |_| || | | || |__( (/ / | |     / __/ 
|_|   |_| \___/  \____| \____)|_| |_| \____||_| |_| \___)\____)|_|    (_____)                   
                                
                                                                                                                                
${YELLOW}                      :: Powered by Noderhunterz ::
${NC}"

echo -e "${CYAN}
🚀 NOCKCHAIN NODE LAUNCHER
---------------------------------------${NC}"
#!/bin/bash

set -e

# ========== COLOR CODES ==========
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"

# ========== PATHS ==========
BINARY_PATH="$HOME/nockchain/target/release/nockchain"
LOG_PATH="$HOME/nockchain/build.log"
# --- Root setup ---
if [ "$(id -u)" -eq 0 ]; then
  echo -e "\e[33m>> Running as root. Updating system and installing sudo...\e[0m"
  apt-get update && apt-get upgrade -y

  if ! command -v sudo &> /dev/null; then
    apt-get install sudo -y
  fi
fi

if [ ! -f "$BINARY_PATH" ]; then
    echo -e "${YELLOW}>> Nockchain not built yet. Starting Phase 1 (Build)...${RESET}"

    echo -e "${CYAN}>> Installing system dependencies...${RESET}"
    sudo apt-get update && sudo apt-get upgrade -y
    sudo apt install -y curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libclang-dev llvm-dev

    if ! command -v cargo &> /dev/null; then
        echo -e "${CYAN}>> Installing Rust...${RESET}"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi

    echo -e "${CYAN}>> Cloning Nockchain repo and starting build...${RESET}"
    rm -rf nockchain .nockapp
    git clone https://github.com/zorp-corp/nockchain
    cd nockchain
    cp .env_example .env

    echo -e "${CYAN}>> Launching build in screen session 'nockbuild' and logging to build.log...${RESET}"
    screen -dmS nockbuild bash -c "cd \$HOME/nockchain && make install-hoonc && make build && make install-nockchain-wallet && make install-nockchain | tee build.log"

    echo -e "${GREEN}>> Build started in screen session 'nockbuild'.${RESET}"
    echo -e "${YELLOW}>> To monitor build: screen -r nockbuild${RESET}"
    echo -e "${YELLOW}>> Re-run this script when build completes.${RESET}"
    exit 0
fi

# ========== PHASE 2: VERIFY BUILD ==========
if [ -f "$BINARY_PATH" ]; then
    echo -e "${GREEN}>> Build detected. Continuing Phase 2 (Wallet + Miner Setup)...${RESET}"
else
    echo -e "${RED}!! ERROR: Build not completed or failed.${RESET}"
    echo -e "${YELLOW}>> Check build log: $LOG_PATH${RESET}"
    echo -e "${YELLOW}>> Resume screen: screen -r nockbuild${RESET}"
    exit 1
fi

cd "$HOME/nockchain"
export PATH="$PATH:$(pwd)/target/release"
export PATH="$HOME/.cargo/bin:$PATH"

echo "export PATH=\"\$PATH:$(pwd)/target/release\"" >> ~/.bashrc

# ========== WALLET ==========
echo -e "${YELLOW}\nDo you want to import an existing wallet? (y/n)${RESET}"
read -rp "> " use_existing

if [[ "$use_existing" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Place 'keys.export' in this directory and press Enter to import.${RESET}"
    read -rp "Continue when ready..."
    nockchain-wallet import-keys --input keys.export
else
    echo -e "${CYAN}>> Generating new wallet...${RESET}"
    nockchain-wallet keygen
    echo -e "${CYAN}>> Backing up keys to 'keys.export'...${RESET}"
    nockchain-wallet export-keys
fi

# ========== PUBLIC KEY ==========
echo -e "${YELLOW}Enter your PUBLIC KEY to use for mining:${RESET}"
read -rp "> " MINING_KEY

if [[ -z "$MINING_KEY" ]]; then
    echo -e "${RED}!! ERROR: Public key cannot be empty.${RESET}"
    exit 1
fi

# Update .env
sed -i "s/^MINING_PUBKEY=.*/MINING_PUBKEY=$MINING_KEY/" .env

# ========== FIREWALL ==========
echo -e "${CYAN}>> Configuring firewall...${RESET}"
sudo ufw allow ssh
sudo ufw allow 22
sudo ufw allow 3005/tcp
sudo ufw allow 3006/tcp
sudo ufw allow 3005/udp
sudo ufw allow 3006/udp
sudo ufw --force enable

# Ask user which mode to run miner1 in
echo -e "${YELLOW}Choose how to run miner1:
1) Without peers
2) With recommended peers${RESET}"
read -rp "Enter 1 or 2: " MINER_MODE

mkdir -p miner1 && cd miner1
NCK_DIR="$HOME/nockchain"
NCK_BIN="$NCK_DIR/target/release/nockchain"

# Check miner binary exists and is executable
if [[ ! -x "$NCK_BIN" ]]; then
  echo -e "${RED}Error: Miner binary not found or not executable at $NCK_BIN${RESET}"
  exit 1
fi

sudo sysctl -w vm.overcommit_memory=1
export PATH="$HOME/.cargo/bin:$PATH"

# ========== Run miner1 with tmux ==========
if [[ "$MINER_MODE" == "1" ]]; then
  tmux new-session -d -s miner1 "bash -c '$NCK_BIN --mining-pubkey $MINING_KEY --mine; echo Miner exited with \$?; read -p \"Press enter to close...\"'"
  echo -e "${GREEN}>> Miner1 started without peers in tmux session 'miner1'.${RESET}"

elif [[ "$MINER_MODE" == "2" ]]; then
  tmux new-session -d -s miner1 "bash -c '$NCK_BIN --mine --mining-pubkey $MINING_KEY \
  --peer /ip4/95.216.102.60/udp/3006/quic-v1 \
  --peer /ip4/65.108.123.225/udp/3006/quic-v1 \
  --peer /ip4/65.109.156.108/udp/3006/quic-v1 \
  --peer /ip4/65.21.67.175/udp/3006/quic-v1 \
  --peer /ip4/65.109.156.172/udp/3006/quic-v1 \
  --peer /ip4/34.174.22.166/udp/3006/quic-v1 \
  --peer /ip4/34.95.155.151/udp/30000/quic-v1 \
  --peer /ip4/34.18.98.38/udp/30000/quic-v1 \
  --peer /ip4/96.230.252.205/udp/3006/quic-v1 \
  --peer /ip4/94.205.40.29/udp/3006/quic-v1 \
  --peer /ip4/159.112.204.186/udp/3006/quic-v1 \
  --peer /ip4/217.14.223.78/udp/3006/quic-v1; echo Miner exited with \$?; read -p \"Press enter to close...\"'"
  echo -e "${GREEN}>> Miner1 started with peers in tmux session 'miner1'.${RESET}"
else
  echo -e "${RED}Invalid MINER_MODE choice. Exiting...${RESET}"
  exit 1
fi

# Tmux usage instructions
echo -e "${CYAN}To attach to a tmux session: tmux attach -t miner1 (or minerX)${RESET}"
echo -e "${CYAN}To detach from tmux: Ctrl + b then d${RESET}"
echo -e "${CYAN}To list tmux sessions: tmux ls${RESET}"

# Ask to start more miners
echo -e "${YELLOW}Do you want to run multiple miners? Enter number (e.g. 3 for 3 miners total), or 1 to skip:${RESET}"
read -rp "> " NUM_MINERS

# ========== Multiple miners setup ==========
if [[ "$NUM_MINERS" =~ ^[2-9][0-9]*$ ]]; then
  for i in $(seq 2 "$NUM_MINERS"); do
    MINER_DIR="$NCK_DIR/miner$i"
    echo -e "${CYAN}>> Setting up miner$i...${RESET}"
    mkdir -p "$MINER_DIR"

    tmux new-session -d -s miner$i "bash -c 'cd $MINER_DIR && $NCK_BIN --mining-pubkey $MINING_KEY --mine; echo Miner $i exited with \$?; read -p \"Press enter to close...\"'"
    echo -e "${GREEN}>> Miner $i started in tmux session 'miner$i'.${RESET}"
  done
else
  echo -e "${CYAN}>> Skipping multiple miners setup.${RESET}"
fi

echo -e "${GREEN}All requested miners are now running.${RESET}"
echo -e "${CYAN}To attach to a tmux session: tmux attach -t miner1 (or minerX)${RESET}"
echo -e "${CYAN}To detach from tmux: Ctrl + b then d${RESET}"
echo -e "${CYAN}To list tmux sessions: tmux ls${RESET}"

