/*
* Stuff that sends stuff
 */
import java.io.FileWriter;
import java.io.*;
FileWriter fw;
//BufferWruter bbw;



boolean debug = false;
float smartPinWireAngle = 0;
float previousAngle = 0;
float previousFeed = 0;



void logic()
{
  if (theGCode.equals("!\n")) {
    // this is a feedhold!
    // can resume script (queue) when a '~' is sent
    myPort.write(theGCode);
    reportEvent("Feedhold!" + theGCode);
    reportEvent("Send '~' to resume... " + theGCode);
    canSend = false;
  } else if (theGCode.equals("!%\n") || theGCode.equals("%\n")) {
    // feedhold and flush (full stop)
    // script / queue is flushed both @ tinyG and tinyTerm
    // cannot be resumed by sending '~'
    myPort.write(theGCode);      // first we push the code
    dataQueue.clear();           // then we clear the queue
    tinyGBuffer=0;               // then reset the buffer
    println("Q is clear");
    reportEvent("Halt and flush: " + theGCode);    // then we get chatty
    measure = 0;
    //canSend = false;    // do we need to stop the sending if the queue is clear? meaning: nothing to send?
  } else if (theGCode.equals("~\n") ) {
    myPort.write(theGCode);
    canSend = true;
    reportEvent("Resuming script: " + theGCode);
  } 


  //println("Is Q empty? :" + dataQueue.isEmpty() + "Buffer size:" +  tinyGBuffer);
  while (tinyGBuffer < 2 && dataQueue.size() > 0 && canSend)
  {
    println("Q size: " + dataQueue.size());
    println("Q peek: " + dataQueue.peek());

    if (dataQueue.peek().indexOf('(') >= 0 || dataQueue.peek().indexOf(';') >= 0) {
      // This is a comment. Print on terminal but don't send to tinyG (tinyG doesn't send responses to comments)
      print("Removing a comment: ");
      reportEvent("||" + dataQueue.peek());
      dataQueue.remove();
    } else if (dataQueue.peek().toLowerCase().indexOf("recorda") >= 0) {
      dataQueue.remove();
      // we want to record the A pos into a log file of sorts
      reportEvent(">> TESTING >> Will record posA... \n");
      isTesting = true;
    } else if (dataQueue.peek().toLowerCase().indexOf("cls") >= 0) {
      // Just clear the terminal so it doesn't hog memory
      dataQueue.remove();
      myTerminal.clear();
    }
    //println("can I send? " + canSend); //debug
    sendDataFromQ();
  }//end while
  theGCode = "";
}





void sendDataFromQ()
{
  if (dataQueue.peek().toLowerCase().indexOf("eof") > -1) {
    logger.println("Out > " + theTime() + dataQueue.peek());
    logger.flush();
    //delay(10);
    println("***********");
    println("GOT EOF HERE: " + dataQueue.peek());
    reportEvent("Reached end of file\n");
    reportEvent("Loops Done: " + loopsLeft + "\n");
    cp5.get(Textlabel.class, "counter").setText(str(loopsLeft));
    canAddToQ=true;
    delay(50);
    reportEvent("Can Add again \n");
    println("-----------");
    dataQueue.remove();
    dataQueue.addFirst("!%~\n");


    if ((repeatLoops-loopsLeft)>0) {
      reportEvent("Sending the file " + (repeatLoops-loopsLeft) + " more times!!!\n");
    } else {
      reportEvent("Done looping the file.\n");
    }
  }// if eof

  try {
    myPort.write(dataQueue.peek());
    if (dataQueue.peek().indexOf("$di1fn=0")>-1) {
      statusInterlock=false;
      reportEvent("Removing interlock");
    }
    print("SendQueue ");
    reportEvent("> " + dataQueue.peek());
    logger.println("Out > " + theTime() + dataQueue.peek());
    logger.flush();

    // we only add one to the buffer if it's a "move" command
    // not a tinyG command (start with '$')
    if (dataQueue.peek().indexOf('$')<0) {
      tinyGBuffer ++;
    } else {
      reportEvent("TinyG Command received \n");
    }
    println("tinyGBuffer: " + tinyGBuffer);
    dataQueue.remove();
  } 
  catch(Exception e) {
    tinyGBuffer=0;
    println("Error while writing data to tinyG: " + e);
  }
}





