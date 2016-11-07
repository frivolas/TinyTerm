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
// Or if you have a tinyG connected to the TinyTerm, send the command "$$"
//
// The GUI gives you a textArea to show the history of what has been sent and received
// and a text box to type and inject GCode or tinyG Commands on the fly into the tinyG
// The interface is created using the controlP5 library.
//
// Thanks to http://stackoverflow.com/questions/29107544/serial-com-port-selection-by-dropdownlist-in-processing
// for the help with adding the Serial port dropdown list
// and to http://startingelectronics.org/software/processing/find-arduino-port/
// for detecting new serial connections on the fly


// Imports
import controlP5.*;
import processing.serial.*;

// GUI
ControlP5 cp5;
boolean buttonFlag=false;
ScrollableList serialPortsList;

// String variables
String theGCode = "G91 G1 X100 F100\n";     // Whatever you want to have as default text in the textbox
String jPath = "init.json";                 // the path where the JSON file is
String fileToDump;                          // String to store filename with absolute path of last dumped file (to quickly re-dump)

// The Init.JSON file to be loaded
JSONObject initFile;      // This will receive the JSON file as an object
JSONArray initCommands;   // we will extract the "commands" array of JSONObjects here

// file for the logfile
PrintWriter logFile;

// The serial port:
Serial myPort;  // Create object from Serial class
int BAUD_RATE = 9600;
Boolean serialConnected = false;
Boolean deviceDetected = false;
String[] portNames;
int numberofPorts = 0;
String detectedPort = "";

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
boolean tinyGconnected = true;

Textarea myTerminal;    // CP5 control for the text area
PFont font;             // the font for the script

// Use "Settings" to assign the size of the applet with variables.
void settings(){
  size(theWidth,theHeight);
}


void setup(){
  // size(600,600);      //Just if you have a really old version of Processing. Like this laptop.
  // Start the serial
  font = createFont("arial", 20); // big arial font
  startGUI();
  cp5.get(Bang.class,"loadFile").setTriggerEvent(Bang.RELEASE); // make the bang react at release
  // Gui Loaded. Terminal ready

  // List all the available serial ports, check the terminal window and select find the port# for the tinyG
  portNames = Serial.list();
  printArray(portNames);
  numberofPorts = portNames.length;
  // Open whichever port the tinyG uses in your computer (8 in mine):
  for(int i=0;i<numberofPorts;i++){
    serialPortsList.addItem(portNames[i], i);
  }

  // Hide the gui until the serial is connected.
  guiHide();

  myTerminal.append(theTime() + "Terminal ready... \n");
  myTerminal.append(theTime() + "Please choose a Serial port to connect to... \n");
  myTerminal.scroll(1);
  textFont(font);
}



void draw() {
  background(0);  //black BG
  //read response from tinyG
  refreshSerial();
  if(myPort != null){
  while (myPort.available () > 0) {
    String inBuffer = myPort.readString();
    if (inBuffer != null) {
      print("Incoming: " + inBuffer + "\n");
      if(theGCode.equals("$$\n")) {
        // If the command sent is '$$' (report config)
        // Remove the timestamp on the terminal to the incoming string
        // to have a cleaner display
        myTerminal.append(inBuffer);
        delay(10);
      }
      else {
        // For every other command,
        // Add the timestamp to the incoming string
        myTerminal.append(theTime() + inBuffer);
      }
      myTerminal.scroll(1);         // scroll to the bottom of the terminal
    }
  }
    myPort.clear();
}
  fill(255);
  stroke(255);
  text("TinyTerm:", x, y-pad);

}



// This function will listen to the Bang
// Set "theGCode" to the value in the textfield
// and send the string via serial to the tinyG.
void controlEvent(ControlEvent theEvent) {
  // Get text from the command line and send it
  if(theEvent.isAssignableFrom(Textfield.class)){
    theGCode = theEvent.getStringValue();
    if(theGCode != ""){
      theGCode = theGCode + "\n";
      println("Command sent: " + theGCode);
      // Send command to the tinyG
      if(theGCode.toLowerCase().equals("cls\n")) {
        myTerminal.clear();
        myTerminal.append(theTime() + "Terminal ready...\n");
      }
      else{
        myPort.write(theGCode);
        myTerminal.append(theTime() + theGCode);
        myTerminal.scroll(1);
      }
    }
  }
}



