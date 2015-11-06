/////////////////////////////////////////////////////////////
// PPCreator
// creates data elements and their representation
////////////////////////////////////////////////////////////
class PPCreator {
  PPCreator() {
  }
  PPScene createScene(String _name, int _left, int _top, SceneCounter count) {
    if (_name == "") _name = "scene"+count.getCounter();
    PPScene s = new PPScene(_name, _left, _top);
    SceneRepresentation sr = new SceneRepresentation(s);
    s.rep = sr;
    representations.add(sr);
    return s;
  }  
  PPTransition createTransition(PPScene _s, PPScene _d) {
    PPTransition t = new PPTransition(_s, _d);
    TransitionRepresentation tr = new TransitionRepresentation(t);
    t.rep = tr;
    representations.add(tr);
    return t;
  }
  PPAudio createAudio(Controller c, String _name, String _file_name, PPScene _parent) {
    PPAudio a = new PPAudio(c, _name, _file_name, _parent);
    AudioRepresentation ar = new AudioRepresentation(a);
    a.rep = ar;
    representations.add(ar);
    return a;
  }
  PPAnimation createAnimation(Controller c, String _name, PPScene _parent) {
    PPAnimation a = new PPAnimation(c, _name, _parent);
    AnimationRepresentation ar = new AnimationRepresentation(a);
    a.rep = ar;
    representations.add(ar);
    return a;
  }
  HardwareController createHardware() {
    HardwareController h = new HardwareController();
    HardwareRepresentation hr = new HardwareRepresentation(h);
    h.rep = hr;
    representations.add(hr);
    return h;
  }
  Sensor createSensor(String _name, int min, int max) {
    Sensor s = new Sensor( _name, min, max);
    SensorRepresentation sr = new SensorRepresentation(s);
    s.rep = sr;
    representations.add(sr);
    return s;
  }
  PPTimer createTimer(float sec) {
    PPTimer t = new PPTimer( sec);
    TimerRepresentation tr = new TimerRepresentation(t);
    t.rep = tr;
    representations.add(tr);
    return t;
  }

  PPVariable createVariableEvent(int trig_val) {
    PPVariable v = new PPVariable( trig_val);
    VariableEventRepresentation vr = new VariableEventRepresentation(v);
    v.rep = vr;
    representations.add(vr);
    return v;
  }
  Variable createVariable(int base_val, int max_val) {
    Variable v = new Variable("var"+int(data_cnt.count+1), base_val, max_val);
    VariableRepresentation vr = new VariableRepresentation(v);
    v.rep = vr;
    representations.add(vr);
    return v;
  }
  Actuator createActuator(String _name, int min, int max) {
    Actuator a = new Actuator( _name, min, max);
    ActuatorRepresentation ar = new ActuatorRepresentation(a);
    a.rep = ar;
    representations.add(ar);
    return a;
  }  
  void deleteRepresentation(Representation r) {
    r.bringToFocus();
    r.deleteData();
    representations.remove(r);
  }

  PPUIModal setModal(int _left, int _top, int _width, int _height, Controller c) {    // we use padding to space elements, and we assume standard button size is 50 (close button is the execption
    int button_s = 50;
    int padding = 10;
    _width = 250;
    int p_height = (button_s + padding) + 9*padding + 9*30 +2*padding;
    if (_height < p_height) _height = p_height;
    // check if we need to raise the window
    if (_height + _top + 2*padding > height) _top = height - _height - 2*padding;
    if (_width + _left + 2*padding > width) _left = width - _width - 2*padding;

    PPUIModal mod = new PPUIModal(c, _left, _top, _width, _height, _left, _top, _width, _height);
    int y = button_s+2*padding;
    addResource hardware = new addResource(c, "Controller", "+ New Controller", null, padding, y, _width-2*padding, 30);
    mod.addComponent(hardware);
    y += 30+padding;
    addResource actuator = new addResource(c, "Actuator", "+ New Actuator", null, padding, y, _width-2*padding, 30);
    mod.addComponent(actuator);
    y += 30+padding;
    addResource sensor = new addResource(c, "Sensor", "+ New Sensor Event", null, padding, y, _width-2*padding, 30);
    mod.addComponent(sensor);
    y += 30+padding;
    addResource timer = new addResource(c, "Timer", "+ New Timer Event", null, padding, y, _width-2*padding, 30);
    mod.addComponent(timer);
    y += 30+padding;
    addResource varev = new addResource(c, "Variable Event", "+ New Variable Event", null, padding, y, _width-2*padding, 30);
    mod.addComponent(varev);
    y+= 30+padding;
    addResource scene = new addResource(c, "Scene", "+ New Scene", null, padding, y, _width-2*padding, 30);
    mod.addComponent(scene);
    y += 30+padding;
    addResource transition = new addResource(c, "Transition", "+ New Link", null, padding, y, _width-2*padding, 30);
    mod.addComponent(transition);
    y += 30+padding;
    addResource var = new addResource(c, "Variable", "+ New Variable", null, padding, y, _width-2*padding, 30);
    mod.addComponent(var);
    // the following are not used anymore
    y += 30+padding;
    addResource audio = new addResource(c, "Audio", "+ New Audio Track", null, padding, y, _width-2*padding, 30);
    y += 30+padding;
    addResource animation = new addResource(c, "Animation", "+ New Movement Track", null, padding, y, _width-2*padding, 30);

    mod.updateDrawingAreas(_left, _top, _width, _height, _left, _top, _width, _height);
    mod.makeVisible();
    return mod;
  }
}

