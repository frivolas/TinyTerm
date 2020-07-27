// Let's work on the GUI
void startGUI() {
  // Construct a CP5
  cp5 = new ControlP5(this);            // start the cp5 GUI

  // Define the size of the text area
  taw = width - (2*x) - bw - pad;
  tah = height - y-(3*pad)-tfh;

  // Add a textArea to capture the incoming serial
  myTerminal = cp5.addTextarea("serialText")
    .setPosition(x, y)
    .setSize(taw, tah)
    .setFont(createFont("courier", 14))
    .setLineHeight(14)
    .setColor(color(190))
    .setBorderColor(color(0))
    .setColorBackground(color(200, 100))
    .setColorForeground(color(255))
    .setScrollBackground(color(200, 100))
    .setScrollActive(color(128))
    .showScrollbar()
    .showArrow()
    ;

  // Add a textfield to allow code injection to the tinyG
  cp5.addTextfield("input")
    .setPosition(x, y + tah + pad)     // up and to the left
    //.setSize(taw-bw-pad, tfh)         // make it big
    .setSize(taw, tfh)         // make as big as the textarea
    .setFont(font)
    .setFocus(false)
    .setText(theGCode)
    .setColor(color(255))
    .setColorBackground(color(200, 100))
    .setColorForeground(color(255))
    .setColorActive(color(230, 100))
    .setAutoClear(true)
    ;

  // create a new button with name 'Send' to shoot the command to the tinyG
  /*
  cp5.addBang("Send")
   .setPosition(x+taw-bw, y+tah+pad)
   .setSize(bw, tfh)
   .setColorBackground(color(180, 40, 50))
   .setColorActive(color(180, 40, 50))
   .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
   ;
   */

  // create a new button to quickly dump the init file to the tinyG
  cp5.addBang("loadFile")
    .setCaptionLabel("Load File")
    .setPosition(x+taw+pad, y)
    .setSize(bw, sbh)
    .setColorBackground(color(180, 40, 50))
    .setColorActive(color(180, 40, 50))
    .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
    ;

  // create a new button to re-dump the last opened file to the tinyG
  cp5.addBang("againFile")
    .setCaptionLabel("Re-Dump File")
    .setPosition(x+taw+pad, y+tah+pad)
    .setSize(bw, tfh)
    .setColorBackground(color(180, 40, 50))
    .setColorActive(color(180, 40, 50))
    .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
    ;

  cp5.addBang("Repeat")
    .setCaptionLabel("Send")
    .setPosition(x+taw+pad, y+ 4*sbh + 4*pad)
    .setSize(bw/3, tfh/2)
    .setColorForeground(color(10, 10, 50))
    .setColorActive(color(0,0,0))
    .getCaptionLabel().align(ControlP5.LEFT, ControlP5.CENTER)
    ;

  cp5.addTextfield("numTimes")
    .setFocus(true)
    .setSize(x, tfh/2)
    .setPosition(x+taw+1.5*pad+(bw/3), y+ 4*sbh + 4*pad)
    .setSize(bw/3, tfh/2)
    .setText("1")
    .setColor(color(255))
    .setColorBackground(color(200, 100))
    .setColorForeground(color(255))
    .setColorActive(color(230, 100))
    .setAutoClear(false)
    .setCaptionLabel("")
    .setFont(createFont("Arial", 12))
    ;

  cp5.addBang("times")
    .setCaptionLabel(" times")
    .setPosition(x+taw+2*pad+(2*bw/3), y+ 4*sbh + 4*pad)
    .setSize(bw/2, tfh/2)
    .setColorForeground(color(0, 0, 0))
    .setColorActive(color(0,0,0))
    .getCaptionLabel().align(ControlP5.LEFT, ControlP5.CENTER)
    ;

  cp5.addTextlabel("counter")
    .setPosition(x+taw+2*pad+bw/4, y+tah-tah/4)
    .setSize(bw,tfh)
    .setColorValue(0xffffffff)
    .setColorActive(color(50,50,50))
    .setColorForeground(color(50,50,50))
    .setFont(createFont("Arial", 40))
    ;

  // create a new button to save the log
  cp5.addBang("saveLog")
    .setTriggerEvent(Bang.RELEASE)
    .setCaptionLabel("Save Log")
    .setPosition(x+taw+pad, y+sbh+pad)
    .setSize(bw, sbh)
    .setColorBackground(color(180, 40, 50))
    .setColorActive(color(180, 40, 50))
    .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
    ;

  // create a new button to make the logFile human readable
  cp5.addBang("cleanMyFile")
    .setTriggerEvent(Bang.RELEASE)
    .setCaptionLabel("Make Log Readable")
    .setPosition(x+taw+pad, y+(2*sbh)+(2*pad))
    .setSize(bw, sbh)
    .setColorBackground(color(180, 40, 50))
    .setColorActive(color(180, 40, 50))
    .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
    ;

  serialPortsList = cp5.addScrollableList("serialports")
    .setPosition(x+taw+pad, y+(3*sbh)+(3*pad))
    .setSize(bw, 50)
    .setType(ScrollableList.LIST)
    ;
}

void guiHide() {
  // Hide all controls until the Serial has been established
  //cp5.get(Bang.class, "Send").hide();                        // hide the "re-dump" bang
  cp5.get(Bang.class, "loadFile").hide();                        // hide the "re-dump" bang
  cp5.get(Bang.class, "againFile").hide();                        // hide the "re-dump" bang
  cp5.get(Bang.class, "saveLog").hide();                        // hide the "re-dump" bang
  cp5.get(Bang.class, "cleanMyFile").hide();                        // hide the "re-dump" bang
  cp5.get(Textfield.class, "input").hide();                    // hide the text field
  //cp5.get(Textlabel.class, "Repeat").hide();                    // hide the text field
  cp5.get(Bang.class, "Repeat").hide();                    // hide the text field
  cp5.get(Textfield.class, "numTimes").hide();                    // hide the text field
  cp5.get(Bang.class, "times").hide();                    // hide the text field
  cp5.get(Textlabel.class, "counter").hide();
}

void guiShow() {
  // Hide all controls until the Serial has been established
  //  cp5.get(Bang.class, "Send").show();                        // hide the "re-dump" bang
  cp5.get(Bang.class, "loadFile").show();                        // hide the "re-dump" bang
  // cp5.get(Bang.class,"againFile").show();                        // hide the "re-dump" bang
  cp5.get(Bang.class, "saveLog").show();                        // hide the "re-dump" bang
  cp5.get(Bang.class, "cleanMyFile").show();                        // hide the "re-dump" bang
  cp5.get(Textfield.class, "input").setCaptionLabel("");
  cp5.get(Textfield.class, "input").show();                    // hide the text field
  //cp5.get(Textlabel.class, "Repeat").show();                    // hide the text field
  cp5.get(Bang.class, "Repeat").show();                    // hide the text field
  cp5.get(Textfield.class, "numTimes").show();                    // hide the text field
  cp5.get(Bang.class, "times").show();                    // hide the text field
  cp5.get(Textlabel.class, "counter").show();
}
