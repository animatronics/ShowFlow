//////////////////////////////////////////////////////////////
// This is the main code for ShowFlow.
//
// ShowFlow is a software for designing non-linear animatronic puppet
// shows. It allows the user to define the desired flow of the show by creating
// a state machine whith scenes as states, and a combination of timers, variables,
// and sensors to descibe the rules of transitioning. The user can develop a scene 
// by recording, dragging sound files, and describing animations with keyframes.
// The user can connect the program to controllers (Pololu for servos, arduino for 
// servos and sensors) and control them. The resulting show will be run from
// the software.
//
// ShowFlow is a tool created by Nurit Kirshenbaum (nuritk@hawaii.edu)
// as part of the UIST 2015 Student Innovation Contest.
//
// This code is released as open source, however, it is still under development
// and not as stable as it should be.
// This project uses the Minim library, and sojamo sDrop library (http://www.sojamo.de/libraries/drop/) 
//
// There are many planned improvements, such as:
// * More sound editing capabilities (sound effects, move begining of track, erase, cut and paste, etc.)
// * Different easing patters in keyframes (in addition to linear - quadratic, exponential, different ease-in and ease-out)
// * Better edge layout in overview screen
// * Hierarchical view of resources
// * Improved text editing
// * More
//
/////////////////////////////////////////////////////////////////

import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;
import sojamo.drop.*;
import javax.swing.JFileChooser;
import java.awt.event.ActionEvent;
import java.io.*;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.Files;
import java.io.IOException;
import processing.serial.*;
import static java.nio.file.StandardCopyOption.REPLACE_EXISTING;

final static int INVISIBLE = 0;
final static int IDLE = 1;
final static int SELECTED = 2;
final static int DRAGGED = 3;
final static int HOVERED = 4;
final static int PREPLAY = 5;
final static int PLAYING = 6;
final static int DISABLE = 7;
final static int CLICKED = 8;
final static int TARGETED = 9;


// Things you can do with a variable 
final static int NONE = 0;
final static int INCREMENT = 1;
final static int RESET = 2;
final static int RANDOM = 3;

Minim minim;
SDrop drop;

SceneCounter scene_cnt = new SceneCounter();
TrackCounter track_cnt = new TrackCounter();
DataCounter data_cnt = new DataCounter();
ArrayList<PPScene> scenes = new ArrayList<PPScene>();
ArrayList<PPTransition> trans = new ArrayList<PPTransition>();
ArrayList<PPData> hardware = new ArrayList<PPData>();
ArrayList<PPData> data = new ArrayList<PPData>();
ArrayList<PPData> vars = new ArrayList<PPData>();
//ArrayList<Representation> representations = new ArrayList<Representation>();
ArrayList<PPData> representations = new ArrayList<PPData>();


ArrayList<PPEvent> events = new  ArrayList<PPEvent>();

boolean fullScreen = false;
boolean isDragging=false;
boolean isUpdated = true;
boolean isPlaying = false;
int lastX;
int lastY;

OverviewView overview;
SceneView sceneview;
SettingsView settingview;
CodeView codeview;
PPUIView active_view = null;
PPUIModal active_modal = null;

int max_canvas_w=0;
int max_canvas_h=0;

int track_h = 80;
int text_label_w = 100;

boolean doubleClick = false;
Controller controller;
Message message;
PPCreator creator;

String path=sketchPath("");
String project_name="";

void setup() {
  size(displayWidth*2/3, displayHeight*2/3);
  background(255);
  path=sketchPath("");
  message = new Message();
  controller = new Controller(this, scenes, trans, events);
  minim = new Minim(this);
  drop = new SDrop(this);
  creator = new PPCreator();

  PPScene s1 = creator.createScene("", 100, 100, scene_cnt);
  addScene(s1);
  // adding some events
  PGraphics p1 = createGraphics(30, 30);
  PImage img = loadImage("timer.png");

  p1.beginDraw();
  p1.image(img, 0, 0, 30, 30);
  p1.endDraw();
  events.add(new PPEvent("timer", p1));
  PGraphics p2 = createGraphics(30, 30);
  img = loadImage("sensor.png");
  p2.beginDraw();
  p2.image(img, 0, 0, 30, 30);
  p2.endDraw();
  events.add(new PPEvent("sensor", p2));
  PGraphics p3 = createGraphics(30, 30);
  img = loadImage("var_event.png");
  p3.beginDraw();
  p3.image(img, 0, 0, 30, 30);
  p3.endDraw();
  events.add(new PPEvent("variable event", p3));

  isUpdated = true;
}

void clearData() {
  scenes = new ArrayList<PPScene>();
  trans = new ArrayList<PPTransition>();
  hardware = new ArrayList<PPData>();
  data = new ArrayList<PPData>();
  representations = new ArrayList<PPData>();
  vars = new ArrayList<PPData>();
  data_cnt.count = 0;
  track_cnt.count = 0;
  scene_cnt.count = 0;
}
PPData getDataById(int _id) {
  for (int i = 0; i<hardware.size (); i++) {
    if (hardware.get(i).id == _id) return hardware.get(i);
  }

  for (int i = 0; i<vars.size (); i++) {
    if (vars.get(i).id == _id) return vars.get(i);
  }
  for (int i = 0; i<data.size (); i++) {
    if (data.get(i).id == _id) {
      return data.get(i);
    }
    if (data.get(i).type == "scene") {
      PPData track = ((PPScene)data.get(i)).getSceneDataById(_id);
      if (track != null) return track;
    }
  }
  return null;
}
void addRepresentation(Representation r) {
  representations.add(r);
}
PPData createHardware() {
  HardwareController hw = creator.createHardware();
  hardware.add(hw);
  isUpdated = true;
  return hw;
}
PPData createSensor() {
  Sensor s = creator.createSensor("sensor", 0, 100);
  hardware.add(s);
  isUpdated = true;
  return s;
}
PPData createTimer() {
  PPTimer t = creator.createTimer(5);
  hardware.add(t);
  isUpdated = true;
  return t;
}
PPData createVariable() {
  Variable v = creator.createVariable( 0, 3);
  vars.add(v);
  isUpdated = true;
  return v;
}
PPData createVariableEvent() {
  PPVariable v = creator.createVariableEvent(3);
  hardware.add(v);
  isUpdated = true;
  return v;
}
PPData createActuator() {
  Actuator a = creator.createActuator("actuator", 0, 100);
  hardware.add(a);
  isUpdated = true;
  return a;
}

