# ScriptsUI - Custom Asuswrt-Merlin router webpage for running predefined scripts and displaying results

This script has been tested on a GT-AX6000, running Asuswrt-Merlin 3004.388.8_4

## Overview:
- Script adds a Custom Webpage to the router WebUI
- Custom webpage allows for running and viewing results of predefined scripts
- Dynamic list of scripts to choose from on custom webpage, based on a user customizable JSON file

## Install:
*Requires Asuswrt-Merlin, JFFS enabled, and entware installed via AMTM*

SSH to the router and enter:

```Shell
/usr/sbin/curl /usr/sbin/curl --retry 3 "https://raw.githubusercontent.com/kstamand/scriptsui/master/scriptsui.sh" -o "/jffs/addons/scriptsui/scriptsui.sh" --create-dirs && chmod +x /jffs/addons/scriptsui/scriptsui.sh && sh /jffs/addons/scriptsui/scriptsui.sh -install
```

## Configuration:
1. Create one script file for each command you would like to run from the Custom Web page
   *Scripts are intended to be simple one line commands and have it's resuslts saved to "/www/user/scriptsui/results.js". Example:*
   ```Shell
   #!/bin/sh
   logger -t "scriptsui" "Running brctl_show script"  #write a syslog message for script run verification purposes
   brctl show > /www/user/scriptsui/results.js
   ```
   
2. From SSH session, modify /jffs/addons/scriptsui/scriptusi.json file and add one line for each script you have and want to be available in the WebUI.

   ```Shell
   [
    {"name":"brctl","path":"/jffs/addons/scriptsui/brctl_show.sh"},
    {"name":"ethctl","path":"/jffs/addons/scriptsui/ethctl_phymap.sh"}
   ]
   ```
   *Note - the last line in list* **SHOULD NOT**  *have a comma at the end*
  
3. Whenever you change the JSON file, we will need to update the file used by the Custom webpage, using the following command

   ```Shell
   /jffs/addons/scriptsui UpdateWeb
   ```
   
## Usage:
ScriptsUI is located under Tools menu (left side navigation in the routers WebUI. 

From that Tab, you will be presented with the list of Script Names + associated Script Path. Next to the Path on each row is a "Run Script" button.
When you click on a "Run Script" button, the page will refresh (spinning wheel), which will cause a launcher script to fire and run the full path of the selected script. 
Once that script completes, it will output the results to a results.js file, then be displayed in the Textbox of the current page under the list of scripts. 

![image](https://github.com/user-attachments/assets/04a24000-ad10-47aa-8386-6b77619029f4)
