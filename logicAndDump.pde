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
  //delay(0);
  //println("theGCode: " + theGCode + " | and QueuePeek: " + dataQueue.peek() + " | and QueueSize: " + dataQueue.size() + " | and canSend: " + canSend + "| and tinyGBuffer:" + tinyGBuffer);
  //println("Is it valid: " + (theGCode.equals("!\n") || theGCode.equals("!%")));
  //myTerminal.append(theTime() + "Qline:Start" );
  //myTerminal.scroll(1);
  //for (Iterator itr = dataQueue.iterator(); itr.hasNext(); ) {
  //  myTerminal.append(itr.next().toString());
  //  myTerminal.scroll(1);
  //}
  //myTerminal.append(theTime() + "Qline:End" + "| tinygbuffer : " + tinyGBuffer);
  //myTerminal.scroll(2);

  if (theGCode.equals("!\n") || theGCode.equals("!%\n") || theGCode.equals("%\n")) {
    if (!theGCode.equals("!\n")) { 
      dataQueue.clear(); 
      println("Q is clear");
      if (debug == true) myTerminal.append(theTime() + "Flush queue: " + theGCode);
      println("Flush, this gcod:" + theGCode);
      if (debug == true) myTerminal.scroll(1);
      measure = 0;
    }
    myPort.write(theGCode);
    myPort.write("~\n");
    canSend = false;
    if (debug == true) myTerminal.append(theTime() + "Feedhold: " + theGCode);
    println("Eeeee stop, this gcod:" + theGCode);
    if (debug == true) myTerminal.scroll(1);
  } else if (theGCode.equals("~\n") ) {
    //myPort.write(theGCode);
    canSend = true;
    if (debug == true) myTerminal.append(theTime() + "Resuming script: " + theGCode);
    println("Resume, this gcod:" + theGCode);
    if (debug == true) myTerminal.scroll(1);
  }



  if (measure == 1) {
    //GPIO.interrupts();
    delay(10);
    canSend = false;
    theGCode = "G91 G1 A90 F200 \n";
    myPort.write(theGCode);
    if (debug == true) myTerminal.append(theTime() + theGCode);
    if (debug == true) myTerminal.scroll(1);
    measure = 2;
  }
  if (measure == 4) {
    //GPIO.interrupts();
    delay(10);
    canSend = false;
    theGCode = "G91 G1 A-90 F200 \n";
    myPort.write(theGCode);
    if (debug == true) myTerminal.append(theTime() + theGCode);
    if (debug == true) myTerminal.scroll(1);
    measure = 2;
  }
  if (measure == 2)
  {
    //Wait for pin
  }
  if (measure == 3)
  {
    tinyGBuffer =0;
    canSend = true;
    measure = 0;
    //myPort.write("$posa \n");
    //delay(100);
    //myPort.write("g90 g0 a-30.0 \n"); //back off code
  }



  //println("Is Q empty? :" + dataQueue.isEmpty() + "Buffer size:" +  tinyGBuffer);
  while (tinyGBuffer < 2 && dataQueue.size() > 0 && canSend)
  {
    if (dataQueue.peek().toLowerCase().equals("start_measure")) {
      canSend = false;
      measure = 1;
      dataQueue.remove();
      break;
    } else if (dataQueue.peek().toLowerCase().equals("neg_start_measure")) {
      canSend = false;
      measure = 4;
      dataQueue.remove();
      break;
    } else if (dataQueue.peek().toLowerCase().equals("$posa\n")) {
    } else if (dataQueue.peek().toLowerCase().equals("comp\n")) {
      dataQueue.remove();
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
    } else if  (dataQueue.peek().toLowerCase().indexOf("x") > -1)
    {
      String temp[] = split(dataQueue.peek().toLowerCase(), ' ');
      for (int i =0; i < temp.length; i++)
      {
        if (temp[i].indexOf("x") > -1)
        {
          previousFeed = float(temp[i].replaceAll("[^\\d.-]", ""));
        }
      }
      //logger.println("Previous Feed: " + previousFeed + "\n");
      //logger.flush();
      println("This is a feed command with a feed of: " + previousFeed + "\n");
    } else if  (dataQueue.peek().toLowerCase().indexOf("a") > -1)
    {
      String temp[] = split(dataQueue.peek().toLowerCase(), ' ');
      for (int i =0; i < temp.length; i++)
      {
        if (temp[i].indexOf("a") > -1)
        {
          //previousFeed = 0;
          previousAngle = float(temp[i].replaceAll("[^\\d.-]", ""));
        }
      }
      //logger.println("Previous angle: " + previousAngle + "\n");
      //logger.flush();
      println("This is a Angle command with a angle of: " + previousAngle + "\n");
    } else if (dataQueue.peek().toLowerCase().indexOf("end")> -1) {
      println("////////////////////////////////////////////////////");
      println("Reached end of file");
      println("\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\");
      dataQueue.remove();
      myTerminal.append(theTime() + "Reached end of file\n");
      myTerminal.scroll(1);
      if ((repeatLoops-loopsLeft)>0) {
        loopsLeft++;
        myTerminal.append(theTime() + "Sending the file " + (repeatLoops-loopsLeft) + " more times!!!\n");
        myTerminal.scroll(1);
        cp5.get(Textlabel.class, "counter").setText(str(loopsLeft));
      } else {
        myTerminal.append(theTime() + "Done sending the file.\n");
        myTerminal.scroll(1);
        dataQueue.addFirst("!%~");
      }
    } 
    
    sendDataFromQ();
  }//end while
  theGCode = "";
}



