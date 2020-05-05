#!/bin/sh

cd "$(dirname "${BASH_SOURCE[0]}")"
sudo mkdir -p "/Library/Application Support/Trojan/"
sudo cp ProxyConfHelper "/Library/Application Support/Trojan/"
sudo chown root:admin "/Library/Application Support/Trojan/ProxyConfHelper"
sudo chmod +s "/Library/Application Support/Trojan/ProxyConfHelper"

echo done
