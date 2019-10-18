String[] homingSequencePT1 = {
  "G90\n", 
  "G0 Z-9\n", 
  "G28.2 A0\n", 
  "G1 A30 F5000\n", 
  "$di1fn=2\n", 
  "G1 A-30 F500\n",
  "$posa\n"
};

String[] homingSequencePT2 = {
  "%\n", 
  "g90 g0 a", 
  "G28.3 A0\n", 
  "G0 Z0\n", 
  "$di1fn=0\n"
};




void letsHome() {
  isHoming = true;

  for (int k=0; k<homingSequencePT1.length; k++) {
    //myPort.write(homingSequencePT1[k]);
    dataQueue.add(homingSequencePT1[k]);
    //delay(100);
  }

  logic();

 // while (homingEdgePos == 0) {
    //logic();
    //println("Loop of doom");
    
    while (myPort.available () > 0) {
      String inBuffer = myPort.readStringUntil(10);  //10 = LF
      if (inBuffer != null) {
        if (inBuffer.indexOf("stat:3")>0 || inBuffer.indexOf("\"stat\":3")>0)         // catch if the tinyG is done (reports stat:3) 
        {
          println("Buffer Reset");
          println("dataQueue.size() = "+ dataQueue.size() );
          tinyGBuffer = 0;
          println("DONE!");
        }
        print("Incoming: " + inBuffer + "\n");
        if (inBuffer.indexOf("position:")>0) {
          println("GOT POS!");
          // here is where you catch the position from the string
          String testingThis = inBuffer.substring(inBuffer.indexOf("position")+9);
          println(testingThis);
          myTerminal.append(testingThis);
          myTerminal.scroll(1);
          //homingEdgePos = float(name_of_the_string_where_you_got_posa);
          //
        }
      }
   // }
  }
}

  // add something here to make sure we caught posA

void homeAlone(){
  println(homingSequencePT2[0]+ str(homingEdgePos));
  dataQueue.add(homingSequencePT2[0]+ str(homingEdgePos/2));
  delay(50);
  for (int l=1; l<homingSequencePT2.length; l++) {
    //myPort.write(homingSequencePT2[l]);
    dataQueue.add(homingSequencePT2[l]);
    //delay(50);
  }
  homingEdgePos = 0;
  isHoming = false;
}























/* Old useless homing
 
 dataQueue.add("G90\n");
 dataQueue.add("G0 Z-9\n");
 dataQueue.add("G28.2 A0\n");
 dataQueue.add("G1 A30 F5000\n");
 dataQueue.add("$di1mo=2\n");
 dataQueue.add("G1 A-30 F500\n");
 dataQueue.add("%\n");
 dataQueue.add("$posa\n");
 // here you listen for the response
 // divide the position / 2
 //move there:
 dataQueue.add("g90 g0 a___"); // where ___ is the position you calculated
 dataQueue.add("G28.3 A0\n");
 dataQueue.add("G0 Z0\n");
 dataQueue.add("$fi1fn=0\n");
 
 */
