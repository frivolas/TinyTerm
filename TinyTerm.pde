// TinyTerm V2.0.0 for DIWire
// By Oscar Frias (@_frix_) and Dinesh Durai 2020
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
//
// 07/27/20:
// As of today, tinyTerm allows to dump a file repeatedly, up to the number of times
// indicated by the user. It also keeps a counter of the number of times the file has been 
// dumped into the tinyG, as means for the user to know what has happened. This ends up being 
// super helpful. For this to work in this version of tinyTerm, the file needs to have the word "EOF" 
// as the last line. 
// Homing sequence works. Status reads also work
// 


// Imports
import controlP5.*;
import processing.serial.*;
//import processing.io.*;    // to get the i/o pins from a raspberry Pi
import java.util.Deque;
import java.util.ArrayDeque;
import java.util.Iterator;
import java.util.LinkedList;

static final int bufferSize = 5;

final Deque<String> dataQueue = new LinkedList<String>();
//https://forum.processing.org/two/discussion/2829/fifo-queue-problem-with-code
Integer num = new Integer(0);
//Buffer size for the Queue data structure 
//int bufferSize = 50;
//always maintain 4 in the queue
int tinyGBuffer = 0;

//RPI Smart Pin 
int s_Pin = 26;

//previous command status
int measure=0;
// GUI
ControlP5 cp5;
boolean buttonFlag=false;
ScrollableList serialPortsList;

// String variables
String theGCode = "home";                // Whatever you want to have as default text in the textbox (currently sets the tinyG to textmode)
String jPath = "init.json";                 // the path where the JSON file is
String fileToDump;                          // String to store filename with absolute path of last dumped file (to quickly re-dump)

// The Init.JSON file to be loaded
JSONObject initFile;                        // This will receive the JSON file as an object
JSONArray initCommands;                     // we will extract the "commands" array of JSONObjects here

// file for the logfile
PrintWriter logFile;

// The serial port:
Serial myPort;                              // Create object from Serial class
int BAUD_RATE = 115200;                     // default BAUD from the tinyG
Boolean serialConnected = false;
Boolean deviceDetected = false;
String[] portNames;
int numberofPorts = 0;
String detectedPort = "";
int lineCounter = 0;    // linefeed char coming from the serial
String inBuffer = null;        // to receive the comms from tinyG

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
boolean aboutToExit = false;  

boolean tinyGconnected = true;
boolean canSend = true;    // can I send stuff to the tinyG?
boolean isHoming = false;
boolean isHomed = false;
boolean statusInterlock = false;
float homingEdgePos = 0;
PrintWriter logger;
String posAReq = "$posa\n";

int repeatLoops = 0;    // variables to store how many times to repeat sending a file
int loopsLeft = 0;

Textarea myTerminal;    // CP5 control for the text area
PFont font;             // the font for the script
PFont inputFont;        // the font for the small input field

// list of tinyG status codes
StringList statCodes;


// Use "Settings" to assign the size of the applet with variables.
void settings() {
  size(theWidth, theHeight);
}


void setup() {
  // Configure the window
  surface.setTitle("Tiny Term V2");    // Add a nice title
  //surface.setResizable(true);          // Allow it to be resizable
  surface.setLocation(100, 100);       // Position it up-left
  // Start the serial
  // List all the available serial ports, check the terminal window and select find the port# for the tinyG
  portNames = Serial.list();
  println("Available COM ports:");
  printArray(portNames);
  numberofPorts = portNames.length;

  // Build GUI
  font = createFont("arial", 20); // big arial font
  inputFont = createFont("arial", 12); // big arial font
  startGUI();
  cp5.get(Bang.class, "loadFile").setTriggerEvent(Bang.RELEASE); // make the bang react at release
  cp5.get(Textlabel.class, "counter").setText("1");
  // Add all the available serial ports to the drop-down list
  for (int i=0; i<numberofPorts; i++) {
    serialPortsList.addItem(portNames[i], i);
  }

  // Hide the gui until the serial is connected.
  guiHide();


  // Gui Loaded. Terminal ready
  reportEvent("Terminal ready... \n");
  String dateAppend = theDate();
  String theLogLocation = "logs/" + "AutoLogger_" + dateAppend + ".log";
  logger = createWriter(dataPath(theLogLocation));
  logger.println(theTime() + "Starting Log file for session: " + dateAppend + "\n");
  //logFile.println(content + "\n");
  logger.flush();
  reportEvent("Log file started \n");  
  reportEvent("Please choose a Serial port to connect to... \n");
  textFont(font);

  // Uncomment if running this in the Raspberry PI:
  //GPIO.pinMode(s_Pin, GPIO.INPUT_PULLUP);
  //GPIO.attachInterrupt(s_Pin, this, "pinEvent", GPIO.FALLING);
  // Create a new file in the sketch directory
  //logger = createWriter("positions.txt"); 
  //String content=myTerminal.getText();

  //  prepareExitHandler();  // so we can run code on exit

  statCodes = new StringList();
  tinyGStatus(statCodes);
}