Representation representationOf(PPData d) { 
  return d.rep;
}

PPData[] getControllersList() {
  PPData[] result= {
  };
  for (int i=0; i<hardware.size (); i++) {
    if (hardware.get(i).type == "hardware controller") {
      PPData d = hardware.get(i);
      result = (PPData[])append(result, d);
    }
  }
  return result;
}
PPData[] getActuatorsList() {
  PPData[] result= {
  };
  for (int i=0; i<hardware.size (); i++) {
    if (hardware.get(i).type == "actuator") {
      PPData d = hardware.get(i);
      result = (PPData[])append(result, d);
    }
  }
  return result;
}
PPData[] getSensorsList() {
  PPData[] result= {
  };
  for (int i=0; i<hardware.size (); i++) {
    if (hardware.get(i).type == "sensor") {
      PPData d = hardware.get(i);
      result = (PPData[])append(result, d);
    }
  }
  return result;
}
PPData[] getEventsList() {
  PPData[] result= {
  };
  for (int i=0; i<hardware.size (); i++) {
    if (hardware.get(i).type == "sensor" || hardware.get(i).type == "timer" || hardware.get(i).type == "variable event") {
      PPData d = hardware.get(i);
      result = (PPData[])append(result, d);
    }
  }
  return result;
}
PPData[] getScenesList() {
  PPData[] result= {
  };
  for (int i=0; i<data.size (); i++) {
    if (data.get(i).type == "scene") {
      PPData d = data.get(i);
      result = (PPData[])append(result, d);
    }
  }
  return result;
}

void removeTransFromTrans(PPTransition t) {
  if (t != null) {
    controller.setResource(null, false);
    t.source.removeTransaction(t, false);
    t.destination.removeTransaction(t, true);
    message("Removed Link from '"+t.source.name+"' to '"+t.destination.name+"'");
    trans.remove(t);
    data.remove(t);
    representations.remove(representationOf(t));
    isUpdated = true;
  }
}
PPTransition addTrans(PPScene src, PPScene dest) {
  PPTransition t = creator.createTransition(src, dest);
  message("Added Link from '"+t.source.name+"' to '"+t.destination.name+"'");
  trans.add(t);
  data.add(t);
  isUpdated = true;
  return t;
}
void removeSceneFromScene(PPScene s) {
  // remove all the transactions associated with the scene
  controller.setResource(null, false);
  ArrayList<PPData> all = s.allTransactions();
  while (all.size ()>0) {
    PPTransition t = (PPTransition)all.get(0);
    removeTransFromTrans(t);
    all = s.allTransactions();
  }
  ArrayList<PPData> scene_data = s.scene_data;
  for (int i =scene_data.size ()-1; i>= 0; i--) {
    PPData t = scene_data.get(i);
    if (t.type == "audio") removeAudioFromAudio((PPAudio)t);
    else if (t.type == "animation") removeAnimationFromAnimation((PPAnimation)t);
  }
  message("Removed scene '"+s.name+"'");
  scenes.remove(s);
  data.remove(s);
  trans.remove(s.stub);
  data.remove(s.stub);
  representations.remove(representationOf(s));
  isUpdated = true;
}
void addScene(PPScene s) {
  scenes.add(0, s);
  data.add(0, s);
  trans.add(s.stub);
  data.add(s.stub);

  message("Added scene '"+s.name+"'");
  controller.calcCanvas();
  isUpdated = true;
}

PPScene addSceneFromTrans(PPTransition t) {
  // if there is a selected transition go in the middle
  PPScene s = null;
  if (t != null) {
    PVector middle = t.middle();
    t.source.removeTransaction(t, false);
    t.destination.removeTransaction(t, true);
    trans.remove(t);
    data.remove(t);
    s = creator.createScene("", int(middle.x), int(middle.y), scene_cnt);
    addScene(s);

    PPTransition new_t =   creator.createTransition(t.source, s);
    trans.add(new_t);
    data.add(new_t);
    new_t = creator.createTransition(s, t.destination);
    trans.add(new_t);
    data.add(new_t);
  }
  // if there isn't, goes between the end and something before end
  else {
    s = creator.createScene("", width/2 - 50, height/3 + 50, scene_cnt);
    addScene(s);
    //return s;
  }
  isUpdated = true;
  return s;
}
void deleteHardware(PPData d) {
  hardware.remove(d);
}
void removeAudioFromAudio(PPAudio d) {
  controller.setResource(null, false);
  if (d.parent != null) {
    d.parent.removeData(d);
  }
  isUpdated = true;
}
void removeAnimationFromAnimation(PPAnimation d) {
  controller.setResource(null, false);
  if (d.parent != null) {
    d.parent.removeData(d);
  }
  isUpdated = true;
}
void removeControllerFromController(HardwareController d) {
  controller.setResource(null, false);

  isUpdated = true;
}
void removeSensorFromSensor(Sensor d) {
  controller.setResource(null, false);
  isUpdated = true;
}
void removeTimerFromTimer(PPTimer d) {
  controller.setResource(null, false);
  isUpdated = true;
}
void removeVariableEventFromVariableEvent(PPVariable d) {
  controller.setResource(null, false);
  vars.remove(d);
  isUpdated = true;
}
void removeVariableFromVariable(Variable d) {
  controller.setResource(null, false);
  isUpdated = true;
}
void removeActuatorFromActuator(Actuator d) {
  controller.setResource(null, false);
  isUpdated = true;
}

void draw() {
  if (isUpdated || isPlaying) {
    background(255);
    if (controller.active_view != null) controller.active_view.display();
    if (controller.active_modal != null) controller.active_modal.display();
    isUpdated = false;
  }
  for (int i = 0; i<hardware.size (); i++) {
    hardware.get(i).display();
  }
  message.display();
}

void message(String str) {
  isUpdated = true;
  message.setMessage(str);
}

