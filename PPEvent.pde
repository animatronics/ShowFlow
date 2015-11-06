//////////////////////////////////////////////////////////
// Classes for HardwareController, Sensor, and Actuator
// which communicate with hardware.
// Also PPTimer and PPVariable which correspond to other
// events that may trigger a transition.
/////////////////////////////////////////////////////////
class HardwareController extends PPData {
  int ARDUINO = 0;
  int POLOLU = 1;

  ArrayList<PPData> connected = new ArrayList<PPData>();
  String port_name="";
  Serial port=null;
  String in ="";
  String out="";
  boolean isEcho = true;
  boolean isConnected = false;
  boolean isSending = false; // either sending or waiting for input
  int tryAgain =0;
  int controller_type = ARDUINO;
  int actuator_cnt = 0;
  int sensor_cnt = 0;
  HardwareController() {
    type="hardware controller";
    name= "controller";
    id = data_cnt.getCounter();
    setPort();
  }
  void setPort() {
    boolean exists = false;
    String[] list = Serial.list();
    for (int i=0; i<list.length; i++) {
      if (list[i].equals(port_name)) exists = true;
    }
    if (port_name == "" || !exists) {
      isConnected = false;
      if (port != null) {
        port.stop();
        port = null;
      }
    }
    if (!isConnected && port_name != "" && exists) {
      // after choosing from a list
      println("Trying to connect to port "+port_name);
      try {
        port = new Serial(controller.applet, port_name, 9600);
        isConnected = true;
        println("Connected to "+port_name);
      } 
      catch(Exception ex) {
      }
    }
  }

  void register(PPData c) {
    if (connected.indexOf(c) < 0) {
      connected.add(c);
      if (c.type == "actuator") actuator_cnt++;
      else if (c.type == "sensor") sensor_cnt++;
    }
  }
  void unregister(PPData c) {
    if (connected.indexOf(c) >=0) {
      if (c.type == "actuator") actuator_cnt++;
      else if (c.type == "sensor") sensor_cnt++;
      connected.remove(c);
    }
  }

  // this isn't used anymore
  void setAction(int pin, int value) {
    setPort();
    if (isConnected) {
      if (isEcho || tryAgain == 2) {
        tryAgain = 0;
        port.clear();
        if (controller_type == ARDUINO) {
          out = "<"+str(pin)+":"+str(value)+">";
          port.write(out);
        } else if (controller_type == POLOLU) {
          value = 1000+ value*100;
          int b = 132;  // beginning of command
          int ch = pin;
          int lo = value&0x7f;
          int hi = value>>7;
          port.write(char(b));
          port.write(char(ch));
          port.write(char(lo));
          port.write(char(hi));
        }
        isEcho = false;
        in = "";
      } else {
        tryAgain++;
      }
    }
  }

  void display() {
    setPort();
    if (isConnected) {
      in="";
      out="";
      if (port.available()>0) in += port.readString();
      String[] m = match(in, "<(.*?)>");
      if (m != null) {
        for (int i = 0; i<connected.size (); i++) {
          if (connected.get(i).type == "sensor") {
            Sensor s = (Sensor)connected.get(i);
            for (int j=1; j<m.length; j++) {
              if (getPin(m[j]) == s.pin) s.setValue(getValue(m[j]));
            }
          }
        }
      }
      for (int i = 0; i<connected.size (); i++) { 
        if (connected.get(i).type == "actuator") {
          Actuator a = (Actuator)connected.get(i);
          if (controller_type == ARDUINO) {
            if (a.status == PLAYING) {
              out += "<"+str(a.pin)+":"+str(a.getValue())+">";
            }
          } else {
            int value = a.getValue()*4;
            int b = 132;  // beginning of command
            int ch = a.pin;
            int lo = value&0x7f;
            int hi = value>>7;
            out += char(b)+char(ch)+char(lo)+char(hi);
            port.write(char(b));
            port.write(char(ch));
            port.write(char(lo));
            port.write(char(hi));
          }
        }
      }
      if (controller_type == ARDUINO) {
        port.write(out);
      }
    }
  }
  int getPin(String m) {
    int i = m.indexOf(":");
    if (i > -1) return int(m.substring(0, i));
    return -1;
  }
  int getValue(String m) {
    int i = m.indexOf(":");
    if (i > -1) return int(m.substring(i+1));
    return -1;
  }

  boolean isChild(PPData child) {
    if (child.type == "sensor" ) {
      if (((Sensor)child).hardware == this) return true;
    } else if (child.type == "actuator") {
      if (((Actuator)child).hardware == this) return true;
    }
    return false;
  }