void serialports(int n){
  // Stop any active connections
  if(myPort != null){
    myPort.stop();
    myPort = null;
  }
  // open the selected port
  try{
    myPort = new Serial(this, Serial.list()[n], BAUD_RATE);
    serialConnected = true;
    } catch (Exception e) {
      System.err.println("Error opening serial port " + myPort);
      myTerminal.append(theTime() + "Error opening the selected serial port... \n");
      serialConnected = false;
      e.printStackTrace();
    }
    if(serialConnected) {
      println("Yay Serial!");
      myTerminal.append(theTime() + "Connected to Serial on port " + portNames[n] + "\n");
      guiShow();
  } else {
    println("Boo no Serial");
    myTerminal.append(theTime() + "No Serial connection" + "\n");
  }
  }


public void Send(){
  // Get the command from the text field
  theGCode = cp5.get(Textfield.class, "input").getText();
  theGCode = theGCode + "\n";
  // Print for debug
  println("Command sent: " + theGCode);
  // Put the command on the terminal
  if(theGCode.toLowerCase().equals("cls\n")) {
    myTerminal.clear();
    myTerminal.append(theTime() + "Terminal ready...\n");
  }
  else{
  // Send command to the tinyG
  myPort.write(theGCode);
  myTerminal.append(theTime() + theGCode);
  myTerminal.scroll(1);
}
  // Clear the text field to be ready for the next
  cp5.get(Textfield.class,"input").clear();
}


// This Bang clears the textfield
public void clear() {
  cp5.get(Textfield.class,"input").clear();
}



// Let's work on the GUI
void startGUI(){
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

  // create a new button to re-dump the last opened file to the tinyG
  cp5.addBang("againFile")
  .setCaptionLabel("Re-Dump File")
  .setPosition(x+taw+pad, y+tah+pad)
  .setSize(bw, tfh)
  .setColorBackground(color(180,40,50))
  .setColorActive(color(180,40,50))
  .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
  ;

  // create a new button to save the log
  cp5.addBang("saveLog")
  .setTriggerEvent(Bang.RELEASE)
  .setCaptionLabel("Save Log")
  .setPosition(x+taw+pad, y+sbh+pad)
  .setSize(bw, sbh)
  .setColorBackground(color(180,40,50))
  .setColorActive(color(180,40,50))
  .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
  ;

  // create a new button to make the logFile human readable
  cp5.addBang("cleanMyFile")
  .setTriggerEvent(Bang.RELEASE)
  .setCaptionLabel("Make Log Readable")
  .setPosition(x+taw+pad, y+(2*sbh)+(2*pad))
  .setSize(bw, sbh)
  .setColorBackground(color(180,40,50))
  .setColorActive(color(180,40,50))
  .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
  ;

  serialPortsList = cp5.addScrollableList("serialports")
  .setPosition(x+taw+pad,y+(3*sbh)+(3*pad))
  .setSize(bw,200)
  .setType(ScrollableList.LIST)
  ;

}



// When the load file bang is released, open a file explorer window
void loadFile(){
  myTerminal.append(theTime() + "Loading file...\n");
  selectInput("Select script file to load", "fileLoaded");
}

// See what the user selected as a file
void fileLoaded(File selection){
  // If no file, print on screen.
  if(selection == null){
    // println("No file selected");
    myTerminal.append(theTime() + "No file selected\n");
    myTerminal.scroll(1);
  } else {
    // If file, say it and send the file to the dumpFile function
    // println("File to load: " + selection.getAbsolutePath());
    fileToDump = selection.getAbsolutePath();   // Save the filename to the global variable
    myTerminal.append(theTime() + "File to load: " + selection.getAbsolutePath() + "\n");
    myTerminal.scroll(1);
    dumpFile(selection.getAbsolutePath());
    cp5.get(Bang.class,"againFile").show();
  }
  // remove the callback from the Bang or else it never lets us go
  cp5.get(Bang.class,"loadFile").removeCallback();
}


void againFile(){
  println("fileToDump=" + fileToDump);
  if(fileToDump.equals("")){
    // If there's no value in the variable, no file has been dumped
    myTerminal.append(theTime() + "No file to re-dump\n");
  } else {
    // We have a file, re-dump it.
    println("REDUMPING!!");
    myTerminal.append(theTime() + "Re-Dumping file " + fileToDump + "\n");
    myTerminal.scroll(1);
    dumpFile(fileToDump);
  }
  // cp5.get(Bang.class,"aganFile").removeCallback();
}



void saveLog(){
  String content=myTerminal.getText();
  String dateAppend = theDate();
  String theLogLocation = "/logs/data" + theDate() + ".log";
  logFile = createWriter(dataPath(theLogLocation));
  logFile.println(theTime() + "Starting Log file for session: " + dateAppend + "\n");
  logFile.println(content + "\n");
  logFile.flush();
  logFile.close();
  myTerminal.clear();
  myTerminal.append(theTime() + "Log File: " + theLogLocation + " created...\n");
  myTerminal.append(theTime() + "Terminal ready...\n");
  cp5.get(Bang.class,"saveLog").removeCallback();
}



