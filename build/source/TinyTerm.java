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
// It opens a serial connection and searches for the tinyG,
// Then dumps the "Commands" string to the tinyG
// The interface is created using the controlP5 library.
//
//  The complete list of tinyG commands and settings can be found @
//  https://github.com/synthetos/TinyG/wiki/TinyG-Configuration-for-Firmware-Version-0.97
//
//  The commands being dumped by this script are:
//  $gun=1 : set units = mm
//  $2ma=0 : MOTOR2 mapped to axis X (Motor 2 is being used, change to your motor)
//  $2po=0 : polarity 0 = normal, 1 = inverted
//  $2pl=1 : power level = 100%
//  $2pm=2 : power mode = ON While In Cycle
//  $2mi=10 : Microsteps = 10usteps (per your driver/application)
//  $2sa=1.8 : Step Angle = 1.8 deg/step (per your motor)
//  $xtr=7.10059 : Travel per rev = 7.10059mm/motor rev (13:1 gearbox x 3.9:1 pulley)
//  $xvm=10000 : X Vel max = 10,000mm/min
//  $xjm=20000 : X Jerk max = 20,000xE6 mm/s3
//  $xfr=10000 : X feed max = 10,000mm/min
//
//  Add any other needed settings to the "Commands" string, separating them by '\n'
//
//  The GUI then gives you a text box to type your desired GCode or tinyG Commands

// Imports



// GUI
ControlP5 cp5;
boolean buttonFlag=false;

// String variables
String commands = "$gun=1\n$3ma=0\n$3po=0\n$3pl=1.0\n$3pm=2\n$3mi=10\n$3sa=1.8\n$3tr=7.10059\n$xvm=10000\n$xjm=500\n$xfr=10000\n$1ma=4\n$gpa=1";
String theGCode = "G91 G1 X100 F100\n"; // Whatever you want to have as default text in the textbox

// The Init.JSON file to be loaded
JSONObject initFile;
JSONArray initCommands;
String jPath;

// The serial port:
Serial myPort;  // Create object from Serial class

//misc variables
int x = 50;             // Position on the X axis
int y = 50;             // Position on the Y axis
int tfh = 50;           // textfield height
int taw;                // textArea width
int tah;                // textArea height
int bw = 100;           // width of Bang
int theWidth = 600;     // applet width
int theHeight = 800;    // applet height
int pad = 20;           // padding between fields
Textarea myTerminal;    // CP5 control for the text area
PFont font;             // the font for the script

// Use "Settings" to assign the size of the applet with variables.
public void settings(){
  size(theWidth,theHeight);
}


public void setup()
{
  // Start the serial
  // List all the available serial ports, check the terminal window and select find the port# for the tinyG
  // printArray(Serial.list());
  // Open whichever port the tinyG uses in your computer (8 in mine):
  // myPort = new Serial(this, Serial.list()[8], 9600);
  // Dump the init commands to the tinyG via serial port

  font = createFont("arial", 20); // big arial font
  startGUI();

  // Load the inti file (JSON in /data folder)
  initFile = loadJSONObject(dataPath("init.json"));

  // Get the "Commands" array from the init file
  initCommands = initFile.getJSONArray("commands");
  // Convert the array of commands to a string
  String comm = initCommands.toString();
  println("commands to send: \n" + comm);
  // Send it to the terminal
  myTerminal.append(comm);
  myTerminal.update();
  myTerminal.scroll(1);
  myTerminal.append("\n");

  delay(20);
  // Dump the commands to the tinyG via serial and show it in the terminal
  myPort.write(comm);


  textFont(font);
}



public void draw() {
  background(0);  //black BG
  //read response from tinyG
  while (myPort.available () > 0) {
    String inBuffer = myPort.readString();
    if (inBuffer != null) {
      println(inBuffer);
      myTerminal.append(inBuffer);
      myTerminal.update();
      myTerminal.scroll(1);
    }
  }
  fill(255);
  stroke(255);
  text("TinyTerm:", x, y-pad);
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
      // myPort.write(theGCode);
      myTerminal.append(theGCode);
      myTerminal.update();
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
  myTerminal.append(theGCode);
  myTerminal.update();
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



// Let's work on the GUI
public void startGUI(){
  // Construct a CP5
  cp5 = new ControlP5(this);            // start the cp5 GUI

  // Define the size of the text area
  taw = width - (2*x);
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