// We'll first check what's the file type by checking the extension
// we just need to see if it's a JSON or not.
// If it's a JSON, treat it accordingly, if it's not, treat it as text and
// dump it.
void dumpFile(String theFile) {
  reportEvent("Loading File... \n");
  String theLCFile = theFile.toLowerCase(); // so there's no confustion between JSON and json

  // If it's a json let's check if it's the init file to properly send it to the tinyG
  // JSON files are only sent ONE time

  if (theLCFile.endsWith("json") && theLCFile.contains("init")) {
    initFile = loadJSONObject(dataPath(theFile));
    // Get the "Commands" array from the init file
    initCommands = initFile.getJSONArray("commands");
    delay(500);
    reportEvent("JSON Loaded... \n");
    delay(250);
    reportEvent("Dumping init file... \n");
    // The tinyG doesn't accept JSONArrays as input, so we need to brake it.
    // So lets extract each command as a JSONObject, and
    // then convert it into a String to be sent via Serial to the tinyG
    for (int i=0; i<initCommands.size(); i++) {

      JSONObject jsonObject = initCommands.getJSONObject(i);    // Get the command
      String sCommand = jsonObject.toString();                  // Make it a String
      sCommand = sCommand.replaceAll("\\s+", "");               // Clean the string
      println("Init Command # " + i + "> " + jsonObject + "\t | to String > " + sCommand);
      myPort.write(sCommand + "\n");                            // Send it to the queue
      //myTerminal.append(theTime() + sCommand + "\n");           // Display the command on the terminal
      //myTerminal.scroll(1);
      //delay(50);
    }
    myPort.write("$ej:0\n");                                  // make sure the last command is in text form
  } else {
    // If it's not the init file, then let's just dump whatever is in the file.
    // if it's a JSON but not the init, it will be dumped and the tinyG might complain
    // Rando files will be sent repeatLoops number of times.
    if (debug) println("repeat loops: " + repeatLoops);
    if (debug) println("Can Add to Q: " + canAddToQ);
    if (debug) println("Im supposed to be here");

    String fileLines[] = loadStrings(theFile);
    reportEvent("Adding " + fileLines.length + " lines to the queue... \n");

    int eofCounter = 0;
    for (int i=0; i<fileLines.length; i++) {
      if (fileLines[i].equals("")) {
        if (debug) println("Empty line, skip");
      } else if (fileLines[i].indexOf('(')>=0) {
        if (debug) println("Comment line, skip");
      } else if (fileLines[i].toLowerCase().equals("eof")) {
        eofCounter++;
        dataQueue.add(fileLines[i] + "\n");
        println("Got EOF");
      } else {
        if (debug) println("Adding line " + i + " to the Q");
        if (i == fileLines.length && eofCounter == 0) { // we went through the whole thing but didn't find an EOF
          println("Adding EOF cuz didn't find it");
          dataQueue.add("EOF\n");
        }
        dataQueue.add(fileLines[i] + "\n");
        delay(1);
      }
      //reportEvent(fileLines[i] + "\n");                 // Put the line on the terminal
    }//end FOR
  }//end else
  canAddToQ = false;
  loopsLeft++;
  reportEvent("File added to the queue. \n");
  if (debug) println("Can't add anything to the q now");
  if (debug) println("Loops left: " + loopsLeft);
}//end func