///////////////////////////////////////////////////////
// Event Handling
///////////////////////////////////////////////////////

void mousePressed() {
  lastX = mouseX;
  lastY = mouseY;

  if (controller.active_modal != null) {
    PPUIComponent comp = controller.active_modal.isInside(mouseX, mouseY, true);
    if (comp != null) {
      if (comp.type != "button" && comp.type != "scroller"  && comp.status != DISABLE) {
      }
      comp.status = DRAGGED;
    }
  } else if (controller.active_view != null) {
    PPUIComponent comp = controller.active_view.isInsideComponent(mouseX, mouseY);
    if (comp != null) {
      if (comp.type != "button" && comp.type != "scroller"  && comp.status != DISABLE) {
      }
      if (comp.name == "vscroll" || comp.name == "hscroll") {
        comp.status = DRAGGED;
      } else if (comp.name == "overview canvas") {// we are in overview->canvas->graphics
        PPData d = controller.active_view.isInsideData(mouseX, mouseY);
        if (d != null) {
          if (d.type == "scene") {
            controller.mouseOnOverviewScene(d);
          } else if (d.type == "transition" || d.type == "stub") {
            controller.mouseOnOverviewTransition(d);
          }
        }
      } else if (comp.name == "scene canvas") {
        PPData d = controller.active_view.isInsideData(mouseX, mouseY);
        controller.mouseOnTrack(d);
      } 
      if (comp.name == "resources canvas") {
        PPData d = controller.active_view.isInsideData(mouseX, mouseY);
        controller.mouseOnResource(d);
      } else if (comp.type == "text") {
        controller.mouseOnText(comp);
      }
    }
  }
  isUpdated = true;
}
void mouseDragged() {
  controller.mouseBeingDragged(lastX, lastY);
  lastX=mouseX;
  lastY=mouseY;
  isUpdated = true;
}

void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  controller.verticalScroll(e);
  isUpdated = true;
}

void keyPressed() {
  controller.checkKey();
  isUpdated = true;
}
void keyReleased() {
  if (keyCode == CONTROL || keyCode == 157) controller.isControl = false;
  if (keyCode == ALT) controller.isAlt = false;
  isUpdated = true;
}
void mouseClicked(MouseEvent event) {

  if (event.getCount() == 2) { // check for double click
    doubleClick = true;
    controller.doubleClick();
  } else if (event.getCount() == 1) { // check for double click
    if (doubleClick == false) controller.oneClick();
    else doubleClick = false;
  }
  isUpdated = true;
}

void dropEvent(DropEvent theDropEvent) {
  if (theDropEvent.isFile()) {
    controller.fileDropped(theDropEvent.file());
  }
  isUpdated = true;
}

void mouseReleased() {
  if (controller.active_modal != null) {
    PPUIComponent comp = controller.active_modal.isInside(mouseX, mouseY, true);
    if (comp != null) {
      if (comp.type != "button") comp.status = SELECTED;
      comp.activate();
    } else { // not inside the modal
      controller.dismiss();
    }
  } else if (controller.active_view != null) {
    PPUIComponent comp = controller.active_view.isInsideComponent(mouseX, mouseY);
    if (comp != null) {

      if (comp.status != DISABLE) {
        if (comp.type != "button" && comp.type != "scroller") comp.status = SELECTED;
        comp.activate();
      }
      if (comp.name == "overview canvas") {// we are in overview->canvas->graphics
        PPData d = controller.active_view.isInsideData(mouseX, mouseY);
        if (d != null) {

          if (d.type == "scene") {
            controller.mouseOutOverviewScene(d);
          } else if (d.type == "transition" || d.type == "stub") {
            controller.mouseOutOverviewTransition(d);
          }
        } else {
          controller.mouseOutOverviewTransition(null);
        }
      }
      if (comp.name == "scene canvas") {
        PPData d = controller.active_view.isInsideData(mouseX, mouseY);
        controller.mouseOutTrack(d);
      }
      if (comp.name == "resources canvas") {
        PPData d = controller.active_view.isInsideData(mouseX, mouseY);
        controller.mouseOutResource(d);
      }
      if (comp.type == "text") {
        controller.mouseOutText(comp);
      }
    }
  }
  isUpdated = true;
}

void resize() {
  if (fullScreen) {
    // change to full screen size and recreate the views
    frame.setResizable(true);
    size(displayWidth, displayHeight-100);
    frame.setSize(displayWidth, displayHeight-78);
    frame.setResizable(false);
    String view = controller.active_view.name;

    controller = new Controller(this, scenes, trans, events);
    controller.setViewByName(view);
  } else {
    frame.setResizable(true);
    size(displayWidth*2/3, displayHeight*2/3);
    frame.setSize(displayWidth*2/3, displayHeight*2/3+22);
    frame.setResizable(false);
    String view = controller.active_view.name;

    controller = new Controller(this, scenes, trans, events);
    controller.setViewByName(view);
  }
  isUpdated = true;
}



///////////////////////////////////////////////////////////////////
// Controller class
//
// The controller is in charge of the interaction with and between the views
///////////////////////////////////////////////////////////////////

class Controller {
  ArrayList<PPScene> scenes;
  ArrayList<PPTransition> trans; 
  ArrayList<PPEvent> events; 
  PPUITabLabel[] tabs;

  AudioRecorder recorder;
  String recording_track;

  OverviewView overview;
  SceneView sceneview;
  SettingsView settingview;
  CodeView codeview;
  PPUIView active_view = null;
  PPUIModal active_modal = null;

  PPScene selected_s = null;
  PPTransition selected_t = null;
  PPUIButton selected_b = null;
  PPTrack selected_tr = null;
  PPUIText selected_tx = null;
  Representation selected_r = null;

  boolean isControl = false;
  boolean isAlt = false;
  String pasteBoard = "";

  PApplet applet;
  float[] zoom_levels = {
    0.01, 0.015, 0.0188, 0.023000000044703484, 0.04, 0.07, 0.1, 0.15, 0.2, 0.25, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1
  };
  PPRecording r;