void sendDataFromQ()
{
  try{
    //if (! keyWord(dataQueue.peek())) {
    myPort.write( dataQueue.peek() + "\n");
    //if (debug == true) myTerminal.append(theTime() + dataQueue.peek());
    //if (debug == true) myTerminal.scroll(1);
    if (debug == true) myTerminal.append(theTime() + dataQueue.peek());
    println("Queue sending: " + dataQueue.peek());
    logger.println("Sent to TinyG: " + theTime() + dataQueue.peek());
    logger.flush();
    if (debug == true) myTerminal.scroll(1);
    tinyGBuffer ++;
    dataQueue.remove();
    //}
    // else {
    //  if (dataQueue.peek().toLowerCase().equals("start_measure"))
    //  {
    //    measure = 1; 
    //    myTerminal.append(theTime() + dataQueue.peek());
    //    myTerminal.scroll(1);
    //    dataQueue.remove();
    //  }
    //}
  } catch(Exception e) {}
}





// We'll first check what's the file type by checking the extension
// we just need to see if it's a JSON or not.
// If it's a JSON, treat it accordingly, if it's not, treat it as text and
// dump it.
void dumpFile(String theFile) {
  // get how many times we need to repeat the dump
  if (cp5.get(Textfield.class, "numTimes").getText().equals("")) {
    repeatLoops = 1;
  } else {
    repeatLoops = int(cp5.get(Textfield.class, "numTimes").getText());
  }
  loopsLeft = 0;
  cp5.get(Textlabel.class, "counter").setText(str(loopsLeft));

  myTerminal.append(theTime() + "Loading File... \n");
  myTerminal.scroll(1);
  String theLCFile = theFile.toLowerCase(); // so there's no confustion between JSON and json

  // If it's a json let's check if it's the init file to properly send it to the tinyG
  // JSON files are only sent ONE time

  if (theLCFile.endsWith("json") && theLCFile.contains("init")) {
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
  } else {
    // If it's not the init file, then let's just dump whatever is in the file.
    // if it's a JSON but not the init, it will be dumped and the tinyG might complain
    // Rando files will be sent repeatLoops number of times.
    String fileLines[] = loadStrings(theFile);
    println("There are " + fileLines.length + " lines in this file");
    myTerminal.append(theTime() + "Adding " + fileLines.length + " lines to the queue... \n");
    myTerminal.append(theTime() + "Sending the file " + repeatLoops + " time(s)... \n");
    myTerminal.scroll(1);

    for (int n=0; n<repeatLoops; n++) {
      // send the file the number of times the user has indicated in the text field (default 1)
      for (int i=0; i<fileLines.length; i++) {
        if (fileLines[i].toLowerCase().equals("measure")) {
          dataQueue.add("G91 G1 A-7 F10000\n");
          dataQueue.add("G91 G1 X0.0\n");
          dataQueue.add("G91 G1 X0.0\n");
          dataQueue.add("G91 G1 X0.0\n");
          dataQueue.add("start_measure");
          dataQueue.add("$posa\n");
          dataQueue.add("G91 G1 X0.0\n");
          dataQueue.add("G91 G1 X0.0\n");
          dataQueue.add("G91 G1 X0.0\n");
          //dataQueue.add("G90 G0 A-30\n");
        } else if (fileLines[i].toLowerCase().equals("neg_measure")) {
          dataQueue.add("G91 G1 A7 F10000\n");
          dataQueue.add("G91 G1 X0.0\n");
          dataQueue.add("G91 G1 X0.0\n");
          dataQueue.add("G91 G1 X0.0\n");
          dataQueue.add("neg_start_measure");
          dataQueue.add("$posa\n");
          dataQueue.add("G91 G1 X0.0\n");
          dataQueue.add("G91 G1 X0.0\n");
          dataQueue.add("G91 G1 X0.0\n");
          //dataQueue.add("G90 G0 A-30\n");
        } else if (fileLines[i].toLowerCase().equals("home")) {
          println("Dinesh is sad");
        } else {
          dataQueue.add(fileLines[i] + "\n");
        }
        //q_adder(fileLines[i]);       
        //myTerminal.append(theTime() + fileLines[i] + "\n");                 // Put the line on the terminal
        //myTerminal.scroll(1);
      }
      myTerminal.append(theTime() + "File added to the queue. \n");
      myTerminal.scroll(1);
      myTerminal.append(theTime() + "Sending the file " + (repeatLoops-n) + " more times...\n"); 
      myTerminal.scroll(1);
    }//end for repeats
  }
}

Boolean keyWord(String cmd)
{
  if (cmd.toLowerCase().equals("measure\n") || cmd.toLowerCase().equals("home\n") || cmd.toLowerCase().equals("start_measure")) {
    switch (cmd)
    {
      case("measure\n"): //measure the wire angle on its right 
      dataQueue.add("G90 G0 A5");
      dataQueue.add("start_measure");
      dataQueue.add("$posa");
      dataQueue.add("G91 G0 A-30");
      break;
      case("home\n"): 

      break;
      //case("S"): break;
      //case("S"): break;





      //case("S"): break;
      //case("S"): break;
      //case("S"): break;
    default: 
      break;
    }
    return true;
  }
  return false;
}