void draw() {
  background(0);  //black BG

  refreshSerial();
  logic();

  if (myPort != null) {

    while (myPort.available () > 0) {
      inBuffer = myPort.readStringUntil(10);  //10 = LF
      if (inBuffer != null) {
        reportEvent("< " + inBuffer);
        logger.println("From tinyG: " + theTime() + inBuffer);
        logger.flush();

        // we listen for a response from the tinyG.
        if (inBuffer.indexOf("r:")>-1 || inBuffer.indexOf("sr:")>-1) {          // can be a received (r:) a status report (sr:) 
          tinyGBuffer--;                                                        // or some status codes. Reduce the buffer since it's been used
        }
        if (inBuffer.indexOf("stat:3")>-1 || inBuffer.indexOf("\"stat:3\"")>-1 && isHoming && !statusInterlock) {                 // getting a status 3: Program STOP (machine done)
          //if (isHoming && isHomed) {
          reportEvent("Machine is homed. \n");
          //isHoming = false;
          //} 
          tinyGBuffer = 0;
        } //else if (inBuffer.indexOf("stat:3")>0) {
        //reportEvent("S:3 - Ready. \n");
        //tinyGBuffer = 0;
        //} 
        if (inBuffer.indexOf("stat:6")>0 || inBuffer.indexOf("\"stat\":6")>0) {  // status 6: Machine on HOLD (interlock!)
          println("INTERLOCK!");
          statusInterlock=true;
          myPort.write("%\n");      //  first push the GCode
          dataQueue.clear();         //  then clear the queue
          tinyGBuffer=0;             //  then reset the buffer
          reportEvent("Interlock hit. Stop. Flush queue...\n");    // then we get chatty

          if (isHoming) {
            reportEvent("WE'RE HOMING, ASK FOR $POSA \n");    // then we get chatty
            //dataQueue.clear();
            //tinyGBuffer=0;
            myPort.write("%\n");
            delay(50);
            myPort.write("$di1fn=0\n");
            delay(50);
            reportEvent("Asking for directions\n");
            dataQueue.add(posAReq);
          }
        } 
        if (inBuffer.indexOf("position") > 0 && isHoming) { // if we're homing and receive a position, pass it on
          reportEvent("< " + inBuffer);
          String f = inBuffer.replaceAll("[^\\d.-]", "");
          float currentAngle = float(f);
          homePT2(currentAngle);
        }
        // make sure we're not going negative sizes
        if (tinyGBuffer<0) tinyGBuffer=0;
      }//end if inbuffer null
    }//end while myport
    myPort.clear();
  }//end if !myport

  // write a nice title block
  fill(255);
  stroke(255);
  text("TinyTerm:", x, y-pad);
}



// This is the main guy sending the GCode (Dinesh)
// This function will listen to the Bang
// Set "theGCode" to the value in the textfield
// and send the string via serial to the tinyG.
void controlEvent(ControlEvent theEvent) {
  // Get text from the command line and send it
  if (theEvent.isAssignableFrom(Textfield.class)) {
    println("texfield event!");
    SendCommand();
  }
}