  Controller(PApplet _applet, ArrayList<PPScene> _scenes, ArrayList<PPTransition> _trans, ArrayList<PPEvent> _events) {
    applet = _applet;
    scenes = _scenes;
    trans = _trans;
    events = _events;

    int top_nav_h = 70;
    int labels_h = 30;
    int tab_width = (width*2/3) / 4;   
    tabs = new PPUITabLabel[4];

    tabs[0] = new PPUITabLabel(this, "overview tab", "Overview", null, 0, top_nav_h, tab_width, labels_h, null);
    tabs[1] = new PPUITabLabel(this, "scene tab", "Scene", null, tab_width, top_nav_h, tab_width, labels_h, null);
    tabs[2] = new PPUITabLabel(this, "setting tab", "Resources", null, tab_width*2, top_nav_h, tab_width, labels_h, null);
    tabs[3] = new PPUITabLabel(this, "code tab", "Code", null, tab_width*3, top_nav_h, tab_width, labels_h, null);

    overview = new OverviewView(this);
    sceneview = new SceneView(this);
    settingview = new SettingsView(this);
    codeview = new CodeView(this);

    tabs[0].activate = overview;
    tabs[1].activate = sceneview;
    tabs[2].activate = settingview;
    tabs[3].activate = codeview;

    activate(overview);
  } 
  PPUITabLabel[] getTabs() { 
    return tabs;
  }
  PPUIView getOverview() { 
    return overview;
  }
  PPUIView getScene() { 
    return sceneview;
  }
  PPUIView getSetting() { 
    return settingview;
  }
  PPUIView getCode() { 
    return codeview;
  }
  void setViewByName(String viewname) {
    if (viewname == "Overview") activate(overview);
    else if (viewname == "Scene") activate(sceneview);
    else if (viewname == "Resources") activate(settingview);
    else if (viewname == "Code") activate(codeview);
  }
  ArrayList<PPScene> getScenes() {
    return scenes;
  }
  ArrayList<PPTransition> getTransitions() {
    return trans;
  }

  boolean singleStart() {
    int cnt=0;
    for (int i = 0; i<scenes.size (); i++) {        
      if (((PPScene)scenes.get(i)).isStart) {
        cnt++;
      }
    }
    if (cnt == 1) return true;
    return false;
  }

  void resetVars() {
    for (int i = 0; i<vars.size (); i++) {
      ((Variable)vars.get(i)).reset();
    }
  }
  void playClicked() {
    ((ShowFlow)applet).isPlaying = true;
    if (active_view == overview) {
      // check if there is only one start scene      
      if (selected_s != null) {
        selected_s.status = IDLE;
        selected_s = null;
      }
      for (int i = 0; i<scenes.size (); i++) {

        if (((PPScene)scenes.get(i)).isStart) {
          selected_s = (PPScene)scenes.get(i);
          selected_s.setStatus(PLAYING);
        }
      }
      resetVars();
      if (selected_s != null) overview.play();
    } else if (active_view == sceneview) {
      if (sceneview.current_scene != null) {
        sceneview.play();
      }
    } else if (active_view == settingview) {
      // something else
    }
  }
  void stopClicked() {
    ((ShowFlow)applet).isPlaying = false;
    if (active_view == overview) {
      overview.pause();
    } else if (active_view == sceneview) {
      sceneview.pause();
    } else if (active_view == settingview) {
      // something else
    }
  }

  void dismiss() {
    if (active_modal != null) {
      active_modal.dismiss();
      active_modal = null;
      // clear a selected transition if there is one
      if (selected_t != null) {
        selected_t.status = IDLE;
        selected_t = null;
      }
      if (selected_s != null) {
        selected_s.status = IDLE;
        selected_s = null;
      }
    }
  }

  void activate(PPUIComponent a) {
    dismiss();
    if (a.type == "view") {

      if (active_view != null) active_view.deactivate();
      active_view = (PPUIView)a;
      if (active_view == sceneview) editScene();
      if (active_view == codeview) {
        generateProcessingCode(); 
        PPData[] controllers = getControllersList();
        if (controllers.length >0) {
          for (int i=0; i< controllers.length; i++) {
            generateArduinoCode( (HardwareController)controllers[i]);
          }
          generateArduinoCode( (HardwareController)controllers[0]);
        }
      }
      active_view.activate();
    }
    if (a.type == "modal") {
      if (active_modal != null) active_modal.dismiss();
      active_modal = (PPUIModal)a;
      active_modal.makeVisible();
      active_modal.activate();
    }
  }
  void addScene() {
    if (active_modal != null) {
      if (selected_t != null) {
        addSceneFromTrans(selected_t);
      }
      selected_t = null;
      active_modal.dismiss();
    } else { // called from menu
      // add scene before the end
      addSceneFromTrans(null);
    }
    overview.main.setData(data);
    clearSelections();
  }
  // This isn't used anymore
  void showPossibleTransitions(int modal_l, int modal_t, int modal_w, int modal_h) {
    if (selected_s != null) {
      PPUIModal m = selected_s.setModal2(modal_l, modal_t, modal_w, modal_h, scenes, this);
      activate(m);
    }
  }

  void removeScene() {
    if (active_modal != null) {
      removeSceneFromScene(selected_s);
      selected_s = null;
      active_modal.dismiss();
    } else { // called from menu
      if (selected_s != null) {
        removeSceneFromScene(selected_s);
      }
    }
    clearSelections();
    overview.main.setData(data);
  }

  void removeTrans() {
    if (active_modal != null) {
      removeTransFromTrans(selected_t);
      selected_t = null;
      if (active_modal != null) active_modal.dismiss();
    } else { // called from menu
      // add scene before the end
    }
    clearSelections();
  }
  void editScene() {
    if (selected_s != null) {
      selected_s.isUpdated = true;
      sceneview.setScene(selected_s);
    } else if (scenes.size()> 0) {
      scenes.get(0).isUpdated = true;
      selected_s = scenes.get(0);
      sceneview.setScene(scenes.get(0));
    } else {
      // going to scene screen must have a scene, so creating if there is none
      PPScene s = addSceneFromTrans(null);
      selected_s = s;
      sceneview.setScene(s);
    }
    if (active_modal != null) active_modal.dismiss();
    if (active_view != sceneview) activate(sceneview);
  }

