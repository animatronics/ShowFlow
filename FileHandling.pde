///////////////////////////////////////////////////////
// This file is part of "main" applet, but was thrown
// in a different file for my convenience
///////////////////////////////////////////////////////

void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected " + selection.getAbsolutePath());

    path = selection.getAbsolutePath();
    int i = path.lastIndexOf(File.separator);
    if (i != path.length()-1) {
      project_name = path.substring(i+1);
    } else {
      project_name = path;
    }
    path = path+"/";
    File dir = new File(selection.getAbsolutePath());
    dir.mkdir();

    File datadir = new File(path+"/data");
    datadir.mkdir();

    // Do things to make the project new, like emptying data and initing the counters
    clearData();
    PPScene s1 = creator.createScene("", 100, 100, scene_cnt);
    addScene(s1);
    controller.clearSelections();
    controller.scenes = scenes;
    controller.trans = trans;
    isUpdated = true;
    controller.activate(controller.active_view);
  }
}

void fileForSaveSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected " + selection.getAbsolutePath());

    path = selection.getAbsolutePath();
    project_name = selection.getName();
    path = path+"/";
    File dir = new File(selection.getAbsolutePath());
    dir.mkdir();
    File datadir = new File(path+"/data");
    datadir.mkdir();
    saveToFile();
  }
}
void saveToFile() {
  String file_name;
  if (project_name == "") {
    file_name = path+"/Default.json";
    controller.saveFile();
    return;
  } else {
    file_name = path+"/"+project_name+".json";
  }
  JSONArray values = new JSONArray();
  int i = 0;
  for (int j=0; j<vars.size (); j++, i++) {
    PPData d = vars.get(j);
    JSONObject jo = d.writeToJSON();
    if (jo != null) values.setJSONObject(i, jo);
  }
  for (int j = 0; j<hardware.size (); j++) {
    PPData d = hardware.get(j);
    if (d.type == "hardware controller") {
      JSONObject jo = d.writeToJSON();
      if (jo != null) {
        values.setJSONObject(i, jo);
        i++;
      }
    }
  }
  for (int j = 0; j<hardware.size (); j++) {
    PPData d = hardware.get(j);
    if (d.type != "hardware controller") {
      JSONObject jo = d.writeToJSON();
      if (jo != null) {
        values.setJSONObject(i, jo);
        i++;
      }
    }
  }
  for (int j = 0; j<data.size (); j++) {
    PPData d = data.get(j);
    if (d.type == "scene" || d.type == "transition") {
      JSONObject jo = d.writeToJSON();
      if (jo != null) values.setJSONObject(i, jo);
      i++;
    }
  }

  // get the values of the two counters too
  JSONObject s_cnt = new JSONObject();
  s_cnt.setInt("scene_counter", scene_cnt.count);
  s_cnt.setString("type", "scene counter");
  values.setJSONObject(i++, s_cnt);
  JSONObject t_cnt = new JSONObject();
  t_cnt.setInt("track_counter", track_cnt.count);
  t_cnt.setString("type", "track counter");
  values.setJSONObject(i++, t_cnt);
  JSONObject d_cnt = new JSONObject();
  d_cnt.setInt("data_counter", data_cnt.count);
  d_cnt.setString("type", "data counter");
  values.setJSONObject(i++, d_cnt);
  // write to the file defined during project initiation
  saveJSONArray(values, file_name);
  message("File saved.");
}
void loadFile() {
  selectInput("Select a JSON file to load:", "loadFileSelected");
}

