// TinyTerm for DIWire
// By Oscar Frias (@_frix_) and Dinesh Durai 2019
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
// 10/17/19:
// As of today, tinyTerm allows to dump a file repeatedly, up to the number of times
// indicated by the user. It also keeps a counter of the number of times the file has been 
// dumped into the tinyG, as means for the user to know what has happened. This ends up being 
// super helpful. For this to work in this version of tinyTerm, the file needs to have the word "END" 
// as the last line. 
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
String theGCode = "$ej:0\n";                // Whatever you want to have as default text in the textbox (currently sets the tinyG to textmode)
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

//misc variables
int x = 50;             // Position on the X axis
int y = 50;             // Position on the Y axis
int tfh = 50;           // textfield height
int taw;                // textArea width
int tah;                // textArea height
int bw = 100;           // width of Bang
int sbh = 30;           // side button height
int theWidth = 800;     // applet width
int theHeight = 450;    // applet height
int pad = 20;           // padding between fields
int lineCounter = 0;    // linefeed char coming from the serial
boolean tinyGconnected = true;
boolean canSend = true;    // can I send stuff to the tinyG?
boolean isHoming = false;
float homingEdgePos = 0;
PrintWriter logger;

int repeatLoops = 0;    // variables to store how many times to repeat sending a file
int loopsLeft = 0;

Textarea myTerminal;    // CP5 control for the text area
PFont font;             // the font for the script
PFont inputFont;        // the font for the small input field

//Queue queue = new Queue();
// Use "Settings" to assign the size of the applet with variables.
void settings() {
  size(theWidth, theHeight);
}


void setup() {
  // size(600,600);      //Just if you have a really old version of Processing. Like this laptop.
  // Start the serial
  font = createFont("arial", 20); // big arial font
  inputFont = createFont("arial", 12); // big arial font
  startGUI();
  cp5.get(Bang.class, "loadFile").setTriggerEvent(Bang.RELEASE); // make the bang react at release
  cp5.get(Textlabel.class, "counter").setText("1");
  // Gui Loaded. Terminal ready

  // List all the available serial ports, check the terminal window and select find the port# for the tinyG
  portNames = Serial.list();
  printArray(portNames);
  numberofPorts = portNames.length;
  // Open whichever port the tinyG uses in your computer (8 in mine):
  for (int i=0; i<numberofPorts; i++) {
    serialPortsList.addItem(portNames[i], i);
  }

  

  // Hide the gui until the serial is connected.
  guiHide();

  myTerminal.append(theTime() + "Terminal ready... \n");
  myTerminal.append(theTime() + "Please choose a Serial port to connect to... \n");
  myTerminal.scroll(1);
  textFont(font);
  //GPIO.pinMode(s_Pin, GPIO.INPUT_PULLUP);
  //GPIO.attachInterrupt(s_Pin, this, "pinEvent", GPIO.FALLING);

  // Create a new file in the sketch directory
  //logger = createWriter("positions.txt"); 

  //String content=myTerminal.getText();
  String dateAppend = theDate();
  String theLogLocation = "logs/" + "AutoLogger_" + dateAppend + ".log";
  logger = createWriter(dataPath(theLogLocation));
  logger.println(theTime() + "Starting Log file for session: " + dateAppend + "\n");
  //logFile.println(content + "\n");
  logger.flush();
  //logger.close();
  //logger.println(theTime() + "1Starting Log file for session: " + dateAppend + "\n");
  //.println("Some data" + "\n");
  //logger.flush();
  //logger.close();
}

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

