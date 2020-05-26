#!/bin/sh


launchctl unload "$HOME/Library/LaunchAgents/MacOS.Trojan.local.plist"
launchctl load "$HOME/Library/LaunchAgents/MacOS.Trojan.local.plist"