void loadFileSelected(File selected) {
  if (selected == null) {
    println("Window was closed or the user hit cancel.");
    return;
  } else {
    println("User selected " + selected.getAbsolutePath());
  }
  clearData();
  String separator= File.separator;
  String file_name = selected.getAbsolutePath();
  int i1 = file_name.lastIndexOf(separator);
  path = file_name.substring(0, i1);
  int i2 = file_name.lastIndexOf(".");
  project_name = file_name.substring(i1+1, i2);
  JSONArray values = loadJSONArray(selected);
  for (int i = 0; i < values.size (); i++) {

    JSONObject data = values.getJSONObject(i); 
    String type = data.getString("type");
    if (type.equals("hardware controller")) {
      PPData h = createHardware();
      h.readFromJSON(data);
    } else if (type.equals("actuator")) {
      PPData a = createActuator();
      a.readFromJSON(data);
    } else if (type.equals("sensor")) {
      PPData s = createSensor();
      s.readFromJSON(data);
    } else if (type.equals("timer")) {
      PPData t = createTimer();
      t.readFromJSON(data);
    } else if (type.equals("variable event")) {
      PPData v = createVariableEvent();
      v.readFromJSON(data);
    } else if (type.equals("scene")) {
      PPScene s = creator.createScene("", width/2 - 50, height/3 + 50, scene_cnt);
      addScene(s);
      s.readFromJSON(data);
    } else if (type.equals("transition")) {
      PPScene s = (PPScene)scenes.get(0);
      PPData t = addTrans(s, s);
      t.readFromJSON(data);
    } else if (type.equals("variable")) {
      PPData v = createVariable();
      v.readFromJSON(data);
    } else if (type.equals("data counter")) {
      data_cnt.count = data.getInt("data_counter");
    } else if (type.equals("track counter")) {
      track_cnt.count = data.getInt("track_counter");
    } else if (type.equals("scene counter")) {
      scene_cnt.count = data.getInt("scene_counter");
    }
  }
  controller.clearSelections();
  controller.scenes = scenes;
  controller.trans = trans;
  controller.sceneview.variables.setData(vars);
  isUpdated = true;
  controller.activate(controller.active_view);
  message("File loaded");
}

StringList processing_code = new StringList();
StringList actions_code = new StringList();
StringList arduino_code = new StringList();

