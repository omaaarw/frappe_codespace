#!/bin/bash

set -e

# --------------------------
# Check if Bench already exists
# --------------------------
if [[ -d "/workspaces/frappe_codespace/frappe-bench/apps/frappe" ]]; then
    echo "Bench already exists, skipping init"
    exit 0
fi

# --------------------------
# Cleanup old git (if any)
# --------------------------
rm -rf /workspaces/frappe_codespace/.git

# --------------------------
# Node Setup (NVM)
# --------------------------
echo "Setting up Node.js..."
source /home/frappe/.nvm/nvm.sh
nvm install 24
nvm alias default 24
nvm use 24
echo "nvm use 24" >> ~/.bashrc
npm install -g yarn

# --------------------------
# Python 3.10 Setup (pyenv)
# --------------------------
echo "Setting up Python 3.10..."
pyenv install -s 3.10.14
pyenv global 3.10.14
echo "Using Python version: $(python3 --version)"

# --------------------------
# Workspace & Virtualenv
# --------------------------
cd /workspace
uv venv env --seed --python python3.10
source env/bin/activate
echo "Virtualenv using Python: $(python --version)"

# --------------------------
# Bench Init (Frappe v15)
# --------------------------
echo "Initializing Frappe Bench v15..."
bench init \
  --frappe-branch version-15 \
  --ignore-exist \
  --skip-redis-config-generation \
  frappe-bench

cd frappe-bench

# --------------------------
# Configure database & Redis for containers
# --------------------------
echo "Configuring database and Redis hosts..."
bench set-mariadb-host mariadb
bench set-redis-cache-host "redis://redis-cache:6379"
bench set-redis-queue-host "redis://redis-queue:6379"
bench set-redis-socketio-host "redis://redis-queue:6379"

# Remove Redis from Procfile (for local development)
sed -i '/redis/d' ./Procfile

# --------------------------
# Create New Site
# --------------------------
echo "Creating new site: dev.localhost..."
bench new-site dev.localhost \
  --db-root-username root \
  --db-root-password 123 \
  --admin-password admin \
  --mariadb-user-host-login-scope='%'

# --------------------------
# Final Bench Setup
# --------------------------
bench --site dev.localhost set-config developer_mode 1
bench --site dev.localhost clear-cache
bench use dev.localhost

echo "Frappe v15 setup complete!"