/////////////////////////////////////////////////////////////
// Representation (base class)
//
// A wrapper around every data
////////////////////////////////////////////////////////////
class Representation extends PPData {
  PPData data;
  PGraphics icon;
  PGraphics preview;
  int _width = 80;
  int _height = 80;
  ArrayList<PPData> related;
  Representation(PPData d) {
    data = d;
    icon = createGraphics(80, 80);
    preview = createGraphics(160, 160);
    type="representation";
    PImage img;
    if (d.type == "scene") {
      img = loadImage("scene_s.png");
    } else if (d.type == "transition") {
      img = loadImage("link.png");
    } else if (d.type == "hardware controller") {
      img = loadImage("arduino.png");
    } else if (d.type == "audio") {
      img = loadImage("audio.png");
    } else if (d.type == "animation") {
      img = loadImage("movement.png");
    } else if (d.type == "sensor") {
      img = loadImage("sensor.png");
    } else if (d.type == "timer") {
      img = loadImage("timer.png");
    } else if (d.type == "variable event") {
      img = loadImage("var_event.png");
    } else if (d.type == "variable") {
      img = loadImage("var.png");
    } else if (d.type == "actuator") {
      img = loadImage("servo.png");
    } else {
      img = loadImage("delete.png");
    }
    icon.beginDraw();
    icon.image(img, 10, 10, 60, 60);
    icon.endDraw();

    // default preview
    preview.beginDraw();
    preview.noStroke();
    preview.fill(255);
    preview.rect(30, 30, 100, 100, 10);
    preview.image(img, 30, 30, 100, 100);
    preview.endDraw();
  }
  void updateControlls() {
    associated_components = new ArrayList<PPUIComponent>();
    createControls();
  }
  void bringToFocus() {
    // used to calculate the related data
    related = new ArrayList<PPData>();
    for (int i=0; i<representations.size (); i++) {
      Representation r = (Representation)representations.get(i);
      if (data.isChild(r.data) || data.isParent(r.data)) {
        related.add(representations.get(i));
      }
    }
  }

  void deleteData() {
    for (int i = 0; i<related.size (); i++) {
      ((Representation)related.get(i)).data.isUpdated = true;
    }
  }
  void createControls() {
  }

  void display(PGraphics p) {    
    if (status == TARGETED) {
      p.noStroke();
      p.fill(90);
      p.rect(_left-10, _top-10, _width+20, _height+20, 10);
    }
    p.strokeWeight(1);
    if (status == SELECTED) {
      p.strokeWeight(3);
      p.stroke(100);
      p.rect(_left+2, _top+2, _width, _height, 10);
      p.fill(255, 0, 0);
      p.noStroke();
      for (int i = 0; i<related.size (); i++) {
        p.ellipse(related.get(i)._left-2, related.get(i)._top-2, 3, 3);
        p.ellipse(related.get(i)._left-2, related.get(i)._top+3, 3, 3);
        p.ellipse(related.get(i)._left-2, related.get(i)._top+8, 3, 3);
        p.ellipse(related.get(i)._left-2, related.get(i)._top+13, 3, 3);
        p.ellipse(related.get(i)._left+3, related.get(i)._top-2, 3, 3);
        p.ellipse(related.get(i)._left+8, related.get(i)._top-2, 3, 3);
        p.ellipse(related.get(i)._left+13, related.get(i)._top-2, 3, 3);
      }
    }
    if (status == DRAGGED) {
      p.tint(255, 50);
    }
    p.stroke(0);
    p.fill(255);
    p.rect(_left, _top, _width, _height, 10);
    p.image(icon, _left, _top);
    p.textSize(14);
    p.fill(0);
    p.textAlign(CENTER, CENTER);
    p.text(data.name, _left, _top+77, _width, 20);
    p.fill(170);
    if (status == DRAGGED) {
      p.tint(255, 255);
    }
  }
  boolean isInside(int x, int y) {
    if (x>_left && x<_left+_width &&
      y>_top && y<_top+_height) {
      return true;
    }
    return false;
  }
  void componentTriggered(PPUIComponent d) {
  }
}

/////////////////////////////////////////////////////////////
// SceneRepresentation
////////////////////////////////////////////////////////////
class SceneRepresentation extends Representation {
  PPUITable tracks;
  PPUITable incoming;
  PPUITable outgoing;
  PPUILabel in_label;
  PPUILabel out_label;
  SceneRepresentation(PPScene d) {
    super(d);
    // override icon or preview

    createControls();
  }