//////////////////////////////////////////////////////////////////////////
// Function that generate the processing and arduino codes
//////////////////////////////////////////////////////////////////////////
void generateProcessingCode() {
  processing_code = new StringList();
  String str ="";
  PPData[] controllers = getControllersList();
  processing_code.append("import ddf.minim.*;");
  processing_code.append("import processing.serial.*;");
  processing_code.append("");
  processing_code.append("///////////////////////////////");
  processing_code.append("// declaring states");
  processing_code.append("///////////////////////////////");
  for (int i = 0; i<2*scenes.size (); i++) {
    str = scenes.get(i/2).name.toUpperCase();
    str = str.replaceAll(" ", "_");
    processing_code.append( "final static int "+str+"_PLAYING = "+int(i++) +";");
    processing_code.append( "final static int "+str+"_WAITING = "+i+";");
  }
  processing_code.append("");
  processing_code.append("///////////////////////////////");
  processing_code.append("// global variables");
  processing_code.append("///////////////////////////////");
  processing_code.append("Minim minim;");
  String first="";
  for (int i = 0; i<scenes.size (); i++) {
    str = scenes.get(i).name.toUpperCase().replaceAll(" ", "_");
    if (((PPScene)scenes.get(i)).isStart) {
       first = str;       
    }
    processing_code.append( "boolean "+str+"_started_playing = false;");
    processing_code.append( "boolean "+str+"_started_waiting = false;");
  }
  // Variables
  for (int i=0; i<vars.size(); i++) {
      processing_code.append( "int "+vars.get(i).name+" = "+ ((Variable)vars.get(i)).base_value+";");
  }
  for (int i=0; i<controllers.length; i++) {
      processing_code.append( "Serial "+controllers[i].name+str(controllers[i].id)+";");
  }
  PPData[] sensors = getSensorsList();
  for (int i=0; i<sensors.length; i++) {
    if (((Sensor)sensors[i]).hardware != null){
      processing_code.append( "int "+((Sensor)sensors[i]).hardware.name+((Sensor)sensors[i]).hardware.id+"_"+sensors[i].name+sensors[i].id+"_value = 0;");
    }
  }
  for (int i=0; i<scenes.size(); i++) {
    PPScene s = (PPScene)scenes.get(i);
    for (int j=0; j < s.scene_data.size(); j++) {
      if (s.scene_data.get(j).type == "animation") {
          processing_code.append("// "+s.name.replaceAll(" ", "_")+"_"+s.scene_data.get(j).name.replaceAll(" ", "_") + " is declared in actions.pde");
          actions_code.append("int[] "+s.name.replaceAll(" ", "_")+"_"+s.scene_data.get(j).name.replaceAll(" ", "_")+" = {"+join(str(((PPAnimation)s.scene_data.get(j)).actions), ", ")+"};");
          actions_code.append("");    
      }
    }
  }
  for (int i=0; i<scenes.size(); i++) {
    PPScene s = (PPScene)scenes.get(i);
    for (int j=0; j < s.scene_data.size(); j++) {
      if (s.scene_data.get(j).type == "audio") {
          processing_code.append("String "+s.name.replaceAll(" ", "_")+"_"+s.scene_data.get(j).name.replaceAll(" ", "_") + " = \""+ ((PPAudio)s.scene_data.get(j)).file_name +"\";" ); 
      }
    }
  }
  processing_code.append("int time_ms = 0;      // current time in ms");
  processing_code.append("int time_elapsed = 0; // num of ms passed while in current state");
  processing_code.append("int delta_t = 0;      // num of ms since last loop"); 
  processing_code.append("int current_state = "+first+"_PLAYING;");
  processing_code.append(""); 
  processing_code.append("///////////////////////////////");
  processing_code.append("// setup - initialize variables, start serial communication");
  processing_code.append("///////////////////////////////");
  processing_code.append("void setup() {");
  processing_code.append("  size(400, 200);");
  processing_code.append("  background(0);");
  processing_code.append("  textSize(36);");
  
  processing_code.append("  fill(255); // white text on black");
  processing_code.append("  minim = new Minim(this);");
  for (int i=0; i<controllers.length; i++) {
      processing_code.append( "  "+controllers[i].name+str(controllers[i].id)+" = new Serial(this, \""+((HardwareController)controllers[i]).port_name+"\", 9600);");
  }
  processing_code.append("  time_ms = millis();");
  processing_code.append("  "+first+"_started_playing = true;");
  processing_code.append("}");
  processing_code.append("");
  processing_code.append("///////////////////////////////");
  processing_code.append("// main loop");
  processing_code.append("///////////////////////////////");
  processing_code.append("void draw() {");
  processing_code.append("  delta_t = millis() - time_ms;");
  processing_code.append("  time_ms = millis();");
  processing_code.append("");
  processing_code.append("  arduinoRead();");
  processing_code.append("");
  processing_code.append("  background(0);");
  for (int i = 0; i<2*scenes.size (); i++) {
    String condition = (i==0) ? "if" : "else if";
    str = scenes.get(i/2).name.toUpperCase();
    str = str.replaceAll(" ", "_");
    processing_code.append( "  "+condition + " (current_state == "+str+"_PLAYING) {");
    processing_code.append( "    text(\"playing "+scenes.get(i/2).name.replaceAll(" ", "_")+"\", 20, 40);");
    processing_code.append( "    play_"+scenes.get(i/2).name.replaceAll(" ", "_")+"();");
    processing_code.append( "  }");
    i++;
    processing_code.append( "  "+"else if (current_state == "+str+"_WAITING) {");
    processing_code.append( "    text(\"wait after "+scenes.get(i/2).name.replaceAll(" ", "_")+"\", 20, 40);");
    processing_code.append( "    wait_after_"+scenes.get(i/2).name.replaceAll(" ", "_")+"();");
    processing_code.append( "  }");
  }
  processing_code.append(" ");
  processing_code.append("  time_elapsed = time_elapsed + delta_t;");
  
  processing_code.append("}");
  processing_code.append("");
  processing_code.append("///////////////////////////////");
  processing_code.append("// a function for each state");
  processing_code.append("///////////////////////////////");
  for (int i = 0; i<scenes.size (); i++) {
    PPScene s = scenes.get(i);
    str = s.name.replaceAll(" ", "_");
    processing_code.append("");  
    processing_code.append("void play_"+str+"() {");
    processing_code.append("  if (time_elapsed >= "+s.duration+") {  // play is done - move to wait state");
    processing_code.append("    current_state = "+str.toUpperCase()+"_WAITING;");
    processing_code.append("    "+str.toUpperCase()+"_started_waiting = true;");
    processing_code.append("    return;");
    processing_code.append("  }");    
    processing_code.append("  if ("+str.toUpperCase()+"_started_playing) {  // just started playing - initialize ");
    processing_code.append("    "+str.toUpperCase()+"_started_playing = false;");
    processing_code.append("    time_elapsed = 0;");
    processing_code.append("");
    processing_code.append("  // activate variables");
    for (int j=0; j<vars.size();j++) {
      if (s.interactions.get(str(vars.get(j).id)) == 1) {
        processing_code.append("    "+vars.get(j).name+"++;");
      }
      else if  (s.interactions.get(str(vars.get(j).id)) == 2) {
        processing_code.append("    "+vars.get(j).name+" = "+ ((Variable)vars.get(j)).base_value+";");
      }  else if (s.interactions.get(str(vars.get(j).id)) == 3) {
        processing_code.append("    "+vars.get(j).name+" = floor(random("+((Variable)vars.get(j)).base_value+", "+str(((Variable)vars.get(j)).max_value+1)+"));");
      }
    }
    processing_code.append("  }");
    processing_code.append("");
    processing_code.append("  // start audio play (based on timing)");
    for (int j=0; j<s.scene_data.size();j++) {
       if (s.scene_data.get(j).type == "audio"){
         processing_code.append("  if ((time_elapsed <= "+((PPAudio)s.scene_data.get(j)).start_pos +") && (time_elapsed + delta_t >= "+((PPAudio)s.scene_data.get(j)).start_pos+")) {");
         processing_code.append("    AudioPlayer "+s.scene_data.get(j).name+" = minim.loadFile("+str+"_"+s.scene_data.get(j).name+");");
         processing_code.append("    "+s.scene_data.get(j).name+".play();");
         processing_code.append("  }");
       }
    }
    processing_code.append("");
    processing_code.append("  // send value to actuators");
    for (int j=0; j<s.scene_data.size();j++) {
       if (s.scene_data.get(j).type == "animation"){
         PPAnimation a = (PPAnimation)s.scene_data.get(j);
         if (a.actuator != null && a.actuator.hardware != null) {
           if(a.actuator.hardware.controller_type == 0) {
             processing_code.append("  arduinoWrite("+a.actuator.hardware.name+a.actuator.hardware.id+", "+a.actuator.pin+", "+str+"_"+a.name+"[time_elapsed]);");
           }  
           else {
               processing_code.append("  pololuWrite("+a.actuator.hardware.name+a.actuator.hardware.id+", "+a.actuator.pin+", "+str+"_"+a.name+"[time_elapsed]);");
           }
         }
       }
    }
    processing_code.append("}");
    processing_code.append("void wait_after_"+str+"() {");
    //processing_code.append("  boolean trigger = false;");
    processing_code.append("  if ("+str.toUpperCase()+"_started_waiting) {  // just started playing - initialize ");
    processing_code.append("    "+str.toUpperCase()+"_started_waiting = false;");
    processing_code.append("    time_elapsed = 0;");
    processing_code.append("  }");
    processing_code.append("  // check the conditions for transitioning");
    for (int j = 0; j<s.outgoing.size(); j++) {
       PPTransition t = (PPTransition)s.outgoing.get(j);
       if (t.chosen_events.size()>0) {
         String condition = "";
         for (int k =0; k<t.chosen_events.size(); k++) {
           if (t.chosen_events.get(k).type == "variable event" && ((PPVariable)t.chosen_events.get(k)).variable != null) {
             condition+="("+((PPVariable)t.chosen_events.get(k)).variable.name+" == "+((PPVariable)t.chosen_events.get(k)).variable.max_value+")";
           }
           else if (t.chosen_events.get(k).type == "sensor" && ((Sensor)t.chosen_events.get(k)).hardware != null) {
             String s_val = ((Sensor)t.chosen_events.get(k)).hardware.name+((Sensor)t.chosen_events.get(k)).hardware.id+"_"+((Sensor)t.chosen_events.get(k)).name+((Sensor)t.chosen_events.get(k)).id+"_value";
             condition+="("+s_val+" >= "+((Sensor)t.chosen_events.get(k)).min_range+" && "+s_val+" <= "+((Sensor)t.chosen_events.get(k)).max_range+")";
           }
           else if (t.chosen_events.get(k).type == "timer") {
             condition+="(time_elapsed >= "+ int(((PPTimer)t.chosen_events.get(k)).seconds*1000)+")";
           }
         }
         condition = condition.replaceAll("\\)\\(","\\) && \\(");
         processing_code.append("  if ("+condition+") {");
         processing_code.append("    current_state = "+t.destination.name.replaceAll(" ", "_").toUpperCase()+"_PLAYING;");
         processing_code.append("    "+t.destination.name.replaceAll(" ", "_").toUpperCase()+"_started_playing = true;");
         processing_code.append("    return;");
         processing_code.append("  }");
       }    
    }   
    processing_code.append("}");
  }
  
  processing_code.append("");
  processing_code.append("///////////////////////////////");
  processing_code.append("// utility functions - communication with serial port");
  processing_code.append("///////////////////////////////");
  processing_code.append("void arduinoWrite(Serial port, int pin, int value) {");
  processing_code.append("  port.write(\"<pin:value>\");");
  processing_code.append("}");
  processing_code.append("");
  processing_code.append("void pololuWrite(Serial port, int pin, int value) {");
  processing_code.append("  value = value*4;");
  processing_code.append("  int b = 132;  // beginning of command");
  processing_code.append("  int ch = pin;");
  processing_code.append("  int lo = value&0x7f;");
  processing_code.append("  int hi = value>>7;");
  processing_code.append("  port.write(char(b));");
  processing_code.append("  port.write(char(ch));");
  processing_code.append("  port.write(char(lo));");
  processing_code.append("  port.write(char(hi));");
  processing_code.append("}");
  processing_code.append("");
  processing_code.append("void arduinoRead() {");
  processing_code.append("  String in;");
  for (int i=0; i<controllers.length; i++) {
    HardwareController control = (HardwareController)controllers[i];
      if (control.controller_type == 0) {
        str = control.name+control.id;
        processing_code.append("  if ("+str+".available()>0) {");
        processing_code.append("    in = "+str+".readString();");
        processing_code.append("    String[] m = match(in, \"<(.*?)>\");");
        processing_code.append("    if (m != null) {");
        processing_code.append("      for (int i = 1; i < m.length; i++) {");
        processing_code.append("        int c = m[i].indexOf(\":\");");
        processing_code.append("        if (c > -1) {");
        processing_code.append("          int pin = int(m[i].substring(0,c));");
        for (int j=0; j<control.connected.size(); j++) {
          if(control.connected.get(j).type == "sensor") {
              processing_code.append("          if (pin == "+((Sensor)control.connected.get(j)).pin+") {");
              processing_code.append("            "+str+"_"+control.connected.get(j).name+control.connected.get(j).id+"_value = int(m[i].substring(c+1));");
              processing_code.append("          }");
          }
        }
        processing_code.append("        }");
        processing_code.append("      }");
        processing_code.append("    }");
        processing_code.append("  }"); 
      } 
  }
  
  processing_code.append("}");
  
  String filename = path+"/actions.pde";
  saveStrings(filename, actions_code.array());
  filename = path+"/"+project_name+".pde";
  saveStrings(filename, processing_code.array());
}


