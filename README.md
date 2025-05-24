# Nockchain Wallet & Node Launcher

Easy scripts to build, generate wallets, and launch Nockchain nodes.


---

### $NOCK Details
Mining starts soon check countdown https://nockstats.com/

Total Supply: 4,294,967,296$NOCK Fully mineable token supply

$NOCK is used to pay for blockspace on Nockchain.


## Features

- **Node Launcher**  
  Loads wallet keys, allows port customization, updates Makefile, and launches leader & follower nodes in detached `screen` sessions.

---

## Hardware Requirements

> Hardware requirements are highly speculative since mainnet launch details are not finalized.

| RAM      | CPU              | Disk           |
|----------|------------------|----------------|
| 64 GB    | 6 cores or higher | 100-200 GB SSD |

- More CPU cores = higher hashrate = better mining chances  
- These specs are for testnet; mainnet requirements may vary.

---

## Prerequisites

- Linux/macOS with:
  - `screen` installed
  - `make` and build tools
  - `bash`

---

## Usage

## Quick Start

```bash
sudo apt-get -qq update && sudo apt-get upgrade -y
sudo apt -qq install curl -y
```

### Run Nockchain Script
Clone the repository:

```bash
curl -O https://raw.githubusercontent.com/codedialect/nockchain/main/node_launcher.sh
chmod +x node_launcher.sh
./node_launcher.sh

```


### Run Multiminer Script
Clone the repository:

```bash
curl -O https://raw.githubusercontent.com/codedialect/nockchain/main/multi_miner.sh
chmod +x multi_miner.sh
./multi_miner.sh

```

- If this is your first run, it will build Nockchain in a detached `screen` session.
- Rerun using this ``` ./node_launcher.sh ``` after screen gets closed to generate wallet keys and launch miner.

- Enter a public key.
- Optionally customize P2P and API ports (default 3005/3006).

---

Make sure these ports match those you set when launching thode (defaults: `3005` for P2P, `3006` for API).

---

## Useful Commands

### Wallet Commands

> **Important:** After every terminal restart, run these commands before using wallet commands to avoid `command not found` errors:

```bash
cd nockchain
export PATH="$PATH:$(pwd)/target/release"
```
---

### Remove NockChain
```bash
sudo rm -rf nock-chain .nockapp .nockbuild_done nockchain
```
Also delete all the relative screen with below commands

### Tmux Commands

> To avoid overlapping screens, minimize or close your current screen before switching.

- Reattach leader logs screen:

```bash
tmux attach -t miner
```

- Minimize (detach) current screen session:

```
CTRL + B, then D
```

- List all screen sessions:

```bash
tmux ls
```

- Stop node inside a screen (graceful shutdown):

```
CTRL + C
```

- Kill and remove a screen session (replace `NAME` with session name):

```bash
tmux kill-session -t miner
```

---

## Contributing

Contributions, issues, and feature requests are welcome!  
Feel free to fork and submit pull requests.
Discord: https://discord.gg/4w7cRka4

---

*Happy mining with Nockchain!* 
