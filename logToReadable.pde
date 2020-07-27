PrintWriter output;
String loadFile, saveFile;

void cleanMyFile(){
  cp5.get(Bang.class,"cleanMyFile").removeCallback();
  reportEvent("Choose file to clean...\n");
  selectInput("Select a Log file to clean...", "theSelection");
}


void theSelection(File theFile){
  cp5.get(Bang.class,"cleanMyFile").removeCallback();
  if(theFile == null){
    println("NO FILE...");
  } else {
    loadFile = theFile.getAbsolutePath();
    reportEvent("Choose where to save the clean file...\n");
    selectOutput("Where do you want to save your spanky new logFile?","theSaves");
  }

}


void theSaves(File theSFile){
  cp5.get(Bang.class,"cleanMyFile").removeCallback();
  if(theSFile == null){
    reportEvent("Don't dare fuck with me again...\n");
  } else {
    output = createWriter(theSFile.getAbsolutePath());
    String lines[] = loadStrings(loadFile);
    println(lines.length);
    for(int i=0;i<lines.length;i++){
      // println(lines[i]);
      if(i==0){
        println(i + ": " + lines[i]);
        output.println("# " + lines[i]);
      }
      else {
        println(i + ": " + lines[i]);
        output.println(i + ": " + lines[i]);
      }
      delay(10);
    }
    output.flush();
    output.close();
    reportEvent("Logfile " + loadFile + " is now human-readable\n");
  }
}
