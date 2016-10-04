import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import controlP5.*; 
import processing.serial.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class TinyTerm extends PApplet {

// TinyTerm
// By Oscar Frias (@_frix_) 2016
// www.oscarfrias.com
//
// TinyTerm is a simple interface for a serial terminal to control the TinyG board.
// We needed a quick way to send both tinyG commands and GCode to the tinyG,
// while at the same time have a quick and easy way to dump the init settings
// to the board without having to type them every time.
//
// TinyTerm loads a JSON file called "init.json" from the /data folder containing
// the init settings that we want to dump on the tinyG, and extracts the array of
// json objects called "commands" as a long string. See the JSON file to learn how to
// properly format this init file.
//
// Then it opens a serial connection, searches for the tinyG, and
// then dumps the JSON-turned-into-strings into the tinyG
//
// The complete list of tinyG commands and settings can be found @
// https://github.com/synthetos/TinyG/wiki/TinyG-Configuration-for-Firmware-Version-0.97
//
// The GUI gives you a textArea to show the history of what has been sent and received
// and a text box to type and inject GCode or tinyG Commands on the fly into the tinyG
// The interface is created using the controlP5 library.


// Imports



// GUI
ControlP5 cp5;
boolean buttonFlag=false;

// String variables
String theGCode = "G91 G1 X100 F100\n";     // Whatever you want to have as default text in the textbox
String jPath = "init.json";                 // the path where the JSON file is

// The Init.JSON file to be loaded
JSONObject initFile;      // This will receive the JSON file as an object
JSONArray initCommands;   // we will extract the "commands" array of JSONObjects here

// file for the logfile
PrintWriter logFile;

// The serial port:
Serial myPort;  // Create object from Serial class

//misc variables
int x = 50;             // Position on the X axis
int y = 50;             // Position on the Y axis
int tfh = 50;           // textfield height
int taw;                // textArea width
int tah;                // textArea height
int bw = 100;           // width of Bang
int sbh = 30;           // side button height
int theWidth = 800;     // applet width
int theHeight = 600;    // applet height
int pad = 20;           // padding between fields
int lineCounter = 0;    // linefeed char coming from the serial

Textarea myTerminal;    // CP5 control for the text area
PFont font;             // the font for the script

// Use "Settings" to assign the size of the applet with variables.
public void settings(){
  size(theWidth,theHeight);
}


public void setup()
{
  // size(600,600);      //Just if you have a really old version of Processing. Like this laptop.
  // Start the serial
  // List all the available serial ports, check the terminal window and select find the port# for the tinyG
  printArray(Serial.list());
  // Open whichever port the tinyG uses in your computer (8 in mine):
  myPort = new Serial(this, Serial.list()[2], 115200);
  myPort.clear();

  font = createFont("arial", 20); // big arial font
  startGUI();
  cp5.get(Bang.class,"loadFile").setTriggerEvent(Bang.RELEASE); // make the bang react at release
  // Gui Loaded. Terminal ready
  myTerminal.append(theTime() + "Terminal ready... \n");
  myTerminal.scroll(1);
  textFont(font);
}



public void draw() {
  background(0);  //black BG
  //read response from tinyG
  while (myPort.available () > 0) {
    String inBuffer = myPort.readString();
    if (inBuffer != null) {
      print("Incoming: " + inBuffer);
      myTerminal.append(theTime() + inBuffer);
      myTerminal.scroll(1);         // scroll to the bottom of the terminal
    }
  }
  fill(255);
  stroke(255);
  text("TinyTerm:", x, y-pad);
  myPort.clear();
}



// This function will listen to the Bang
// Set "theGCode" to the value in the textfield
// and send the string via serial to the tinyG.
public void controlEvent(ControlEvent theEvent) {
  // Get text from the command line and send it
  if(theEvent.isAssignableFrom(Textfield.class)){
    theGCode = theEvent.getStringValue();
    if(theGCode != ""){
      theGCode = theGCode + "\n";
      println("Command sent: " + theGCode);
      // Send command to the tinyG
      myPort.write(theGCode);
      myTerminal.append(theTime() + theGCode);
      myTerminal.scroll(1);
    }
  }
}


public void Send(){
  // Get the command from the text field
  theGCode = cp5.get(Textfield.class, "input").getText();
  theGCode = theGCode + "\n";
  // Print for debug
  println("Command sent: " + theGCode);
  // Put the command on the terminal
  myTerminal.append(theTime() + theGCode);
  myTerminal.scroll(1);
  // Send command to the tinyG
  myPort.write(theGCode);
  // Clear the text field to be ready for the next
  cp5.get(Textfield.class,"input").clear();
}


// This Bang clears the textfield
public void clear() {
  cp5.get(Textfield.class,"input").clear();
}



// When the load file bang is released, open a file explorer window
public void loadFile(){
  myTerminal.append(theTime() + "Loading file...\n");
  selectInput("Select script file to load", "fileLoaded");
}

// See what the user selected as a file
public void fileLoaded(File selection){
  // If no file, print on screen.
  if(selection == null){
    // println("No file selected");
    myTerminal.append(theTime() + "No file selected\n");
  } else {
    // If file, say it and send the file to the dumpFile function
    // println("File to load: " + selection.getAbsolutePath());
    myTerminal.append(theTime() + "File to load: " + selection.getAbsolutePath() + "\n");
    dumpFile(selection.getAbsolutePath());
  }
  // remove the callback from the Bang or else it never lets us go
  cp5.get(Bang.class,"loadFile").removeCallback();
}


// Let's work on the GUI
public void startGUI(){
  // Construct a CP5
  cp5 = new ControlP5(this);            // start the cp5 GUI

  // Define the size of the text area
  taw = width - (2*x) - bw - pad;
  tah = height - y-(2*pad)-tfh;

  // Add a textArea to capture the incoming serial
  myTerminal = cp5.addTextarea("serialText")
  .setPosition(x,y)
  .setSize(taw,tah)
  .setFont(createFont("courier",14))
  .setLineHeight(14)
  .setColor(color(190))
  .setBorderColor(color(0))
  .setColorBackground(color(200,100))
  .setColorForeground(color(255))
  .setScrollBackground(color(200,100))
  .setScrollActive(color(128))
  .showScrollbar()
  .showArrow()
  ;

  // Add a textfield to allow code injection to the tinyG
  cp5.addTextfield("input")
  .setPosition(x, y + tah + pad)     // up and to the left
  .setSize(taw-bw-pad, tfh)         // make it big
  .setFont(font)
  .setFocus(true)
  .setText(theGCode)
  .setColor(color(255))
  .setColorBackground(color(200,100))
  .setColorForeground(color(255))
  .setColorActive(color(230,100))
  .setAutoClear(true)
  ;

  // create a new button with name 'Send' to shoot the command to the tinyG
  cp5.addBang("Send")
  .setPosition(x+taw-bw, y+tah+pad)
  .setSize(bw, tfh)
  .setColorBackground(color(180,40,50))
  .setColorActive(color(180,40,50))
  .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
  ;

  // create a new button to quickly dump the init file to the tinyG
  cp5.addBang("loadFile")
  .setCaptionLabel("Load File")
  .setPosition(x+taw+pad, y)
  .setSize(bw, sbh)
  .setColorBackground(color(180,40,50))
  .setColorActive(color(180,40,50))
  .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
  ;


  // create a new button to save the log
  cp5.addBang("saveLog")
  .setCaptionLabel("Save Log")
  .setPosition(x+taw+pad, y+sbh+pad)
  .setSize(bw, sbh)
  .setColorBackground(color(180,40,50))
  .setColorActive(color(180,40,50))
  .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
  ;

}


public void saveLog(){
String content=myTerminal.getText();
String dateAppend = theDate();
String theLogLocation = "/logs/data" + theDate() + ".log";
logFile = createWriter(dataPath(theLogLocation));
logFile.println(theTime() + "Starting Log file for session: " + dateAppend + "\n");
logFile.println(content);
logFile.flush();
logFile.close();
myTerminal.clear();
myTerminal.append(theTime() + "Log File: " + theLogLocation + " created...\n");
myTerminal.append(theTime() + "Terminal ready...\n");
}



// We'll first check what's the file type by checking the extension
// we just need to see if it's a JSON or not.
// If it's a JSON, treat it accordingly, if it's not, treat it as text and
// dump it.
public void dumpFile(String theFile){
  myTerminal.append(theTime() + "Loading File... \n");
  String theLCFile = theFile.toLowerCase(); // so there's no confustion between JSON and json

  // If it's a json let's check if it's the init file to properly send it to the tinyG
  if(theLCFile.endsWith("json") && theLCFile.contains("init")){
    initFile = loadJSONObject(dataPath(theFile));
    // Get the "Commands" array from the init file
    initCommands = initFile.getJSONArray("commands");
    delay(500);
    myTerminal.append(theTime() + "JSON Loaded... \n");
    delay(250);
    myTerminal.append(theTime() + "Dumping init file... \n");
    // The tinyG doesn't accept JSONArrays as input, so we need to brake it.
    // So lets extract each command as a JSONObject, and
    // then convert it into a String to be sent via Serial to the tinyG
    for(int i=0; i<initCommands.size(); i++){
      JSONObject jsonObject = initCommands.getJSONObject(i);    // Get the command
      String sCommand = jsonObject.toString();                  // Make it a String
      sCommand = sCommand.replaceAll("\\s+", "");               // Clean the string
      // println("Init Command # " + i + "> " + jsonObject + "\t | to String > " + sCommand);
      myPort.write(sCommand + "\n");                            // Send it to the tinyG
      myTerminal.append(theTime() + sCommand + "\n");                       // Display the command on the terminal
    }
    } else {
      // If it's not the init file, then let's just dump whatever is in the file.
      // if it's a JSON but not the init, it will be dumped and the tinyG might complain
      String fileLines[] = loadStrings(theFile);
      println("There are " + fileLines.length + " lines in this file");
      myTerminal.append(theTime() + "Sending " + fileLines.length + " lines of code... \n");

      for (int i=0 ; i<fileLines.length ; i++){
        println("Going in...");
        myPort.write(fileLines[i] + "\n");                      // Send the line to the tinyG
        myTerminal.append(theTime() + fileLines[i] + "\n");                 // Put the line on the terminal
        delay(150);
      }
    }
  myTerminal.append(theTime() + "File dumped to the tinyG. \n");
  myTerminal.scroll(1);
}



// This function returns a timestamp to be used as filename for the log file
public String theDate(){
  int y = year();
  int mo = month();
  int d = day();
  int h = hour();
  int mi = minute();
  int s = second();

  String dateString = y + "" + mo + "" + d + "-" + h + mi + s;

  return dateString;
}

public String theTime(){
  String theMinute;
  int h=hour();
  int mi=minute();

  if(mi<10) theMinute = "0" + mi;
  else theMinute = "" + mi;

  String timeString = "[" + h + ":" + mi + "] ";

  return timeString;
}
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "TinyTerm" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