void serialports(int n) {
  // Stop any active connections
  if (myPort != null) {
    myPort.stop();
    myPort = null;
  }
  // open the selected port
  try {
    myPort = new Serial(this, Serial.list()[n], BAUD_RATE);
    //myPort.bufferUntil(10);
    serialConnected = true;
  } 
  catch (Exception e) {
    System.err.println("Error opening serial port " + myPort);
    reportEvent("Error opening the selected serial port... \n");
    serialConnected = false;
    e.printStackTrace();
  }
  if (serialConnected) {
    myPort.write("$ej:0\n");                                              // Comms must be in TEXT format for tinyterm to catch the STATs
    println("Yay Serial!");
    reportEvent("Connected to Serial on port " + portNames[n] + "\n");
    guiShow();
  } else {
    reportEvent("No Serial connection available on that port... \n");
    guiHide();
  }
}


public void Send() {
  // Get the command from the text field
  SendCommand();
  clear();
}


void SendCommand() {
  theGCode = cp5.get(Textfield.class, "input").getText().toLowerCase();   // to lower case to prevent conflicts of interest

  if (theGCode.indexOf("home")>-1) {                                      // first check for commands and keywords:
    if (theGCode.equals("home")) {                                        // if the command is -exactly- "HOME", then home the whole machine
      reportEvent("Homing all axes. \n");
      letsHome('*');
    } else {                                                              // if it's home plus something else, let's check what's incoming
      char theAxis = theGCode.charAt(theGCode.indexOf("home")+4);         // check one character after "home" to determine axis to home
      if (theAxis == 'a' || theAxis == 'x' || theAxis == 'z') {           // check for valid axes
        reportEvent("Homing axis: " + theAxis + "\n");
        letsHome(theAxis);
      } else {                                                            // it's not an axis or just gibberish
        reportEvent("Axis " + theAxis + " cannot be homed");
      }
    } //end equals
  } else if (theGCode.equals("cls")) {                                    // clear the terminal
    saveLog();
    myTerminal.clear();
    reportEvent("Terminal cleared and ready...\n");
    myTerminal.scroll(1);
  } else if (theGCode.equals("exit")) {                                   // close app
    reportEvent("Preparing to quit...\n");
    saveLog();
    reportEvent("Log file saved...\n");
    delay(500);
    exit();
  } else {                                                                 // anything else is a Sendable command, or rando text, so send it
    theGCode = theGCode + "\n";                                            // Add a newline so the tinyG doesn't freak out (it's expected)
    dataQueue.add(theGCode);                                               // Add command to the queue
    //println("Command added: " + theGCode);
  }
}

// This Bang clears the textfield
public void clear() {
  cp5.get(Textfield.class, "input").clear();
}

// When the load file bang is released, open a file explorer window
void loadFile() {
  reportEvent("Loading file...\n");
  selectInput("Select script file to load", "fileLoaded");
}


// See what the user selected as a file
void fileLoaded(File selection) {
  // If no file, print on screen.
  if (selection == null) {
    reportEvent("No file selected\n");
  } else {
    // If file, say it and send the file to the dumpFile function
    // println("File to load: " + selection.getAbsolutePath());
    fileToDump = selection.getAbsolutePath();   // Save the filename to the global variable
    reportEvent("File to load: " + selection.getAbsolutePath() + "\n");
    dumpFile(selection.getAbsolutePath());
    cp5.get(Bang.class, "againFile").show();
  }
  // remove the callback from the Bang or else it never lets us go
  cp5.get(Bang.class, "loadFile").removeCallback();
}


void againFile() {
  if (fileToDump.equals("")) {
    // If there's no value in the variable, no file has been dumped
    reportEvent("No file to re-dump. \n");
  } else {
    // We have a file, re-dump it.
    println("REDUMPING!!");
    reportEvent("Re-Dumping file " + fileToDump + " ...\n");
    dumpFile(fileToDump);
  }
  // cp5.get(Bang.class,"aganFile").removeCallback();
}



void saveLog() {
  String content=myTerminal.getText();
  String dateAppend = theDate();
  String theLogLocation = "logs/data" + theDate() + ".log";
  logFile = createWriter(dataPath(theLogLocation));
  logFile.println(theTime() + "Starting Log file for session: " + dateAppend + "\n");
  logFile.println(content + "\n");
  logFile.flush();
  logFile.close();
  myTerminal.clear();
  reportEvent("Log File: " + theLogLocation + " created...\n");
  reportEvent("Terminal ready...\n");
  cp5.get(Bang.class, "saveLog").removeCallback();
}