  void createControls() {
    PPUILabel name_label = new PPUILabel(controller, "resource name label", "Name:", null, 10, 10, text_label_w, 20);
    name_label.alignment = A_RIGHT;
    associateComponent(name_label);

    PPUIText name = new PPUIText(controller, "resource name", 20+text_label_w, 10, text_label_w + 100, 20, data.name);
    name.restricted_length = 21;
    name.expandWidth = true;  
    name.fixed_position = false;
    name.parent = this;
    associateComponent(name);

    PPUILabel tracks_label = new PPUILabel(controller, "tracks label", "Tracks:", null, 10, 40, text_label_w, 20);
    tracks_label.alignment = A_RIGHT;
    associateComponent(tracks_label);

    tracks = new PPUITable("table", 20+text_label_w, 40, ((PPScene)data).getDataList());
    tracks.parent = this;
    associateComponent(tracks);

    in_label = new PPUILabel(controller, "incoming label", "Incoming Links:", null, 10, tracks._top+tracks._height+20, text_label_w, 20);
    in_label.alignment = A_RIGHT;
    associateComponent(in_label);

    incoming = new PPUITable("table", 20+text_label_w, tracks._top+tracks._height+20, ((PPScene)data).getIncomingList());
    incoming.parent = this;
    associateComponent(incoming);

    out_label = new PPUILabel(controller, "outgoing label", "Outgoing Links:", null, 10, incoming._top+incoming._height+10, text_label_w, 20);
    out_label.alignment = A_RIGHT;
    associateComponent(out_label);

    outgoing = new PPUITable("table", 20+text_label_w, incoming._top+incoming._height+10, ((PPScene)data).getOutgoingList());
    outgoing.parent = this;
    associateComponent(outgoing);
  }
  void bringToFocus() {
    for (int i =0; i<associated_components.size (); i++) {
      if (associated_components.get(i).type == "inline button") {
        unassociateComponent(associated_components.get(i));
      }
    }
    tracks.updateOptions(((PPScene)data).getDataList());
    incoming.updateOptions(((PPScene)data).getIncomingList());
    outgoing.updateOptions(((PPScene)data).getOutgoingList());
    associateComponents(tracks.getAssociatedComponents());
    associateComponents(incoming.getAssociatedComponents());
    associateComponents(outgoing.getAssociatedComponents());
    incoming._top = tracks._top+ tracks._height+20;
    in_label._top = incoming._top;
    outgoing._top = incoming._top+incoming._height+10;
    out_label._top = outgoing._top;
    super.bringToFocus();
  }
  void deleteData() {
    super.deleteData();
    removeSceneFromScene((PPScene)data);
  }
  void componentTriggered(PPUIComponent d) {
    if (d != null && d.name == "resource name") {
      data.name = ((PPUIText)d).getText();
    }
  }
}

/////////////////////////////////////////////////////////////
// TransitionRepresentation
////////////////////////////////////////////////////////////
class TransitionRepresentation extends Representation {
  PPData[] scenes;
  PPUIList s_list;
  PPUIList d_list;
  PPUITable events;
  PPUIText name;
  TransitionRepresentation(PPTransition d) {
    super(d);
    // override icon or preview

    createControls();
  }

  void createControls() {
    PPUILabel name_label = new PPUILabel(controller, "resource name label", "Name:", null, 10, 10, text_label_w, 20);
    name_label.alignment = A_RIGHT;
    associateComponent(name_label);


    name = new PPUIText(controller, "resource name", 20+text_label_w, 10, text_label_w + 100, 20, data.name);
    name.restricted_length = 21;
    name.expandWidth = true;

    name.fixed_position = false;
    name.parent = this;
    associateComponent(name);

    PPUILabel s_label = new PPUILabel(controller, "source label", "Source Scene:", null, 10, 40, text_label_w, 20);
    s_label.alignment = A_RIGHT;
    associateComponent(s_label);

    scenes = getScenesList();
    s_list = new PPUIList(controller, "sources list", 20+text_label_w, 40, makeStringsFromDataList(scenes) );
    s_list.fixed_position = false;
    s_list.parent = this;
    associateComponent(s_list);

    PPUILabel d_label = new PPUILabel(controller, "destination label", "Destination Scene:", null, 10, 70, text_label_w, 20);
    d_label.alignment = A_RIGHT;
    associateComponent(d_label);

    d_list = new PPUIList(controller, "destination list", 20+text_label_w, 70, makeStringsFromDataList(scenes) );
    d_list.fixed_position = false;
    d_list.parent = this;
    associateComponent(d_list);

    PPUILabel events_label = new PPUILabel(controller, "events label", "Events:", null, 10, 110, text_label_w, 20);
    events_label.alignment = A_RIGHT;
    associateComponent(events_label);

    events = new PPUITable("table", 20+text_label_w, 110, ((PPTransition)data).chosen_events);
    events.parent = this;
    associateComponent(events);
  }

  void display(PGraphics p) {
    super.display(p);
    if ( ((PPTransition)data).chosen_events.size() == 0) {
      p.stroke(170);
      PImage img = loadImage("disconnect.png");
      p.image(img, _left+_width-20, _top+_height-20, 27, 27);
    }
  } 

  void bringToFocus() {
    unassociateComponents(events.getAssociatedComponents());
    events.updateOptions(((PPTransition)data).chosen_events);
    associateComponents(events.getAssociatedComponents());

    scenes = getScenesList();
    s_list.updateOptions(makeStringsFromDataList(scenes));
    d_list.updateOptions(makeStringsFromDataList(scenes));
    s_list.selected = -1;
    d_list.selected = -1;
    for (int i = 0; i<scenes.length; i++) {
      if (scenes[i].id == ((PPTransition)data).source.id) s_list.selected = i;
      if (scenes[i].id == ((PPTransition)data).destination.id) d_list.selected = i;
    }
    name.isDisabled = true;
    super.bringToFocus();
  }
  void deleteData() {
    super.deleteData();
    removeTransFromTrans((PPTransition)data);
  }
  void componentTriggered(PPUIComponent d) {
  }
}

/////////////////////////////////////////////////////////////
// AudioRepresentation
////////////////////////////////////////////////////////////
class AudioRepresentation extends Representation {
  AudioRepresentation(PPAudio d) {
    super(d);
    // override icon or preview
    preview.beginDraw();
    preview.background(0, 0);
    PGraphics wave = ((PPAudio)d).getImage(); 
    preview.image(wave, 0, 20);
    preview.endDraw();

    createControls();
  }

