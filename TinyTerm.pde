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
import controlP5.*;
import processing.serial.*;

// GUI
ControlP5 cp5;
boolean buttonFlag=false;

// String variables
String theGCode = "G91 G1 X100 F100\n"; // Whatever you want to have as default text in the textbox
String jPath;                           // the path where the JSON file is

// The Init.JSON file to be loaded
JSONObject initFile;      // This will receive the JSON file as an object
JSONArray initCommands;   // we will extract the "commands" array of JSONObjects here

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
int theHeight = 600;    // applet height
int pad = 20;           // padding between fields
Textarea myTerminal;    // CP5 control for the text area
PFont font;             // the font for the script

// Use "Settings" to assign the size of the applet with variables.
void settings(){
  size(theWidth,theHeight);
}


void setup()
{
  size(600,600);      //Just if you have a really old version of Processing. Like this laptop.
  // Start the serial
  // List all the available serial ports, check the terminal window and select find the port# for the tinyG
  printArray(Serial.list());
  // Open whichever port the tinyG uses in your computer (8 in mine):
  myPort = new Serial(this, Serial.list()[8], 9600);


  font = createFont("arial", 20); // big arial font
  startGUI();

  myTerminal.append("Loading JSON... \n");
  delay(50);
  // Load the inti file (JSON in /data folder)
  initFile = loadJSONObject(dataPath("init.json"));
  // Get the "Commands" array from the init file
  initCommands = initFile.getJSONArray("commands");

  myTerminal.append("JSON Loaded... \n");
  delay(50);
  myTerminal.append("Dumping init file... \n");

  // The tinyG doesn't accept JSONArrays as input, so we need to brake it.
  // So lets extract each command as a JSONObject, and
  // then convert it into a String to be sent via Serial to the tinyG
  for(int i=0; i<initCommands.size(); i++){
    JSONObject jsonObject = initCommands.getJSONObject(i);    // Get the command
    String sCommand = jsonObject.toString();                  // Make it a String
    sCommand = sCommand.replaceAll("\\s+", "");               // Clean the string
    println("Init Command # " + i + "> " + jsonObject + "\t | to String > " + sCommand);
    myPort.write(sCommand + "\n");                            // Send it to the tinyG
    myTerminal.append(sCommand + "\n");                       // Display the command on the terminal
    delay(20);                                                // Let it process.
  }
  myTerminal.append("Init dumped...\n");
  myTerminal.append("Listening for the report... \n");
  // Init Dumped. Terminal ready
  while (myPort.available () > 0) {
    String inBuffer = myPort.readString();
    if (inBuffer != null) {
      println(inBuffer);
      myTerminal.append(inBuffer);
      // myTerminal.update();
      myTerminal.scroll(1);
    }
  }
  myTerminal.append("TinyG Ready... \n\n");
  //myTerminal.update();
  myTerminal.scroll(1);

  textFont(font);
}



void draw() {
  background(0);  //black BG
  //read response from tinyG
  while (myPort.available () > 0) {
    String inBuffer = myPort.readString();
    if (inBuffer != null) {
      println(inBuffer);
      myTerminal.append(inBuffer);
      // myTerminal.update();
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
void controlEvent(ControlEvent theEvent) {
  // Get text from the command line and send it
  if(theEvent.isAssignableFrom(Textfield.class)){
    theGCode = theEvent.getStringValue();
    if(theGCode != ""){
      theGCode = theGCode + "\n";
      println("Command sent: " + theGCode);
      // Send command to the tinyG
      myPort.write(theGCode);
      myTerminal.append(theGCode);
      // myTerminal.update();
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
  // myTerminal.update();
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
void startGUI(){
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
