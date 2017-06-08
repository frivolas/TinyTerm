# TinyTerm
By Oscar Frias - September 2016
www.oscarfrias.com

__TinyTerm__, a quick [Processing](www.processing.org) script to create a terminal-like interface that allows the user to control a [tinyG](http://synthetos.myshopify.com/products/tinyg) connected via Serial to the computer. It provides a textArea to show the history of the communication between the tinyG and the computer, and a textfield to allow the user to inject GCode commands or tinyG commands to the tinyG on the fly.

TinyTerm allows to load and dump files into the tinyG in either text or JSON format. TinyTerm looks for the file extension and determnies if the file is a JSON or any other format.

If a JSON, TinyTerm will try to parse it following Pensa's schema for init files. Otherwise, if not a JSON, TinyTerm will treat it as a plain text file and dump all the contents to the tinyG.

An initialization, config, or _init_ file could be created containing all the desired init settings for the tinyG. For a complete list of commands and settings, please take a look at the [tinyG Wiki](https://github.com/synthetos/TinyG/wiki/TinyG-Configuration-for-Firmware-Version-0.97). Such file should be in JSON format and in the schema, have a JSONArray named _"commands"_ contained in a JSONObject:

```css
{
  "commands":[
    { "command": value },
    { "command": value },
    { "command": value }
  ]
}
```

You could have as many commands as necessary (some of our init files have dozens of commands!), all depending on how many axes and inputs you want to initialize with this file. Just make sure the JSON file is clean, and valid. Make liberal use of the [JSON lint](http://jsonlint.com).

To run GCode scripts on your tinyG, just save them as text files (.txt, .cnc, .nc, etc) and load them with TinyTerm.

Once a file has been loaded, a "Re-dump file" button will appear, allowing for quick re-running of the script.

TinyTerm will wait and look for a serial device to be plugged on a USB port and hold the interface until something is connected (not checking specifically for a tinyG, though). Once a connection has been established, the interface can be used.

The GUI is created with the [ControlP5](http://www.sojamo.de/libraries/controlP5/) library by [Sojamo](https://github.com/sojamo), so make sure you have this library installed before running this script.

Cheers!<br>
@\_frix_