void compensateAngle() {
  float tempAngle = smartPinWireAngle + float(dataQueue.peek().replaceAll("[^\\d.-]", ""));

  println("New Angle to goto : " + tempAngle);
  //material profie comes here
  //logger.println("Comp new angle to go to is: " + tempAngle +" :Current wire angle is: " + smartPinWireAngle +" :Desired Wire angle is: "+ float(dataQueue.peek().replaceAll("[^\\d.-]", "")) + "\n");
  //logger.flush();

  tempAngle = -0.00000000001339184*pow(tempAngle, 6) + 0.000000006227119*pow(tempAngle, 5) - 0.000001067801*pow(tempAngle, 4) + 0.00009016468*pow(tempAngle, 3) - 0.005157139*pow(tempAngle, 2) + 0.9794736*tempAngle - 11.62875;
  //logger.println("Pin position that will bend the new desired wire angle is : " + tempAngle + "\n\n");
  //logger.flush();

  previousAngle =float(dataQueue.peek().replaceAll("[^\\d.-]", ""));
  String temp = "G90 G0 A"+tempAngle;
  println("Comp added gcode : " + dataQueue.peek());
  dataQueue.remove();
  dataQueue.addFirst(temp);
}



// Handy function to publish events both on the terminal
// and on the serial console. This will save us some lines
// of code
void reportEvent(String theEvent) {
  myTerminal.append(theTime() + theEvent);
  myTerminal.scroll(1);
  theEvent =theEvent.replaceAll("\n", "");
  println(theEvent);
}

String thePath() {
  //String fileName = dataPath("") + theDate() + ".csv";
  String fileName = dataPath("") + "HomingTest_1" + ".csv";
  return fileName;
}




void aPosToFile(String filename, float thePosA) {
  File f = new File(dataPath(filename));
  if (!f.exists()) {
    createFile(f);
  }
  try {
    PrintWriter out = new PrintWriter(new BufferedWriter(new FileWriter(f, true)));
    out.println(thePosA);
    out.close();
    reportEvent("Recorded PosA... \n");
  }
  catch (IOException e) {
    e.printStackTrace();
  }
  canAddToQ = true;
}


void createFile(File f) {
  File parentDir = f.getParentFile();
  try {
    parentDir.mkdirs(); 
    f.createNewFile();
  }
  catch(Exception e) {
    e.printStackTrace();
  }
}    


















/*
  if (measure>0) {
 switch (measure) {
 case 1:
 //GPIO.interrupts();
 delay(10);
 canSend = false;
 theGCode = "G91 G1 A90 F200 \n";
 myPort.write(theGCode);
 if (debug == true) myTerminal.append(theTime() + theGCode);
 if (debug == true) myTerminal.scroll(1);
 measure = 2;
 break;
 
 case 2:
 // wait for pin
 break;
 
 case 3:
 tinyGBuffer = 0;
 canSend = true;
 measure = 0;
 //myPort.write("$posa \n");
 //delay(100);
 //myPort.write("g90 g0 a-30.0 \n"); //back off code
 break;
 
 case 4:
 //GPIO.interrupts();
 delay(10);
 canSend = false;
 theGCode = "G91 G1 A-90 F200 \n";
 myPort.write(theGCode);
 if (debug == true) myTerminal.append(theTime() + theGCode);
 if (debug == true) myTerminal.scroll(1);
 measure = 2;
 break;
 
 default:
 break;
 }//end switch
 }//end if measure
 */


/*
     
 for (int n=0; n<repeatLoops; n++) {
 // send the file the number of times the user has indicated in the text field (default 1)
 for (int i=0; i<fileLines.length; i++) {
 if (fileLines[i].equals("")) {
 println("Empty line, skip");
 } else if (fileLines[i].indexOf('(')>=0) {
 println("Comment line, skip");
 } else {
 dataQueue.add(fileLines[i] + "\n");
 delay(1);
 }
 //reportEvent(fileLines[i] + "\n");                 // Put the line on the terminal
 }
 reportEvent("File added to the queue. \n");
 reportEvent("Sending the file " + (repeatLoops-n) + " more times...\n");
 */
