# TinyTerm
By Oscar Frias - September 2016
www.oscarfrias.com

__TinyTerm__, a quick script to create a terminal-like interface that allows the user to control a [tinyG](http://synthetos.myshopify.com/products/tinyg) connected via Serial to the computer. It provides a textArea to show the history of the communication between the tinyG and the computer, and a textfield to allow the user to inject GCode commands or tinyG commands to the tinyG on the fly.

TinyTerm starts by loading an init.json file from the /data folder. This JSON file contains all the desired init settings for the tinyG. For a complete list of commands and settings, please take a look at the [tinyG Wiki](https://github.com/synthetos/TinyG/wiki/TinyG-Configuration-for-Firmware-Version-0.97). The JSON file needs to have a JSONArray named _"commands"_ contained in a JSONObject:

```css
{
  "commands":[
    { "command": value },
    { "command": value },
    { "command": value }
  ]
}
```

You can have as many commands as necessary. Some of our init files have dozens of commands. It all depends on how many axes and inputs you want to initialize with this file.

The GUI is created with the [ControlP5](http://www.sojamo.de/libraries/controlP5/) library by [Sojamo](https://github.com/sojamo), so make sure you have this library installed before running this script.

Cheers!<br>
@\_frix_