  void addEvent(PPData d) {
    if (active_modal != null) {
      active_modal.dismiss();
    }
    if (selected_t != null) {
      selected_t.addEvent((Sensor)d);
      selected_t.status = IDLE;
      selected_t = null;
      data.add(d);
    }
  }
  void setResource(PPData d, boolean activate_settings) {
    if (active_view != settingview && activate_settings) activate(settingview);
    if (selected_r != null) {
      selected_r.status = IDLE;
    }
    selected_r = (Representation)d;
    if (selected_r != null) {
      selected_r.status = SELECTED;
    }
    settingview.setResource(selected_r);
  }


  void zoomIn() {
    if (active_view == sceneview) {
      float curr_scale = sceneview.current_scene.scale;
      int index = 0;
      for (int i = 0; i<zoom_levels.length; i++) {
        if (zoom_levels[i] == curr_scale) index = i;
      }
      if (index < zoom_levels.length-1) {
        curr_scale = zoom_levels[index+1];
      }
      sceneview.scale = curr_scale;
      sceneview.current_scene.setScale(curr_scale);
      sceneview.current_scene.isUpdated = true;
    }
  }
  void zoomOut() {
    if (active_view == sceneview) {
      float curr_scale = sceneview.current_scene.scale;
      int index = 0;
      for (int i = 0; i<zoom_levels.length; i++) {
        if (zoom_levels[i] == curr_scale) index = i;
      }
      if (index > 1) {
        curr_scale = zoom_levels[index-1];
      }
      sceneview.scale = curr_scale;
      sceneview.current_scene.setScale(curr_scale);
      sceneview.current_scene.isUpdated = true;
    }
  }
  void prevScene() {
    int i = scenes.indexOf(sceneview.current_scene);
    if (i == 0) {
      i = scenes.size() -1;
    } else {
      i--;
    }
    PPScene s = scenes.get(i);
    s.isUpdated = true;
    sceneview.setScene(s);
  }
  void nextScene() {
    int i = scenes.indexOf(sceneview.current_scene);
    if (i == scenes.size() -1) {
      i = 0;
    } else {
      i++;
    }
    PPScene s = scenes.get(i);
    s.isUpdated = true;
    sceneview.setScene(s);
  }

  void record() {
    AudioInput in = minim.getLineIn();
    recording_track = "track"+track_cnt.getCounter();
    recorder = minim.createRecorder(in, path+ "/data/"+recording_track+".wav", true);
    recorder.beginRecord();
    message("Recording...");
  }
  void stopRecord() {
    recorder.endRecord();
    recorder.save();
    PPAudio a = creator.createAudio(this, recording_track, path+"/data/"+recording_track+".wav", sceneview.current_scene);
    sceneview.registerComponents(a);
    sceneview.current_scene.isUpdated = true;
  }
  void saveFile() {
    selectOutput("Enter a name for your project:", "fileForSaveSelected");
    return;
  }
  void newFile() {
    selectOutput("Enter a name for your project:", "fileSelected");
    return;
  }

  void saveToFile() {
    ((ShowFlow)applet).saveToFile();
  }
  void loadFile() {
    ((ShowFlow)applet).loadFile();
    activate(active_view);
  }
  void actionPerformed(ActionEvent e) {
    // do something
  }

  void setSceneColor() {
    int _h = 320 + 50; 
    int _w = 320;   // 300 + padding
    int _l = mouseX;
    int _t = mouseY;
    if (mouseX + _w > width) _l = width - _w -10;
    PPUIModal mod = new PPUIModal(this, _l, _t, _w, _h, _l, _t, _w, _h);
    mod.updateDrawingAreas(_l, _t, _w, _h, _l, _t, _w, _h);
    int x_offset = 10;
    int y_offset = 60;
    colorMode(HSB, 30);
    for (int i = 1; i<=30; i++) {
      for (int j = 1; j<=30; j++) {
        color c = color(i, j, 30);
        color drag = color(i, j, 27);
        ColorButton cb = new ColorButton(this, c, drag, x_offset, y_offset);
        mod.addComponent(cb);
        x_offset += 10;
      }
      x_offset = 10;
      y_offset += 10;
    }
    colorMode(RGB, 255);
    activate(mod);
  }
  void setSceneColorTo(color clr, color drag) {
    if (sceneview.current_scene != null) {
      dismiss();     
      sceneview.current_scene.setColor(clr, drag);
      sceneview.current_scene.isUpdated = true;
    }
  }
  void calcCanvas() {
    overview.calcCanvas();
  }

  void chooseResource() {
    PPUIModal mod = creator.setModal(mouseX, mouseY, 20, 20, this);
    activate(mod);
  }
  void removeResource() {
    if (selected_r !=null) {
      creator.deleteRepresentation(selected_r);
    }
  }
  void addResource(String n) {
    if (n == "Scene") {
      PPScene s = creator.createScene("", width/2 - 50, height/3 + 50, scene_cnt);
      ((ShowFlow)applet).addScene(s);
    } else if (n == "Transition") {
      if (((ShowFlow)applet).scenes.size() == 0) {
        return;
      }
      PPScene s = ((ShowFlow)applet).scenes.get(0);
      ((ShowFlow)applet).addTrans(s, s);
    } else if (n == "Audio") {
    } else if (n == "Animation") {
    } else if (n == "Controller") {
      createHardware();
    } else if (n == "Sensor") {
      createSensor();
    } else if (n == "Timer") {
      createTimer();
    } else if (n == "Variable Event") {
      createVariableEvent();
    } else if (n== "Variable") {
      createVariable();
    } else if (n == "Actuator") {
      createActuator();
    }
    if (active_modal != null) dismiss();
  }

  void clearSelections() {
    if (selected_s != null) selected_s.setStatus(IDLE);
    if (selected_t != null) selected_t.setStatus(IDLE);
    if (selected_r != null) selected_r.status = IDLE;
    //if (selected_b != null) selected_b.setStatus(IDLE);
    if (selected_tr != null) {
      selected_tr.status =IDLE;
      selected_tr.clearSelection();
    }
    if (selected_tx != null) selected_tx.status =IDLE;
    selected_s = null;
    selected_t = null;
    selected_b = null;
    selected_tr = null;
    selected_tx = null;
    selected_r = null;
    settingview.setResource(null);
  }

