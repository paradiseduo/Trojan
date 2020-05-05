#!/bin/sh

cd "$(dirname "${BASH_SOURCE[0]}")"
privoxyVersion=3.0.28.static
mkdir -p "$HOME/Library/Application Support/Trojan/privoxy-$privoxyVersion"
cp -f privoxy "$HOME/Library/Application Support/Trojan/privoxy-$privoxyVersion/"
cp -f libpcre.1.dylib "$HOME/Library/Application Support/Trojan/privoxy-$privoxyVersion/"
rm -f "$HOME/Library/Application Support/Trojan/privoxy"
ln -s "$HOME/Library/Application Support/Trojan/privoxy-$privoxyVersion/privoxy" "$HOME/Library/Application Support/Trojan/privoxy"
ln -sf "$HOME/Library/Application Support/Trojan/privoxy-$privoxyVersion/libpcre.1.dylib" "$HOME/Library/Application Support/Trojan/libpcre.1.dylib"
echo done