  JSONObject writeToJSON() {
    JSONObject hardware = new JSONObject();
    hardware.setString("type", type);
    hardware.setString("name", name);
    hardware.setInt("id", id);
    hardware.setString("port name", port_name);
    hardware.setInt("controller type", controller_type);
    return hardware;
  }
  void readFromJSON(JSONObject jo) {
    name = jo.getString("name");
    id = jo.getInt("id");
    controller_type = jo.getInt("controller type");
    port_name = jo.getString("port name");  
    setPort();
    updateRep();
  }
}

/////////////////////////////////////////////////////////
// Sensor
////////////////////////////////////////////////////////
class Sensor extends PPData {
  final int DIGITAL = 0;
  final int ANALOG = 1;

  int pin;
  int min_range;
  int max_range;
  HardwareController hardware = null;
  HardwareController last_hardware = null;
  int signal = DIGITAL;
  int current_value = -1;
  int millis = -1;
  PGraphics icon;

  Sensor(String _name, int min, int max) {
    name = _name;
    min_range = min;
    max_range = max;
    type ="sensor";
    id = data_cnt.getCounter();
    status = DISABLE;
    icon = createGraphics(30, 30);
    PImage img = loadImage("sensor.png");
    icon.beginDraw();
    icon.image(img, 5, 5, 20, 20);
    icon.endDraw();
  }
  // instead of using multiple booleans to control triggering, we will use the status
  // status = DISABLE -> this sensor shouldn't be checked
  // status = IDLE -> this sensor is checked but hasn't triggered (current_value isn't in the range)
  // status = SELECTED -> this sensor was triggered
  boolean isParent(PPData p) {
    if (hardware == p) return true;
    if (p.type == "transition") {
      return p.isParent(this);
    }
    return false;
  }

  void activateSensor() {
    status = IDLE;
    current_value = -1;
    currentValue();
  }
  void clearSensor() {
    status = DISABLE;
  }

  void setValue(int val) {
    current_value = val;
  }
  void currentValue() {
    if (status == IDLE) {
      if (current_value >= min_range && current_value <= max_range) {
        status = SELECTED;
      }
    }
  }

  void display() {
    currentValue();
  }
  void hardwareUpdate() {
    if (hardware == null) {
      if (last_hardware != null) last_hardware.unregister(this);
    } else {
      if (last_hardware != null) last_hardware.unregister(this);
      hardware.register(this);
    }
    last_hardware = hardware;
  }

  JSONObject writeToJSON() {
    JSONObject sensor = new JSONObject();
    sensor.setString("type", type);
    sensor.setString("name", name);
    sensor.setInt("id", id);
    sensor.setInt("pin", pin);
    sensor.setInt("signal", signal);
    if (hardware != null) sensor.setString("hardware", hardware.name);
    else sensor.setString("hardware", "");
    if (hardware != null) sensor.setInt("hardware id", hardware.id);
    else sensor.setInt("hardware id", -1);
    sensor.setInt("min range", min_range);
    sensor.setInt("max range", max_range);
    return sensor;
  }
  void readFromJSON(JSONObject jo) {
    name = jo.getString("name");
    id = jo.getInt("id");
    pin = jo.getInt("pin");
    signal = jo.getInt("signal");
    min_range = jo.getInt("min range");
    max_range = jo.getInt("max range");
    int h_id = jo.getInt("hardware id");
    if (h_id == -1) hardware = null;
    else {
      hardware = (HardwareController)getDataById(h_id);
      if (hardware != null) hardware.register(this);
    }
    updateRep();
  }
}

/////////////////////////////////////////////////////////
// PPTimer
////////////////////////////////////////////////////////
class PPTimer extends Sensor {
  float seconds;
  PPTimer(float sec) {
    super("timer", 0, 0);
    type = "timer";
    seconds = sec;
    icon = createGraphics(30, 30);
    PImage img = loadImage("timer.png");
    icon.beginDraw();
    icon.image(img, 5, 5, 20, 20);
    icon.endDraw();
  }

  void activateSensor() {
    millis = millis();
    current_value = int(seconds*1000);
    status = IDLE;
  }
  boolean isParent(PPData p) {
    if (p.type == "transition") {
      return p.isParent(this);
    }
    return false;
  }
  void currentValue() {
    if (status == IDLE) {
      int delta = millis() - millis;
      millis = millis();
      current_value = current_value - delta;

      if (current_value <= 0) {
        status = SELECTED;
      }
    }
  }

  JSONObject writeToJSON() {
    JSONObject timer = new JSONObject();
    timer.setString("type", type);
    timer.setString("name", name);
    timer.setInt("id", id);
    timer.setFloat("seconds", seconds);
    return timer;
  }
  void readFromJSON(JSONObject jo) {
    name = jo.getString("name");
    id = jo.getInt("id");
    seconds = jo.getFloat("seconds");
    updateRep();
  }
}

