#!/bin/sh
logger -t "scriptsui" "Running ethctl_phymap script"
ethctl phy-map > /www/user/scriptsui/results.js