  void createControls() {
    PPUILabel name_label = new PPUILabel(controller, "resource name label", "Name:", null, 10, 10, text_label_w, 20);
    name_label.alignment = A_RIGHT;
    associateComponent(name_label);


    PPUIText name = new PPUIText(controller, "resource name", 20+text_label_w, 10, text_label_w+50, 20, data.name);
    name.restricted_length = 21;
    name.expandWidth = true;
    name.fixed_position = false;
    name.parent = this;
    associateComponent(name);

    PPUILabel file_label = new PPUILabel(controller, "file label", "File:", null, 10, 40, text_label_w, 20);
    file_label.alignment = A_RIGHT;
    associateComponent(file_label);

    int w = int(textWidth(((PPAudio)data).file_name));
    PPUIText file = new PPUIText(controller, "file name", 20+text_label_w, 40, w, 20, ((PPAudio)data).file_name);
    file.fixed_position = false;
    file.isDisabled = true;
    file.parent = this;
    associateComponent(file);
  }

  void deleteData() {
    super.deleteData();
    removeAudioFromAudio((PPAudio)data);
  }
  void componentTriggered(PPUIComponent d) {
    if (d != null && d.name == "resource name") {
      ((PPAudio)data).rename.setText(((PPUIText)d).getText());
      ((PPAudio)data).componentTriggered(((PPAudio)data).rename);
    }
  }
}

/////////////////////////////////////////////////////////////
// AnimationRepresentation
////////////////////////////////////////////////////////////
class AnimationRepresentation extends Representation {
  PPUIList a_list;
  PPData[] actuators;

  AnimationRepresentation(PPAnimation d) {
    super(d);
    // override icon or preview
    preview.beginDraw();
    preview.background(0, 0);
    PGraphics wave = ((PPAnimation)d).getImage(); 
    preview.image(wave, 0, 20);
    preview.textSize(16);
    preview.endDraw();

    createControls();
  }
  void updateControlls() {
    preview.beginDraw();
    preview.background(0, 0);
    PGraphics wave = ((PPAnimation)data).getImage(); 
    preview.image(wave, 0, 20);
    preview.textSize(16);
    preview.endDraw();
    super.updateControlls();
  }

  void display(PGraphics p) {
    super.display(p);
    if ( ((PPAnimation)data).actuator == null || ((PPAnimation)data).actuator.hardware == null ||!((PPAnimation)data).actuator.hardware.isConnected) {
      p.stroke(170);
      PImage img = loadImage("disconnect.png");
      p.image(img, _left+_width-20, _top+_height-20, 27, 27);
    }
  } 
  void createControls() {
    PPUILabel name_label = new PPUILabel(controller, "resource name label", "Name:", null, 10, 10, text_label_w, 20);
    name_label.alignment = A_RIGHT;
    associateComponent(name_label);

    PPUIText name = new PPUIText(controller, "resource name", 20+text_label_w, 10, text_label_w, 20, data.name);
    name.restricted_length = 21;
    name.expandWidth = true;
    name.fixed_position = false;
    name.parent = this;
    associateComponent(name);

    PPUILabel a_label = new PPUILabel(controller, "actuators label", "Actuators:", null, 10, 40, text_label_w, 20);
    a_label.alignment = A_RIGHT;
    associateComponent(a_label);

    actuators = getActuatorsList();
    a_list = new PPUIList(controller, "actuator list", 20+text_label_w, 40, makeStringsFromDataList(actuators) );
    a_list.fixed_position = false;
    a_list.parent = this;
    if (((PPAnimation)data).actuator != null) {
      for (int i =0; i<actuators.length; i++) {
        if (actuators[i] == ((PPAnimation)data).actuator) a_list.selected = i;
      }
    }
    associateComponent(a_list);
  }
  void deleteData() {
    super.deleteData();
    removeAnimationFromAnimation((PPAnimation)data);
  }
  void bringToFocus() {
    actuators = getActuatorsList();
    a_list.updateOptions(makeStringsFromDataList(actuators));
    super.bringToFocus();
  }
  void componentTriggered(PPUIComponent d) {
    if (d != null && d.name == "resource name") {
      ((PPAnimation)data).rename.setText(((PPUIText)d).getText());
      ((PPAnimation)data).componentTriggered(((PPAnimation)data).rename);
    } else if (d != null && d.name == "actuator list") {
      if (a_list.selected <0) {
        ((PPAnimation)data).actuator = null;
      } else {
        ((PPAnimation)data).actuator = (Actuator)actuators[a_list.selected];
      }
    }
    for (int i = 0; i<related.size (); i++) {
      ((Representation)related.get(i)).data.isUpdated = true;
    }
  }
}
/////////////////////////////////////////////////////////////
// HardwareRepresentation
////////////////////////////////////////////////////////////
class HardwareRepresentation extends Representation {
  PPUIList port_list;
  PPUIList t_list;
  HardwareRepresentation(HardwareController d) {
    super(d);
    // override icon or preview

    createControls();
  }