  void verticalScroll(float e) {
    if (active_modal != null) {
      active_modal.verticalScroll(e);
    } else if (active_view != null) {
      active_view.verticalScroll(e);
    }
  }
  void mouseOnOverviewScene(PPData d) {
    if (d!= null && d.type=="scene") {
      if (selected_s != null) selected_s.status = IDLE;
      if (selected_t != null) {
        selected_t.status = IDLE; 
        selected_t = null;
      }
      selected_s = (PPScene)d;
      selected_s.setStatus(DRAGGED);
    }
  }
  void mouseOnOverviewTransition(PPData d) {
    if (d!= null && (d.type=="transition" || d.type == "stub")) {
      if (selected_s != null) {
        selected_s.status = IDLE; 
        selected_s = null;
      }
      if (selected_t != null) selected_t.status = IDLE;
      selected_t = (PPTransition)d;
      selected_t.setStatus(DRAGGED);
    }
  }

  void mouseOutOverviewScene(PPData d) {
    if (selected_s != null) {
      selected_s.status = SELECTED;
    }
    if (selected_t != null) {
      selected_t.status = SELECTED;

      if (d != null) {
        if (d.type == "scene" && selected_t.flagOnLeft) {
          PPScene scene = (PPScene)d;
          //change the source of the transaction
          if (selected_t.type != "stub") {
            selected_t.changeConnection(scene, selected_t.destination);
          } else {
            addTrans(scene, selected_t.destination);
            return;
          }
        } else if (d.type == "scene" && selected_t.flagOnRight) {
          PPScene scene = (PPScene)d;
          //change the source of the transaction
          if (selected_t.type != "stub") {
            selected_t.changeConnection(selected_t.source, scene);
          } else {
            addTrans(selected_t.source, scene);
            return;
          }
        }
      }
      if ( !selected_t.flagOnLeft && !selected_t.flagOnRight) { // we are in the mid section of the line
        PPUIModal m = selected_t.setModal(mouseX, mouseY, 10, 10, events, this);
        activate(m);
      }
      // if the loop finished... lets make sure it is reconnected to the originals
      selected_t.changeConnection(selected_t.source, selected_t.destination);
    }
  }
  void mouseOutOverviewTransition(PPData d) {
    if (d == null) {
      if (selected_s != null) {
        selected_s.status = IDLE;
        selected_s = null;
      }
    }
    if (selected_t != null) {
      selected_t.status = SELECTED;
      if (selected_t.type == "stub") {
        selected_t.changeConnection(selected_t.source, selected_t.destination);
        selected_t.status = IDLE;
        return;
      }
      if (!selected_t.flagOnLeft && !selected_t.flagOnRight) { // we are in the mid section of the line
        PPUIModal m = selected_t.setModal(mouseX, mouseY, 10, 10, events, this);
        activate(m);
      }

      // if the loop finished... lets make sure it is reconnected to the originals
      selected_t.changeConnection(selected_t.source, selected_t.destination);
    }
  }
  void mouseOnTrack(PPData d) {
    if (selected_tx != null) {
      textOutOfFocus();
    }
    if (d == null) {
      if (selected_tr != null) {
        selected_tr.status =IDLE;
        selected_tr.clearSelection();
        selected_tr = null;
      }
    }
    if (d!=null) {
      if (d.name == "header") {
        sceneview.pause();
        sceneview.sb.activate();  // trigger stop button
      }
      if (selected_tr != null) {
        selected_tr.status =IDLE;
        selected_tr.clearSelection();
        sceneview.doneTrackName(selected_tr);
      }
      selected_tr = (PPTrack)d;
      d.status =DRAGGED;
    }
  }
  void mouseOutTrack(PPData d) {
    if (d == null) {
      if (selected_tr != null) {
        selected_tr.status =IDLE;
        selected_tr.clearSelection();
        selected_tr = null;
      }
    }
    if (d!=null) {
      if (selected_tr!=null ) {
        if (d.name == "header") {
          selected_tr.update(int(mouseX-sceneview.main.getEffectiveLeft()), lastX, int(mouseY-sceneview.main.getEffectiveTop()), lastY);
        }
        if (selected_tr.onLabel) {
          selected_tr.onLabel = false;
          if (selected_tx != null) selected_tx.status = IDLE;
          selected_tx = sceneview.editTrackName(selected_tr);
          selected_tx.status = SELECTED;
        }
      }
    }
  }
  void mouseOnResource(PPData d) {
    if (selected_r != null) {
      selected_r.status = IDLE;
    }
    selected_r = (Representation)d;
    setResource(d, false);
    if (d != null) d.status =SELECTED;
    if (selected_tx != null) {
      textOutOfFocus();
    }
  }
  void mouseOutResource(PPData d) {
    if (d == null) {
      if (selected_r != null) {
        selected_r.status = IDLE;
        selected_r = null;
        settingview.setResource(null);
      }
    } else {
      if (d!= selected_r) {
        if (selected_r.status == DRAGGED) {
          selected_r.status = IDLE;
          settingview.setResource(null);
          dropped(selected_r, (Representation)d);
        }
      }
      setResource(d, false);
    }
  }

