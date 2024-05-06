#!/bin/bash

# Startup script that installs 
# Git, NodeJS, make, and gcc-c++
# clones the website code, installs dependencies, 
# forwards port 80 to 3000, 
# and starts the Node app with pm2.

# Install Git
echo "Installing Git"
yum update -y
yum install git make -y

# Install NodeJS
echo "Installing NodeJS"
curl -sL https://rpm.nodesource.com/setup_20.x | sudo -E bash -

# Clone app code
echo "Cloning website"
mkdir -p /app
cd /app
git clone https://github.com/h1dd3nsn1p3r/ismt-ebistro-app.git .

# Install dependencies
echo "Installing dependencies"
npm install

# Install & use pm2 to run Node app in background
echo "Installing & starting pm2"
npm install pm2@latest -g
pm2 start "npm run dev" --name "ebistroApp" --watch