  void createControls() {
    PPUILabel name_label = new PPUILabel(controller, "resource name label", "Name:", null, 10, 10, text_label_w, 20);
    name_label.alignment = A_RIGHT;
    associateComponent(name_label);

    PPUIText name = new PPUIText(controller, "resource name", 20+text_label_w, 10, text_label_w, 20, data.name);
    name.restricted_length = 21;
    name.expandWidth = true;
    name.fixed_position = false;
    name.parent = this;
    associateComponent(name);

    PPUILabel type_label = new PPUILabel(controller, "hardware type", "Type of Controller:", null, 10, 40, text_label_w, 20);
    type_label.alignment = A_RIGHT;
    associateComponent(type_label);

    String[] types = {
      "Arduino", "Pololu"
    };
    t_list = new PPUIList(controller, "type list", 20+text_label_w, 40, types);
    t_list.fixed_position = false;
    t_list.parent = this;
    t_list.default_selection = 0;
    associateComponent(t_list);

    if (((HardwareController)data).controller_type == 1) {
      PImage img = loadImage("pololu.png");
      icon.beginDraw();
      icon.image(img, 10, 10, 60, 60);
      icon.endDraw();
      preview.beginDraw();
      preview.noStroke();
      preview.fill(255);
      preview.rect(30, 30, 100, 100, 10);
      preview.image(img, 30, 30, 100, 100);
      preview.endDraw();
      t_list.selected = 1;
    }


    PPUILabel port_label = new PPUILabel(controller, "resource port label", "Available Ports:", null, 10, 70, text_label_w, 20);
    port_label.alignment = A_RIGHT;
    associateComponent(port_label);

    port_list = new PPUIList(controller, "port list", 20+text_label_w, 70, Serial.list());
    port_list.fixed_position = false;
    port_list.parent = this;
    associateComponent(port_list);

    if (((HardwareController)data).port_name != "") {
      for (int i =0; i<Serial.list ().length; i++) {
        if (Serial.list()[i].equals(((HardwareController)data).port_name)) port_list.selected = i;
      }
    }
  }
  void display(PGraphics p) {
    super.display(p);
    if ( !((HardwareController)data).isConnected) {
      p.stroke(170);
      PImage img = loadImage("disconnect.png");
      p.image(img, _left+_width-20, _top+_height-20, 27, 27);
    }
  } 
  void bringToFocus() {
    port_list.updateOptions(Serial.list());
    super.bringToFocus();
  }
  void deleteData() {
    super.deleteData();
    removeControllerFromController((HardwareController)data);
    deleteHardware(data);
  }
  void componentTriggered(PPUIComponent d) {
    if (d != null && d.name == "resource name") {
      data.name = ((PPUIText)d).getText();
    } else if (d != null && d.name == "port list") {
      ((HardwareController)data).port_name = ((PPUIList)d).getSelection();
    } else if ( d!= null && d.name == "type list") {
      ((HardwareController)data).controller_type = ((PPUIList)d).selected;
      PImage img = loadImage("arduino.png");
      if (((HardwareController)data).controller_type == 1) {
        img = loadImage("pololu.png");
      }
      icon.beginDraw();
      icon.background(0, 0);
      icon.image(img, 10, 10, 60, 60);
      icon.endDraw();
      preview.beginDraw();
      preview.background(0, 0);
      preview.noStroke();
      preview.fill(255);
      preview.rect(30, 30, 100, 100, 10);
      preview.image(img, 30, 30, 100, 100);
      preview.endDraw();
    }
  }
}

/////////////////////////////////////////////////////////////
// SensorRepresentation
////////////////////////////////////////////////////////////
class SensorRepresentation extends Representation {
  PPUIList hw_list;
  PPUIList s_list;
  PPData[] controllers;
  PPUIText val;

  SensorRepresentation(Sensor d) {
    super(d);
    // override icon or preview

    createControls();
  }