// We'll first check what's the file type by checking the extension
// we just need to see if it's a JSON or not.
// If it's a JSON, treat it accordingly, if it's not, treat it as text and
// dump it.
void dumpFile(String theFile){
  myTerminal.append(theTime() + "Loading File... \n");
  myTerminal.scroll(1);
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
    myTerminal.scroll(1);
    // The tinyG doesn't accept JSONArrays as input, so we need to brake it.
    // So lets extract each command as a JSONObject, and
    // then convert it into a String to be sent via Serial to the tinyG
    for(int i=0; i<initCommands.size(); i++){
      JSONObject jsonObject = initCommands.getJSONObject(i);    // Get the command
      String sCommand = jsonObject.toString();                  // Make it a String
      sCommand = sCommand.replaceAll("\\s+", "");               // Clean the string
      println("Init Command # " + i + "> " + jsonObject + "\t | to String > " + sCommand);
      myPort.write(sCommand + "\n");                            // Send it to the tinyG
      myTerminal.append(theTime() + sCommand + "\n");           // Display the command on the terminal
      myTerminal.scroll(1);
      delay(50);
    }
    } else {
      // If it's not the init file, then let's just dump whatever is in the file.
      // if it's a JSON but not the init, it will be dumped and the tinyG might complain
      String fileLines[] = loadStrings(theFile);
      println("There are " + fileLines.length + " lines in this file");
      myTerminal.append(theTime() + "Sending " + fileLines.length + " lines of code... \n");
      myTerminal.scroll(1);

      for (int i=0 ; i<fileLines.length ; i++){
        println("Going in...");
        myPort.write(fileLines[i] + "\n");                                  // Send the line to the tinyG
        myTerminal.append(theTime() + fileLines[i] + "\n");                 // Put the line on the terminal
        myTerminal.scroll(1);
        delay(100);
        // We need a longer delay for "move" commands than for the "non-move" commands we send with the INIT file.
        // This is because of how the TinyG processes the queue. If this delay is made shorter, the tinyG most likely will
        // crash due to buffer overflow.
      }
    }
  myTerminal.append(theTime() + "File dumped to the tinyG. \n");
  myTerminal.scroll(1);
}



// This function returns a timestamp to be used as filename for the log file
String theDate(){
  int y = year();
  int mo = month();
  int d = day();
  int h = hour();
  int mi = minute();
  int s = second();

  String dateString = y + "" + mo + "" + d + "-" + h + mi + s;

  return dateString;
}

String theTime(){
  String theMinute;
  int h=hour();
  int mi=minute();

  if(mi<10) theMinute = "0" + mi;
  else theMinute = "" + mi;

  String timeString = "[" + h + ":" + theMinute + "] ";
  return timeString;
}




void guiHide(){
  // Hide all controls until the Serial has been established
  cp5.get(Bang.class,"Send").hide();                        // hide the "re-dump" bang
  cp5.get(Bang.class,"loadFile").hide();                        // hide the "re-dump" bang
  cp5.get(Bang.class,"againFile").hide();                        // hide the "re-dump" bang
  cp5.get(Bang.class,"saveLog").hide();                        // hide the "re-dump" bang
  cp5.get(Bang.class,"cleanMyFile").hide();                        // hide the "re-dump" bang
}

void guiShow(){
  // Hide all controls until the Serial has been established
  cp5.get(Bang.class,"Send").show();                        // hide the "re-dump" bang
  cp5.get(Bang.class,"loadFile").show();                        // hide the "re-dump" bang
  // cp5.get(Bang.class,"againFile").show();                        // hide the "re-dump" bang
  cp5.get(Bang.class,"saveLog").show();                        // hide the "re-dump" bang
  cp5.get(Bang.class,"cleanMyFile").show();                        // hide the "re-dump" bang
}



void refreshSerial(){
  // Let's check how many ports are there, if there are more than the original setup,
  // then there's a new device. If there are less, then we lost one.
  if((Serial.list().length > numberofPorts) && !deviceDetected){
    // there's a new connection
    deviceDetected = true;
    // determine which one was it
    boolean str_match = false;
    if(numberofPorts == 0){
      detectedPort = Serial.list()[0];
    } else {
      // compare the current list with the original list.
      for(int i=0;i<Serial.list().length;i++){
        for(int j=0;j<numberofPorts;j++){
          if(Serial.list()[i].equals(portNames[j])){
            detectedPort=Serial.list()[i];
            break;
          }
        }
      }
    }
    println("Adding port "+ detectedPort + " to the list");
    serialPortsList.addItem(detectedPort, numberofPorts);
  } else if(Serial.list().length < numberofPorts){
    println("Lost a port, refresh list");
  }

}