void draw() {
  background(0);  //black BG
  //read response from tinyG
  refreshSerial();
  logic();
  if (myPort != null) {
    while (myPort.available () > 0) {
      //println("Buffer");
      String inBuffer = myPort.readStringUntil(10);  //10 = LF
      if (inBuffer != null) {
        print("Incoming: " + inBuffer + "\n");
        logger.println("From tinyG: " + theTime() + inBuffer);
        logger.flush();
        myTerminal.append(theTime() + inBuffer);
        myTerminal.scroll(1);
        if (isHoming) {
          print("In homing");
          if (inBuffer.indexOf("position")>0 || true) {
            String testingThis = inBuffer.substring(inBuffer.indexOf("position")+9).replaceAll("[^\\d.-]", "");
            println("hihihi"+testingThis);
            myTerminal.append(testingThis);
            myTerminal.scroll(1);
            homingEdgePos = float(testingThis);
            homeAlone();
            // here is where you catch the position from the string
            // homingEdgePos = float(name_of_the_string_where_you_got_posa);
            //
          }
        }

        if (inBuffer.indexOf("stat:3")>0 || inBuffer.indexOf("\"stat\":3")>0)         // catch if the tinyG is done (reports stat:3) 
        {
          print("Buffer Reset");
          tinyGBuffer = 0;
          println("DONE!");
        }
        if (theGCode.equals("$$\n")) {
          // If the command sent is '$$' (report config)
          // Remove the timestamp on the terminal to the incoming string
          // to have a cleaner display
          myTerminal.append(inBuffer);
          delay(500);
        } else {
          // For every other command,
          // Add the timestamp to the incoming string
          if (inBuffer.indexOf("position") > 0) { // this is used to only write the angle pos from tinyg
            myTerminal.append(theTime() + inBuffer);
            tinyGBuffer--;
            String f = inBuffer.replaceAll("[^\\d.-]", "");
            smartPinWireAngle = float(f);

            //logger.println("SmartPin touched the wire at pin angle of: " + smartPinWireAngle + "\n");
            //logger.flush();

            //pin to wire transform comes here -0.000000486582384898182*L30^4 + 0.0000649959719515962*L30^3 + 0.000340808169464137*L30^2 + 1.15404831926069*L30^1 + 17.0014870577853
            smartPinWireAngle = -0.000000486582384898182*pow(smartPinWireAngle, 4)+ 0.0000649959719515962*pow(smartPinWireAngle, 3) + 0.000340808169464137*pow(smartPinWireAngle, 2) + 1.15404831926069*smartPinWireAngle + 17.0014870577853;
            //logger.println("Smartpin Pin position to Wire Angle: " + smartPinWireAngle + "\n");
            //logger.flush();
            print("This is the wire angle right now: " + smartPinWireAngle + "\n\n");
          }
        }
        myTerminal.scroll(1);         // scroll to the bottom of the terminal
      }
      //println("InBuffer NULL");      // just debugging
    }
    myPort.clear();
  }
  fill(255);
  stroke(255);
  text("TinyTerm:", x, y-pad);

  //for (int frame = 1; frame <100; frame++) {
  //  //read data from arduino
  //  String[] words = { "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "1one", "1two", "1three", "1four", "1five", "1six", "1seven", "1eight", "1nine", "1ten" };
  //  int index = int(random(words.length));  // Same as int(random(4))
  //  String str =   words[(frame -1)%20];
  //  //println(num);
  //  if (frame < bufferSize) {
  //    queue.push(str);
  //    queue.display();
  //  } else {
  //    queue.display();
  //    queue.pop();
  //    queue.push(str);
  //    queue.display();
  //  }
  //}
  //exit();
}



// This is the main guy sending the GCode (Dinesh)
// This function will listen to the Bang
// Set "theGCode" to the value in the textfield
// and send the string via serial to the tinyG.
void controlEvent(ControlEvent theEvent) {
  // Get text from the command line and send it
  if (theEvent.isAssignableFrom(Textfield.class)) {
    println("texfield event!");
    Send();
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
    serialConnected = true;
  } 
  catch (Exception e) {
    System.err.println("Error opening serial port " + myPort);
    myTerminal.append(theTime() + "Error opening the selected serial port... \n");
    serialConnected = false;
    e.printStackTrace();
  }
  if (serialConnected) {
    println("Yay Serial!");
    myTerminal.append(theTime() + "Connected to Serial on port " + portNames[n] + "\n");
    guiShow();
  } else {
    println("Boo no Serial");
    myTerminal.append(theTime() + "No Serial connection" + "\n");
    guiHide();
  }
}


public void Send() {
  // Get the command from the text field
  theGCode = cp5.get(Textfield.class, "input").getText();

  if (theGCode.toLowerCase().equals("home")) {
    letsHome();
    isHoming = true;
  } else {
    theGCode = theGCode + "\n";
    // Print for debug
    println("Command sent: " + theGCode);
    // Put the command on the terminal
    if (theGCode.toLowerCase().equals("cls\n")) {
      myTerminal.clear();
      myTerminal.append(theTime() + "Terminal ready...\n");
    } else {
      // Send command to the tinyG
      dataQueue.add(theGCode);
    }
  }
  // Clear the text field to be ready for the next
  cp5.get(Textfield.class, "input").clear();
}


// This Bang clears the textfield
public void clear() {
  cp5.get(Textfield.class, "input").clear();
}

// When the load file bang is released, open a file explorer window
void loadFile() {
  myTerminal.append(theTime() + "Loading file...\n");
  selectInput("Select script file to load", "fileLoaded");
}

// See what the user selected as a file
void fileLoaded(File selection) {
  // If no file, print on screen.
  if (selection == null) {
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
    cp5.get(Bang.class, "againFile").show();
  }
  // remove the callback from the Bang or else it never lets us go
  cp5.get(Bang.class, "loadFile").removeCallback();
}


void againFile() {
  if (fileToDump.equals("")) {
    // If there's no value in the variable, no file has been dumped
    myTerminal.append(theTime() + "No file to re-dump\n");
  } else {
    // We have a file, re-dump it.
    println("REDUMPING!!");
    myTerminal.append(theTime() + "Re-Dumping file " + fileToDump + " ...\n");
    myTerminal.scroll(1);
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
  myTerminal.append(theTime() + "Log File: " + theLogLocation + " created...\n");
  myTerminal.append(theTime() + "Terminal ready...\n");
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
    println("Adding port "+ detectedPort + " to the list");
    serialPortsList.addItem(detectedPort, numberofPorts);
    myTerminal.append(theTime() + "Added port: " + detectedPort + " to the list of connections... \n");
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
    myTerminal.append(theTime() + "Lost connection on port: " + detectedPort + "\n");
    myTerminal.append(theTime() + "Please connect a device to continue ... \n");
    myTerminal.scroll(1);
  }
}