  void createControls() {
    PPUILabel name_label = new PPUILabel(controller, "resource name label", "Name:", null, 10, 10, text_label_w, 20);
    name_label.alignment = A_RIGHT;
    associateComponent(name_label);

    PPUIText name = new PPUIText(controller, "resource name", 20+text_label_w, 10, text_label_w, 20, data.name);
    name.restricted_length = 21;
    name.expandWidth = true;
    name.fixed_position = false;
    name.parent = this;
    associateComponent(name);

    PPUILabel pin_label = new PPUILabel(controller, "resource pin label", "Pin number:", null, 10, 40, text_label_w, 20);
    pin_label.alignment = A_RIGHT;
    associateComponent(pin_label);

    PPUIText pin = new PPUIText(controller, "resource pin", 20+text_label_w, 40, text_label_w, 20, str(((Sensor)data).pin));
    pin.restricted_length = 7;
    pin.expandWidth = true;
    pin.fixed_position = false;
    pin.isNumerical = true;
    pin.parent = this;
    associateComponent(pin); 

    PPUILabel val_label = new PPUILabel(controller, "current value label", "Current value:", null, 210+text_label_w, 10, text_label_w, 20);
    val_label.alignment = A_RIGHT;
    associateComponent(val_label);

    val = new PPUIText(controller, "current value", 220+text_label_w, 40, text_label_w, 20, str(((Sensor)data).current_value));
    val.restricted_length = 7;
    val.expandWidth = true;
    val.fixed_position = false;
    val.isNumerical = true;
    val.isDisabled = true;
    val.parent = this;
    associateComponent(val);


    PPUILabel signal_label = new PPUILabel(controller, "signal labe", "Signal:", null, 10, 70, text_label_w, 20);
    signal_label.alignment = A_RIGHT;
    associateComponent(signal_label);

    String[] types = {
      "Digital", "Analog"
    };
    s_list = new PPUIList(controller, "signal list", 20+text_label_w, 70, types);
    s_list.fixed_position = false;
    s_list.parent = this;
    s_list.default_selection = 0;
    associateComponent(s_list);
    if ( ((Sensor)data).signal == 1) s_list.selected = 1;

    PPUILabel min_label = new PPUILabel(controller, "resource min label", "Range min:", null, 10, 100, text_label_w, 20);
    min_label.alignment = A_RIGHT;
    associateComponent(min_label);

    PPUIText min = new PPUIText(controller, "resource min", 20+text_label_w, 100, text_label_w, 20, str(((Sensor)data).min_range));
    min.restricted_length = 7;
    min.expandWidth = true;
    min.fixed_position = false;
    min.isNumerical = true;
    min.parent = this;
    associateComponent(min); 

    PPUILabel max_label = new PPUILabel(controller, "resource max label", "Range max:", null, 10, 130, text_label_w, 20);
    max_label.alignment = A_RIGHT;
    associateComponent(max_label);

    PPUIText max = new PPUIText(controller, "resource max", 20+text_label_w, 130, text_label_w, 20, str(((Sensor)data).max_range));
    max.restricted_length = 7;
    max.expandWidth = true;
    max.fixed_position = false;
    max.isNumerical = true;
    max.parent = this;
    associateComponent(max);

    PPUILabel hw_label = new PPUILabel(controller, "hardware label", "Controllers:", null, 10, 160, text_label_w, 20);
    hw_label.alignment = A_RIGHT;
    associateComponent(hw_label);

    controllers = getControllersList();
    hw_list = new PPUIList(controller, "hardware list", 20+text_label_w, 160, makeStringsFromDataList(controllers) );
    hw_list.fixed_position = false;
    hw_list.parent = this;
    associateComponent(hw_list);


    if (((Sensor)data).hardware != null) {
      for (int i =0; i<controllers.length; i++) {
        if (controllers[i] == ((Sensor)data).hardware) hw_list.selected = i;
      }
    }
  }
  void deleteData() {
    for (int i=0; i<related.size (); i++) {
      Representation r = (Representation)related.get(i);
      if (r.data.type == "transition") {
        ((PPTransition)r.data).removeEvent(data);
      }
    }
    super.deleteData();
    removeSensorFromSensor((Sensor)data);
  }
  void display(PGraphics p) {
    super.display(p);
    if ( ((Sensor)data).hardware == null || !((Sensor)data).hardware.isConnected) {
      p.stroke(170);
      PImage img = loadImage("disconnect.png");
      p.image(img, _left+_width-20, _top+_height-20, 27, 27);
    }
    val.setText(str(((Sensor)data).current_value));
  } 
  void bringToFocus() {
    controllers = getControllersList();
    hw_list.updateOptions(makeStringsFromDataList(controllers));
    ((Sensor)data).hardwareUpdate();
    super.bringToFocus();
  }
  void componentTriggered(PPUIComponent d) {
    if (d != null && d.name == "resource name") {
      data.name = ((PPUIText)d).getText();
    } else if (d != null && d.name == "resource pin") {
      String txt = ((PPUIText)d).getText();
      if (txt == "") ((Actuator)data).pin = 0;
      else ((Sensor)data).pin = int(txt);
    } else if (d != null && d.name == "signal list") {
      ((Sensor)data).signal = ((PPUIList)d).selected;
    } else if (d != null && d.name == "resource min") {
      String txt = ((PPUIText)d).getText();
      if (txt == "") ((Actuator)data).min_range = 0;
      else ((Sensor)data).min_range = int(txt);
    } else if (d != null && d.name == "resource max") {
      String txt = ((PPUIText)d).getText();
      if (txt == "") ((Actuator)data).max_range = 0;
      else ((Sensor)data).max_range = int(txt);
    } else if (d != null && d.name == "hardware list") {
      if (hw_list.selected <0) {
        ((Sensor)data).hardware = null;
      } else {
        ((Sensor)data).hardware = (HardwareController)controllers[hw_list.selected];
      }
      ((Sensor)data).hardwareUpdate();
    }
    for (int i = 0; i<related.size (); i++) {
      ((Representation)related.get(i)).data.isUpdated = true;
    }
  }
}
/////////////////////////////////////////////////////////////
// TimerRepresentation
////////////////////////////////////////////////////////////
class TimerRepresentation extends Representation {
  TimerRepresentation(PPTimer d) {
    super(d);
    // override icon or preview

    createControls();
  }

  void createControls() {
    PPUILabel name_label = new PPUILabel(controller, "resource name label", "Name:", null, 10, 10, text_label_w, 20);
    name_label.alignment = A_RIGHT;
    associateComponent(name_label);

    PPUIText name = new PPUIText(controller, "resource name", 20+text_label_w, 10, text_label_w, 20, data.name);
    name.restricted_length = 21;
    name.expandWidth = true;
    name.fixed_position = false;
    name.parent = this;
    associateComponent(name);

    PPUILabel sec_label = new PPUILabel(controller, "resource sec label", "Seconds:", null, 10, 40, text_label_w, 20);
    sec_label.alignment = A_RIGHT;
    associateComponent(sec_label);

    PPUIText sec = new PPUIText(controller, "resource sec", 20+text_label_w, 40, text_label_w, 20, str(((PPTimer)data).seconds));
    sec.restricted_length = 7;
    sec.expandWidth = true;
    sec.fixed_position = false;
    sec.isNumerical = true;
    sec.parent = this;
    associateComponent(sec);
  }
  void deleteData() {
    for (int i=0; i<related.size (); i++) {
      Representation r = (Representation)related.get(i);
      if (r.data.type == "transition") {
        ((PPTransition)r.data).removeEvent(data);
      }
    }
    super.deleteData();
    removeTimerFromTimer((PPTimer)data);
  }
  void componentTriggered(PPUIComponent d) {
    if (d != null && d.name == "resource name") {
      data.name = ((PPUIText)d).getText();
    } else if (d != null && d.name == "resource sec") {
      String txt = ((PPUIText)d).getText();
      if (txt == "") {
        ((PPTimer)data).seconds = 0;
      } else {
        ((PPTimer)data).seconds = float(txt);
      }
    }
  }
}

/////////////////////////////////////////////////////////////
// VariableRepresentation
////////////////////////////////////////////////////////////
class VariableRepresentation extends Representation {
  VariableRepresentation(Variable d) {
    super(d);
    // override icon or preview

    createControls();
  }

