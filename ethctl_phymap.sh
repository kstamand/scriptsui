#!/bin/sh
logger -t "ScriptsUI" "Running ethctl_phymap script"
ethctl phy-map > /www/user/scriptsui/results.js