//////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////
void generateArduinoCode(HardwareController h) {
  arduino_code = new StringList();
  if (h.controller_type != 0) return;
  
  String file_path = path +"/" +h.name+h.id;
  File ctrldir = new File(file_path);
  ctrldir.mkdir();
  
  if (h.actuator_cnt>0) arduino_code.append("#include <Servo.h>");
  arduino_code.append("");
  arduino_code.append("// Defining public variables");
  int i;
  String str;
  for (i=0; i<h.connected.size (); i++) {
    if (h.connected.get(i).type == "actuator") {
      str = h.connected.get(i).name + str(h.connected.get(i).id);
      arduino_code.append("Servo "+str+";");
      arduino_code.append("int "+str+"_pin = "+str(((Actuator)h.connected.get(i)).pin) +";");
    }
    if (h.connected.get(i).type == "sensor") { 
      str = h.connected.get(i).name + str(h.connected.get(i).id);
      arduino_code.append("int "+str+"_value = 0;");
      arduino_code.append("int "+str+"_pin = "+str(((Sensor)h.connected.get(i)).pin) +";");
    }
  }
  arduino_code.append("char in_char;");
  arduino_code.append("String in_string =\"\";");
  arduino_code.append("int num = 0;");
  arduino_code.append("int pin = 0;");
  arduino_code.append("boolean string_complete = false;");
  arduino_code.append("boolean reading_pin = true;");
  arduino_code.append("");
  arduino_code.append("// Initialize port, attach servos");
  arduino_code.append("void setup() {");
  arduino_code.append("  Serial.begin(9600);");
  for (i=0; i<h.connected.size (); i++) {
    if (h.connected.get(i).type == "actuator") {
      str = h.connected.get(i).name + str(h.connected.get(i).id);
      arduino_code.append("  "+str+".attach("+str+"_pin);");
    }
  }
  arduino_code.append("  in_string.reserve(200);");
  arduino_code.append("}");
  arduino_code.append("");
  arduino_code.append("// The main loop");
  arduino_code.append("void loop() {");
  arduino_code.append("  serialEvent();     // a separate function that will read from the serial port");
  arduino_code.append("  if (string_complete) {");
  for (i=0; i<h.connected.size (); i++) {
    if (h.connected.get(i).type == "actuator") {
      str = h.connected.get(i).name + str(h.connected.get(i).id);
      arduino_code.append("    if (pin == "+str+"_pin) {");
      arduino_code.append("      "+str+".write(num);");
      arduino_code.append("    }");
    }
  }
  arduino_code.append("    in_string = \"\";");
  arduino_code.append("    num = 0;");
  arduino_code.append("    string_complete = false;");
  arduino_code.append("  }");
  arduino_code.append("  // read values corresponding to sensor pins");
  for (i=0; i<h.connected.size (); i++) {
    if (h.connected.get(i).type == "sensor") {
      str = h.connected.get(i).name + str(h.connected.get(i).id);
      String signal;
      if (((Sensor)h.connected.get(i)).signal == 0) signal = "digital";
      else signal = "analog";
      arduino_code.append("  "+str+"_value = "+signal+"Read("+str+"_pin);");
    }
  }
  arduino_code.append("  delay(10);");
  arduino_code.append("}");
  arduino_code.append("");
  arduino_code.append("// called every loop round, reads and writes to serial port, parses input");
  arduino_code.append("void serialEvent() {");
  arduino_code.append("  while (Serial.available() > 0) {");
  arduino_code.append("    in_char = (char)Serial.read();");
  arduino_code.append("    in_string += in_char;");
  arduino_code.append("    // parsing special characters, format is <pin:value>");
  arduino_code.append("    if (in_char == '<') {");
  arduino_code.append("      pin = 0;");
  arduino_code.append("      num = 0;");
  arduino_code.append("      reading_pin = true;");
  arduino_code.append("    }");
  arduino_code.append("    else if (in_char == ':') {");
  arduino_code.append("      reading_pin = false;");
  arduino_code.append("    }");
  arduino_code.append("    else if (in_char == '>') {");
  arduino_code.append("      string_complete = true;");
  arduino_code.append("    }");
  arduino_code.append("    else {");
  arduino_code.append("      int in_num = (reading_pin) ? pin : num;");
  arduino_code.append("      int digit = in_char -'0'; // convert charater into the digit it represents");
  arduino_code.append("      in_num = in_num * 10 + digit;");
  arduino_code.append("      if (reading_pin) pin = in_num;");
  arduino_code.append("      else num = in_num;");
  arduino_code.append("    }");
  arduino_code.append("  }");
  arduino_code.append("");
  if (h.sensor_cnt>0) arduino_code.append("  // Send sensor values");
  for (i=0; i<h.connected.size (); i++) {
    if (h.connected.get(i).type == "sensor") {
      str = h.connected.get(i).name + str(h.connected.get(i).id);
      arduino_code.append("  Serial.print(\"<\" + String("+str+"_pin) + \":\" + String("+str+"_value) + \">\");");
    }
  }
  arduino_code.append("}");
  
  String filename = file_path+"/"+h.name+str(h.id)+".ino";
  saveStrings(filename, arduino_code.array());
}