  void createControls() {
    PPUILabel name_label = new PPUILabel(controller, "resource name label", "Name:", null, 10, 10, text_label_w, 20);
    name_label.alignment = A_RIGHT;
    associateComponent(name_label);

    PPUIText name = new PPUIText(controller, "resource name", 20+text_label_w, 10, text_label_w, 20, data.name);
    name.restricted_length = 21;
    name.expandWidth = true;
    name.fixed_position = false;
    name.parent = this;
    associateComponent(name);

    PPUILabel base_label = new PPUILabel(controller, "base label", "Starting value:", null, 10, 40, text_label_w, 20);
    base_label.alignment = A_RIGHT;
    associateComponent(base_label);

    PPUIText base_value = new PPUIText(controller, "base value", 20+text_label_w, 40, text_label_w, 20, str(((Variable)data).base_value));
    base_value.restricted_length = 7;
    base_value.expandWidth = true;
    base_value.fixed_position = false;
    base_value.isNumerical = true;
    base_value.parent = this;
    associateComponent(base_value); 

    PPUILabel max_label = new PPUILabel(controller, "max label", "Maximum value:", null, 10, 70, text_label_w, 20);
    max_label.alignment = A_RIGHT;
    associateComponent(max_label);

    PPUIText max_value = new PPUIText(controller, "max value", 20+text_label_w, 70, text_label_w, 20, str(((Variable)data).max_value));
    max_value.restricted_length = 7;
    max_value.expandWidth = true;
    max_value.fixed_position = false;
    max_value.isNumerical = true;
    max_value.parent = this;
    associateComponent(max_value);
  }

  void deleteData() {

    super.deleteData();
    removeVariableFromVariable((Variable)data);
  }
  void componentTriggered(PPUIComponent d) {
    if (d != null && d.name == "resource name") {
      data.name = ((PPUIText)d).getText();
    } else if (d != null && d.name == "base value") {
      String txt = ((PPUIText)d).getText();
      if (txt == "") {
        ((Variable)data).base_value = 0;
      } else {
        ((Variable)data).base_value = int(txt);
      }
    } else if (d != null && d.name == "max value") {
      String txt = ((PPUIText)d).getText();
      if (txt == "") {
        ((Variable)data).max_value = 0;
      } else {
        ((Variable)data).max_value = int(txt);
      }
    }
  }
}

/////////////////////////////////////////////////////////////
// VariableEventRepresentation
////////////////////////////////////////////////////////////
class VariableEventRepresentation extends Representation {
  PPUIList variables;
  VariableEventRepresentation(PPVariable d) {
    super(d);
    // override icon or preview

    createControls();
  }

  void createControls() {
    PPUILabel name_label = new PPUILabel(controller, "resource name label", "Name:", null, 10, 10, text_label_w, 20);
    name_label.alignment = A_RIGHT;
    associateComponent(name_label);

    PPUIText name = new PPUIText(controller, "resource name", 20+text_label_w, 10, text_label_w, 20, data.name);
    name.restricted_length = 21;
    name.expandWidth = true;
    name.fixed_position = false;
    name.parent = this;
    associateComponent(name);

    PPUILabel trigger_label = new PPUILabel(controller, "trigger label", "Trigger value:", null, 10, 70, text_label_w, 20);
    trigger_label.alignment = A_RIGHT;
    associateComponent(trigger_label);

    PPUIText trigger_value = new PPUIText(controller, "trigger value", 20+text_label_w, 70, text_label_w, 20, str(((PPVariable)data).max_range));
    trigger_value.restricted_length = 7;
    trigger_value.expandWidth = true;
    trigger_value.fixed_position = false;
    trigger_value.isNumerical = true;
    trigger_value.parent = this;
    associateComponent(trigger_value); 

    PPUILabel var_label = new PPUILabel(controller, "variable label", "Variable:", null, 10, 40, text_label_w, 20);
    var_label.alignment = A_RIGHT;
    associateComponent(var_label);

    variables = new PPUIList(controller, "variables list", 20+text_label_w, 40, makeStringsFromDataList(vars) );
    variables.fixed_position = false;
    variables.parent = this;
    if (((PPVariable)data).variable != null) {
      for (int i =0; i<vars.size (); i++) {
        if (vars.get(i) == ((PPVariable)data).variable) variables.selected = i;
      }
    }
    associateComponent(variables);
  }

  void display(PGraphics p) {
    super.display(p);
    if ( ((PPVariable)data).variable == null ) {
      p.stroke(170);
      PImage img = loadImage("disconnect.png");
      p.image(img, _left+_width-20, _top+_height-20, 27, 27);
    }
  } 
  void bringToFocus() {
    variables.updateOptions(makeStringsFromDataList(vars));
    if (((PPVariable)data).variable != null) {
      for (int i =0; i<vars.size (); i++) {
        if (vars.get(i) == ((PPVariable)data).variable) variables.selected = i;
      }
    }
    super.bringToFocus();
  }
  void deleteData() {
    for (int i=0; i<related.size (); i++) {
      Representation r = (Representation)related.get(i);
      if (r.data.type == "transition") {
        ((PPTransition)r.data).removeEvent(data);
      }
    }
    super.deleteData();
    removeVariableEventFromVariableEvent((PPVariable)data);
  }
  void componentTriggered(PPUIComponent d) {
    if (d != null && d.name == "resource name") {
      data.name = ((PPUIText)d).getText();
    } else if (d != null && d.name == "trigger value") {
      String txt = ((PPUIText)d).getText();
      if (txt == "") {
        ((PPVariable)data).max_range = 0;
        ((PPVariable)data).min_range = 0;
      } else {
        ((PPVariable)data).max_range = int(txt);
        ((PPVariable)data).min_range = int(txt);
      }
    } else if (d != null && d.name == "variables list") {
      if (variables.selected <0) {
        ((PPVariable)data).variable = null;
      } else {
        ((PPVariable)data).variable = (Variable)vars.get(variables.selected);
      }
    }
  }
}
/////////////////////////////////////////////////////////////
// ActuatorRepresentation
////////////////////////////////////////////////////////////
class ActuatorRepresentation extends Representation {
  PPUIList hw_list;
  PPData[] controllers;
  ActuatorRepresentation(Actuator d) {
    super(d);
    // override icon or preview

    createControls();
  }