  void dropped(Representation src, Representation dest) {
    if (src.data.type == "animation" && dest.data.type == "actuator") {
      ((PPAnimation)src.data).actuator = (Actuator)dest.data;
    } else if (dest.data.type == "animation" && src.data.type == "actuator") {
      ((PPAnimation)dest.data).actuator = (Actuator)src.data;
    }
    // actuator -> controller (set the hardware for that actuator) controller->actuator
    else if (src.data.type == "actuator" && dest.data.type == "hardware controller") {
      ((Actuator)src.data).hardware = (HardwareController)dest.data;
      ((Actuator)src.data).hardwareUpdate();
    } else if (src.data.type == "hardware controller" && dest.data.type == "actuator") {
      ((Actuator)dest.data).hardware = (HardwareController)src.data;
      ((Actuator)dest.data).hardwareUpdate();
    } 
    // sensor -> controller (set the hardware for that sensor) controller->sensor
    else if (src.data.type == "sensor" && dest.data.type == "hardware controller") {
      ((Sensor)src.data).hardware = (HardwareController)dest.data;
      ((Sensor)src.data).hardwareUpdate();
    } else if (src.data.type == "hardware controller" && dest.data.type == "sensor") {
      ((Sensor)dest.data).hardware = (HardwareController)src.data;
      ((Sensor)dest.data).hardwareUpdate();
    }
    // variable -> variable event (set the event for that var event) variable event -> variable
    else if (src.data.type == "variable" && dest.data.type == "variable event") {
      ((PPVariable)dest.data).variable = (Variable)src.data;
    } else if (src.data.type == "variable event" && dest.data.type == "variable") {
      ((PPVariable)src.data).variable = (Variable)dest.data;
    } 
    // sensor/timer/variable event -> transition (add that event to the transition's chosen events) transition ->sensor/timer/variable event
    else if ((src.data.type == "sensor" || src.data.type == "timer" || src.data.type == "variable event") && dest.data.type == "transition") {
      ((PPTransition)dest.data).addEvent(src.data);
    } else if (src.data.type == "transition" && (src.data.type == "sensor" || src.data.type == "timer" || src.data.type == "variable event")) {
      ((PPTransition)src.data).addEvent(dest.data);
    }
    // scene -> transition (set the source of the transition to scene)
    // transition -> scene (set the destination of the transition to scene)
    else if (src.data.type == "scene" && dest.data.type == "transition") {
      ((PPTransition)dest.data).source = (PPScene)src.data;
    } else if (src.data.type == "transition" && dest.data.type == "scene") {
      ((PPTransition)src.data).destination = (PPScene)dest.data;
    } 
    // audio -> scene (make a new audio elements with the same file and add to scene) scene -> audio
    else if (src.data.type == "audio" && dest.data.type == "scene") {
      String a_name = ((PPAudio)src.data).name;
      String file_name = ((PPAudio)src.data).file_name;
      //((PPScene)dest.data).addData( creator.createAudio(this, a_name+"copy", file_name, (PPScene)dest.data ) );
      creator.createAudio(this, a_name+"copy", file_name, (PPScene)dest.data );
    } else if (dest.data.type == "audio" && src.data.type == "scene") {
      String a_name = ((PPAudio)dest.data).name;
      String file_name = ((PPAudio)dest.data).file_name;
      //((PPScene)dest.data).addData( creator.createAudio(this, a_name+"copy", file_name, (PPScene)dest.data ) );
      creator.createAudio(this, a_name+"copy", file_name, (PPScene)src.data );
    }
    src.data.updateRep();
    dest.data.updateRep();
  }
  void doubleClick() {
    if (active_view == overview) {
      if (selected_s != null) {
        editScene();
      }
      if (selected_t != null) {
        PPUIModal m = selected_t.setModal(mouseX, mouseY, 10, 10, events, this);
        activate(m);
      }
    }
  }

  void oneClick() {
    if (active_view == overview) {
      if (selected_s != null) {
        // not doing this anymore
      }
    }
    if (active_view == sceneview) {
      if (selected_tr != null) {
        selected_tr.status = SELECTED;
      }
      if (selected_tr != null && selected_tr.type == "animation") {
        sceneview.keyFrameAt(selected_tr, mouseX, mouseY);
      }
    }
  }

  void fileDropped(File f) {
    String file_path = f.getPath();
    int i2 = f.getName().indexOf(".");
    if (i2 == -1) return;
    String file_name = f.getName().substring(0, i2); 
    String ending = f.getName().substring(i2+1);
    if (ending.equals("wav") ||ending.equals("aiff") || ending.equals("aac") || ending.equals("au") || ending.equals("mp3") || ending.equals("ogg") || ending.equals("wma") ) {
      if (active_view == sceneview) {

        String new_path = path+"/data/"+file_name+"."+ending;
        try {
          Files.copy(Paths.get(file_path), Paths.get(new_path), REPLACE_EXISTING);
          PPAudio a = creator.createAudio (this, file_name, file_path, sceneview.current_scene);
          sceneview.current_scene.isUpdated = true;
        }
        catch (IOException e) {
        }
      }
    }
  }

  void mouseBeingDragged(int lastX, int lastY) {
    if (active_modal != null) {
      active_modal.update(mouseX - lastX, mouseY - lastY);
    }
    if (active_view == overview) {
      if (selected_s != null) {
        overview.update(selected_s, mouseX, mouseY, lastX, lastY);
      }
      if (selected_t != null) {
        overview.update(selected_t, mouseX, mouseY, lastX, lastY);
      }
      overview.update(mouseX - lastX, mouseY - lastY);
    }
    if (active_view == sceneview) {
      if (selected_tr != null) {
        sceneview.update(selected_tr, mouseX, mouseY, lastX, lastY);
      }
      sceneview.update(mouseX - lastX, mouseY - lastY);
    }
    if (active_view == settingview) {
      if (selected_r != null) selected_r.status = DRAGGED;
      settingview.dragging(selected_r);

      settingview.update(mouseX-lastX, mouseY-lastY);
    }
    if (active_view == codeview) {
      //
      codeview.update(mouseX-lastX, mouseY-lastY);
    }
    if (selected_tx != null) { 
      int pos = active_view.moveCursorToPosition(selected_tx, mouseX, mouseY);
      selected_tx.updateHighlight(pos);
    }
  }

  void textOutOfFocus() {
    if (selected_tx != null) {
      selected_tx.status = IDLE;
      selected_tx.outOfFocus();
      selected_tx = null;
    }
  }
  void mouseOnText(PPUIComponent c) {
    if (selected_tx != null) {
      textOutOfFocus();
    }
    selected_tx = (PPUIText)c; 
    if (selected_tx != null) { 
      PPUIText t = (PPUIText)selected_tx;
      int pos = active_view.moveCursorToPosition(t, mouseX, mouseY);

      t.setHighlighStart(pos);
      t.status = DRAGGED;
    }
  }
  void mouseOutText(PPUIComponent c) {
    if (selected_tx != null && selected_tx == c) { 
      PPUIText t = (PPUIText)selected_tx;
      int pos = active_view.moveCursorToPosition(t, mouseX, mouseY);
      t.setHighlighEnd(pos);
      t.status = SELECTED;
    }
  }

