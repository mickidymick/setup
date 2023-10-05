#!/usr/bin/env bash

sudo apt -y install shellcheck
sudo apt -y install npm
sudo npm cache clean -f
sudo npm install -g n
sudo n stable
sudo npm i -g bash-language-server
