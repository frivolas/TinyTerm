String[] homingSequencePT1 = {
  "G90 G0 Z-12.5\n", 
  "G28.2 A0\n", 
  "G91 G0 A30\n", 
  "$di1fn=2\n", 
  "G91 G0 A1\n", 
  "G91 G1 A-30 F250\n", 
};

String[] homingSequencePT2 = {
  "~\n",
  "G91 G0 A0\n",
  "G90 G0 A", 
  "G28.3 A0\n", 
  "G90 G0 Z0 A20\n"
};


void letsHome(char theAxis) {
  isHoming = true;
  isHomed = false;
  switch (theAxis) {
  case 'a':
    // home A (bend) axis only
    // assumes all other axes are homed
    for (int k=0; k<homingSequencePT1.length; k++) {
      dataQueue.add(homingSequencePT1[k]);
    }
    break;
  case 'x':
    // home X (feed) axis only
    dataQueue.add("G28.2 X0\n");
    break;
  case 'z':
    // home Z (duck) axis only
    dataQueue.add("G28.2 Z0\n");    
    break;
  case '*':
    // home all axes
    // Add the first chunk of the homing sequence to the queue
    dataQueue.add("G28.2 Z0 X0\n");
    for (int k=0; k<homingSequencePT1.length; k++) {
      dataQueue.add(homingSequencePT1[k]);
    }
    break;
  default:
    break;
  }
}


void homePT2(float posA) {
  // isHoming=true;
  // append the result of $posA to the second line
  homingSequencePT2[2] += str(posA/2);
  homingSequencePT2[2] += "\n";
  println("GOT THIS POS: " + homingSequencePT2[2]);
  // add the chunk to the queue
  for (int i=1; i<homingSequencePT2.length; i++) {
    dataQueue.add(homingSequencePT2[i]);
  }
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