  void createControls() {
    PPUILabel name_label = new PPUILabel(controller, "resource name label", "Name:", null, 10, 10, text_label_w, 20);
    name_label.alignment = A_RIGHT;
    associateComponent(name_label);

    PPUIText name = new PPUIText(controller, "resource name", 20+text_label_w, 10, text_label_w, 20, data.name);
    name.restricted_length = 21;
    name.expandWidth = true;
    name.fixed_position = false;
    name.parent = this;
    associateComponent(name);

    PPUILabel pin_label = new PPUILabel(controller, "resource pin label", "Pin number:", null, 10, 40, text_label_w, 20);
    pin_label.alignment = A_RIGHT;
    associateComponent(pin_label);

    PPUIText pin = new PPUIText(controller, "resource pin", 20+text_label_w, 40, text_label_w, 20, str(((Actuator)data).pin));
    pin.restricted_length = 7;
    pin.expandWidth = true;
    pin.fixed_position = false;
    pin.isNumerical = true;
    pin.parent = this;
    associateComponent(pin); 

    PPUILabel min_label = new PPUILabel(controller, "resource min label", "Range min:", null, 10, 70, text_label_w, 20);
    min_label.alignment = A_RIGHT;
    associateComponent(min_label);

    PPUIText min = new PPUIText(controller, "resource min", 20+text_label_w, 70, text_label_w, 20, str(((Actuator)data).min_range));
    min.restricted_length = 7;
    min.expandWidth = true;
    min.fixed_position = false;
    min.isNumerical = true;
    min.parent = this;
    associateComponent(min); 

    PPUILabel max_label = new PPUILabel(controller, "resource max label", "Range max:", null, 10, 100, text_label_w, 20);
    max_label.alignment = A_RIGHT;
    associateComponent(max_label);

    PPUIText max = new PPUIText(controller, "resource max", 20+text_label_w, 100, text_label_w, 20, str(((Actuator)data).max_range));
    max.restricted_length = 7;
    max.expandWidth = true;
    max.fixed_position = false;
    max.isNumerical = true;
    max.parent = this;
    associateComponent(max);

    PPUILabel hw_label = new PPUILabel(controller, "hardware label", "Controllers:", null, 10, 130, text_label_w, 20);
    hw_label.alignment = A_RIGHT;
    associateComponent(hw_label);

    controllers = getControllersList();
    hw_list = new PPUIList(controller, "hardware list", 20+text_label_w, 130, makeStringsFromDataList(controllers) );
    hw_list.fixed_position = false;
    hw_list.parent = this;
    if (((Actuator)data).hardware != null) {
      for (int i =0; i<controllers.length; i++) {
        if (controllers[i] == ((Actuator)data).hardware) hw_list.selected = i;
      }
    }
    associateComponent(hw_list);
  }
  void display(PGraphics p) {
    super.display(p);
    if ( ((Actuator)data).hardware == null || !((Actuator)data).hardware.isConnected) {
      p.stroke(170);
      PImage img = loadImage("disconnect.png");
      p.image(img, _left+_width-20, _top+_height-20, 27, 27);
    }
  } 
  void deleteData() {
    super.deleteData();
    removeActuatorFromActuator((Actuator)data);
  }
  void bringToFocus() {
    controllers = getControllersList();
    hw_list.updateOptions(makeStringsFromDataList(controllers));
    ((Actuator)data).hardwareUpdate();
    super.bringToFocus();
  }
  void componentTriggered(PPUIComponent d) {
    if (d != null && d.name == "resource name") {
      data.name = ((PPUIText)d).getText();
    } else if (d != null && d.name == "resource pin") {
      String txt = ((PPUIText)d).getText();
      if (txt == "") ((Actuator)data).pin = 0;
      else ((Actuator)data).pin = int(txt);
    } else if (d != null && d.name == "resource min") {
      String txt = ((PPUIText)d).getText();
      if (txt == "") ((Actuator)data).min_range = 0;
      else ((Actuator)data).min_range = int(txt);
    } else if (d != null && d.name == "resource max") {
      String txt = ((PPUIText)d).getText();
      if (txt == "") ((Actuator)data).max_range = 0;
      else ((Actuator)data).max_range = int(txt);
    } else if (d != null && d.name == "hardware list") {
      if (hw_list.selected <0) {
        ((Actuator)data).hardware = null;
      } else {
        ((Actuator)data).hardware = (HardwareController)controllers[hw_list.selected];
      }
      ((Actuator)data).hardwareUpdate();
    }
    for (int i = 0; i<related.size (); i++) {
      ((Representation)related.get(i)).data.isUpdated = true;
    }
  }
}

String[] makeStringsFromDataList(PPData[] list) {
  String[] strings= new String[list.length];
  for (int i = 0; i<list.length; i++) {
    strings[i] = list[i].name +" ("+ list[i].id+")";
  }
  return strings;
}
String[] makeStringsFromDataList(ArrayList<PPData> list) {
  String[] strings= new String[list.size()];
  for (int i = 0; i<list.size (); i++) {
    strings[i] = list.get(i).name +" ("+ list.get(i).id+")";
  }
  return strings;
}