  void addAnimation() {
    if (sceneview.current_scene != null) {

      PPAnimation anim = creator.createAnimation(this, "animation" + track_cnt.getCounter(), sceneview.current_scene);
      sceneview.addAnimation(anim);
    }
  }
  void checkKey() {
    if (key == CODED) {
      if (keyCode == CONTROL || keyCode == 157) {
        isControl = true;
      } else if (key == ALT) {
        isAlt = true;
      }  
      if (keyCode == UP) {
        if (selected_tx != null) {
          selected_tx.arrowUp();
          return;
        }
      }
      if (keyCode == DOWN) {
        if (selected_tx != null) {
          selected_tx.arrowDown();
          return;
        }
      }
      if (keyCode == LEFT) {
        if (selected_tx != null) {
          selected_tx.arrowLeft();
          return;
        }
      }
      if (keyCode == RIGHT) {
        if (selected_tx != null) {
          selected_tx.arrowRight();
          return;
        }
      }
    }
    if (key == BACKSPACE) {
      if (selected_tx != null) {
        if (selected_tx.isHighlighted) {
          selected_tx.deleteHighlight();
        } else {
          selected_tx.deleteChar(false);
        }
        return;
      }
      if (selected_tr != null && selected_tr.type == "animation") {
        if (selected_tr.status == SELECTED) {
          // erase all, or erase a selected portion
        } else {
          selected_tr.deleteSelection();
        }
        return;
      }
    } else if (key == DELETE) {
      if (selected_tx != null) {
        if (selected_tx.isHighlighted) {
          selected_tx.deleteHighlight();
        } else {
          selected_tx.deleteChar(true);
        }
        return;
      }

      if (selected_tr != null && selected_tr.type == "animation") {
        if (selected_tr.status == SELECTED) {
          // erase all, or erase a selected portion
        } else {
          selected_tr.deleteSelection();
        }
        return;
      }
    } else if (key == ENTER || key == RETURN) {
    } else if ((key>= ' ' && key <= '~') &&  selected_tx != null) {
      if (isControl) {
        if (key == 'x' || key == 'X') {
          pasteBoard = selected_tx.cut();
        } 
        if (key == 'c' || key == 'C') {
          pasteBoard = selected_tx.copy();
        }
        if (key == 'v' || key == 'V') {
          selected_tx.paste(pasteBoard);
        }
      } else {
        selected_tx.addChar(str(key));
      }
    }
  }
}


///////////////////////////////////////////////////////////
// Message class
//
// A message briefly appears at the bottom of the screen and disappears
//////////////////////////////////////////////////////////
class Message {
  String msg;
  int _left, _top, _width, _height;
  PFont font;
  int counter;
  int millis;
  Message() {
    msg = "";
    _width = width*3/4;
    _height = 18;
    _left = 5;
    _top = height-_height-11;
    font = createFont("Arial", 11);
    counter = 0;
  }

  void setMessage(String str) {
    msg = str;
    // should also log this
    counter = 4000;
    millis = millis();
  }

  void display() {
    _width = width*3/4;
    _top = height-_height-11;
    if (counter != 0) {
      fill(0, 180);
      rect(_left, _top, _width, _height, 5);
      fill(255);
      textFont(font);
      text(msg, _left+5, _top+14); 
      counter = counter - (millis() - millis);
      if (counter < 0) counter = 0;
      millis = millis();
    }
  }
}

/////////////////////////////////////////////////////////
// Variable class (should transfer to another file)
//
// A variable may influence the show flow
/////////////////////////////////////////////////////////
class Variable extends PPData {
  int base_value;
  int max_value;
  int value;
  int _width;
  int _height;
  PFont font;
  PPUIList interactions;

  Variable(String n, int base, int max) {
    name = n;
    id = data_cnt.getCounter();
    base_value = base;
    max_value = max;
    value = base;
    type= "variable";
    font = createFont("Arial", 13);
    _width = width/4;
    _height = 25;
    _left = 0;


    String[] list = {
      "None", "Increase", "Reset", "Random"
    };
    interactions = new PPUIList(controller, "interactions options", 130, 0, list); 
    interactions.fixed_position = false;
    interactions.parent = this;
    interactions.canResize = true;
    interactions.default_selection = 0;
    associateComponent(interactions);
  } 

  void display(PGraphics p) {
    p.stroke(140);
    p.strokeWeight(1);

    p.fill(0);
    p.textAlign(LEFT);
    p.line(_left, _top, _left+_width, _top);

    if (vars.indexOf(this) %  2 == 0) {
      p.fill(210);
      p.noStroke();
      p.rect(_left, _top, _width, 25);
      p.fill(0);
      p.stroke(140);
    }
    p.fill(0);

    p.textFont(font);
    p.text(name+" (ID:"+id+")", _left+10, _top+17);

    p.line( _left, _top+25, _left+_width, _top+25);
  }
  JSONObject writeToJSON() {
    JSONObject var = new JSONObject();
    var.setString("type", type);
    var.setString("name", name);
    var.setInt("id", id);
    var.setInt("base value", base_value);
    var.setInt("max value", max_value);
    return var;
  }
  void readFromJSON(JSONObject jo) {
    name = jo.getString("name");
    id = jo.getInt("id");
    base_value = jo.getInt("base value");
    max_value = jo.getInt("max value");
  }

  boolean isChild(PPData parent) {
    if (parent.type == "variable event") {
      if (((PPVariable)parent).variable == this) return true;
    }
    return false;
  }
  void interact(int interaction) {
    if (interaction == NONE) {
    } else if (interaction == INCREMENT) {

      if (value < max_value) value++;
    } else if (interaction == RESET) {
      value = base_value;
    } else if (interaction == RANDOM) {
      value = floor(random(base_value, max_value+1));
    }
  } 

  void reset() {
    value = base_value;
  }
}