// This function returns a timestamp to be used as filename for the log file
String theDate() {
  int y = year();
  int mo = month();
  int d = day();
  int h = hour();
  int mi = minute();
  int s = second();

  String dateString = y + "" + mo + "" + d + "-" + h + mi + s;

  return dateString;
}

String theTime() {
  String theMinute;
  //String theMilliSecond;
  String theSecond;
  int h=hour();
  int mi=minute();
  int sec = second();
  //int mill=millis();

  /*
  if (mill < 10 ) theMilliSecond = "00" + mill;
   else if(mill < 100) theMilliSecond = "0" + mill;
   else theMilliSecond = "" + mill;
   */

  if (mi<10) theMinute = "0" + mi;
  else theMinute = "" + mi;

  if (sec<10) theSecond = "0" + sec;
  else theSecond = ""+sec;

  //String timeString = "[" + h + ":" + theMinute + ":" + theSecond + "." + theMilliSecond + "] ";
  String timeString = "[" + h + ":" + theMinute + ":" + theSecond + "] ";
  return timeString;
}




void refreshSerial() {
  // Let's check how many ports are there, if there are more than the original setup,
  // then there's a new device. If there are less, then we lost one.
  if ((Serial.list().length > numberofPorts) && !deviceDetected) {
    // there's a new connection
    deviceDetected = true;
    // determine which one was it
    boolean str_match = false;
    if (numberofPorts == 0) {
      detectedPort = Serial.list()[0];
    } else {
      // compare the current list with the original list.
      for (int i=0; i<Serial.list().length; i++) {
        for (int j=0; j<numberofPorts; j++) {
          if (Serial.list()[i].equals(portNames[j])) {
            detectedPort=Serial.list()[i];
            break;
          }
        }
      }
    }
    serialPortsList.addItem(detectedPort, numberofPorts);
    reportEvent("Added port: " + detectedPort + " to the list of connections... \n");
  } else if ((Serial.list().length < numberofPorts) && deviceDetected) {
    // We lost the connection
    println("Lost a port, refresh list");
    deviceDetected = false;
    // compare the current Serial list with the original list
    for (int i=0; i<numberofPorts; i++) {
      for (int j=0; j<Serial.list().length; j++) {
        if (Serial.list()[j].equals(portNames[i])) {
          detectedPort=portNames[i];  // we lost this port
          break;
        }
      }
    }
    println("Need to remove " + detectedPort + " from the list");
    reportEvent("Lost connection on port: " + detectedPort + "\n");
    reportEvent("Please connect a device to continue ... \n");
  }
}


public void keyPressed() { 
  switch(key) { 
  case ESC: 
    key = 0; 
    reportEvent("ESC pressed, do you want to exit Y/N? \n");
    aboutToExit=true;
    break;

  case 'y':
    //key=0;
    if (aboutToExit) {
      saveLog();
      println("log saved");
      println("leaving");
      exit();
    }
    break;

  case 'n':
    if (aboutToExit) {
      reportEvent("N: OK clearing textfield. \n");
      cp5.get(Textfield.class, "input").setText("");
      println("here to stay");
      aboutToExit=false;
      break;
    }
  }
}



void tinyGStatus(StringList theList) {
  // fill the list with the potential tinyG status codes
  theList.append("stat:0");
  theList.append("stat:1");
  theList.append("stat:2");
  theList.append("stat:3");
  theList.append("stat:4");
  theList.append("stat:5");
  theList.append("stat:6");
  theList.append("stat:7");
  theList.append("stat:8");
  theList.append("stat:9");
  theList.append("stat:10");
  theList.append("stat:11");
  theList.append("stat:12");
  theList.append("stat:13");
}










/* Uncomment if running in the raspberry pi
 void pinEvent(int pin)
 {
 //disable interrupts. Cheat to over come Debounce
 //GPIO.noInterrupts();
 println("In ISR");
 if (measure == 2)
 {
 myPort.write("!%");
 println("Received interrupt on pin" + pin);
 if (debug) myTerminal.append(theTime() + "Received interrupt on pin" + pin + "\n");
 if (debug) myTerminal.scroll(1);
 canSend = false;
 measure = 3;
 }
 delay(30);
 //enable interrupts. 
 //GPIO.interrupts();
 }
 */









/*
             String testingThis = inBuffer.substring(inBuffer.indexOf("position")+9).replaceAll("[^\\d.-]", "");*/