/////////////////////////////////////////////////////////
// PPVariable
////////////////////////////////////////////////////////
class PPVariable extends Sensor {
  Variable variable;

  PPVariable(int trig_val) {
    super("variable event", trig_val, trig_val);
    type = "variable event";
    icon = createGraphics(30, 30);
    PImage img = loadImage("var_event.png");
    icon.beginDraw();
    icon.image(img, 5, 5, 20, 20);
    icon.endDraw();
  }
  void activateSensor() {
    if (variable != null) {
      status = IDLE;
    }
    super.activateSensor();
  }
  void currentValue() {
    if (variable == null) current_value = -1;
    else {
      current_value = variable.value;
    }
    if (current_value == max_range) {
      status = SELECTED;
    }
  }
  void display() {
    currentValue();
  }
  boolean isParent(PPData p) {
    if (p.type == "transition") {
      return p.isParent(this);
    }
    return false;
  }

  boolean isChild(PPData p) {
    if (p == variable) return true;
    return false;
  }
  JSONObject writeToJSON() {
    JSONObject var = new JSONObject();
    var.setString("type", type);
    var.setString("name", name);
    var.setInt("id", id);
    var.setInt("trigger value", max_range);
    if (variable != null) var.setString("var name", variable.name);
    else var.setString("var name", "");
    if (variable != null) var.setInt("var id", variable.id);
    else var.setInt("var id", -1);
    return var;
  }
  void readFromJSON(JSONObject jo) {
    name = jo.getString("name");
    id = jo.getInt("id");
    min_range = jo.getInt("trigger value");
    max_range = jo.getInt("trigger value");
    int var_id = jo.getInt("var id");

    if (var_id == -1) variable = null;
    else {
      variable = (Variable)getDataById(var_id);
    }
    updateRep();
  }
}

/////////////////////////////////////////////////////////
// Actuator
////////////////////////////////////////////////////////
class Actuator extends PPData {
  int pin;
  int min_range;
  int max_range;
  int last_value = 0;
  HardwareController hardware;
  HardwareController last_hardware;
  boolean isConnected = false;

  int[] actions = null;
  int index = -1; 
  int millis;

  Actuator(String _name, int min, int max) {
    name = _name;
    min_range = min;
    max_range = max;
    type ="actuator";
    id = data_cnt.getCounter();
  }
  boolean isParent(PPData p) {
    if (hardware == p) return true;
    return false;
  }

  JSONObject writeToJSON() {
    JSONObject actuator = new JSONObject();
    actuator.setString("type", type);
    actuator.setString("name", name);
    actuator.setInt("id", id);
    actuator.setInt("pin", pin);
    if (hardware != null) actuator.setString("hardware", hardware.name);
    else actuator.setString("hardware", "");
    if (hardware != null) actuator.setInt("hardware id", hardware.id);
    else actuator.setInt("hardware id", -1);
    actuator.setInt("min range", min_range);
    actuator.setInt("max range", max_range);
    return actuator;
  }
  void readFromJSON(JSONObject jo) {
    name = jo.getString("name");
    id = jo.getInt("id");
    pin = jo.getInt("pin");
    min_range = jo.getInt("min range");
    max_range = jo.getInt("max range");
    int h_id = jo.getInt("hardware id");
    if (h_id == -1) hardware = null;
    else {
      hardware = (HardwareController)getDataById(h_id);
      if (hardware != null) hardware.register(this);
    }
    updateRep();
  }

  void hardwareUpdate() {
    if (hardware == null) {
      if (last_hardware != null) last_hardware.unregister(this);
    } else {
      if (last_hardware != null) last_hardware.unregister(this);
      hardware.register(this);
    }
    last_hardware = hardware;
  }
  void setActions(int[] a) {
    if (a == null) {
      status = IDLE;
      index = -1;
      actions = null;
    } else {
      status = PLAYING;
      index = 0;
      actions = a;
      millis = millis();
      last_value = 0;
    }
  }
  int getValue() {
    return last_value;
  }
  void display() {
    if (hardware == null || hardware.isConnected == false) isConnected = false;
    else isConnected = true;
    if (status == PLAYING && index != -1) {
      int d_time = millis() - millis;
      millis = millis();
      index = index + d_time;
      if (index < actions.length) {
        last_value =actions[index];
      }
    }
  }
}

// for graphical purposes
class PPEvent  extends PPData {
  String name;
  PGraphics icon;
  PPEvent(String _name) {
    name = _name;
  }
  PPEvent(String _name, PGraphics _p) {
    name = _name;
    icon = _p;
  }
}

