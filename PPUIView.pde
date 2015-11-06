//////////////////////////////////////////////
// Views
// this file has the general PPUIView as well as the specific
// *OverviewView
// *SceneView
// *SettingsView
// *CodeView
/////////////////////////////////////////////
class PPUIView extends PPUICollection {

  int label_width = 0;
  int label_height = 0;
  // upper portion is for view specific buttons
  int top_nav_h = 70;
  int labels_h = 30;

  PFont m_font;
  int font_size;

  PPUIView(Controller c) {
    super (c, "view", 0, 0, width, height);

    label_height = labels_h;
    label_width = (width*2/3) / 4; // 4 is the number of views  
    type = "view";
  }
  PPUIComponent isInsideComponent(int x, int y) {
    return null;
  }
  PPData isInsideData(int x, int y) {
    return null;
  }
  void activate() {
    status = SELECTED;
    makeVisible();
  }
  void deactivate() {
    status = INVISIBLE;
    makeInvisible();
  }
  void verticalScroll(float e) {
  }

  int getYOffset() {
    return top_nav_h + labels_h;
  }
  void display() {
    super.display();
  }
  int moveCursorToPosition(PPUIText t, int x, int y) { 
    return -1;
  }
}

//////////////////////////////////////////////
// OverviewView
/////////////////////////////////////////////
class OverviewView extends PPUIView {

  PPUICanvas main;
  PPUICollection nav;
  PPUICollection tabs;

  PGraphics canvas;
  PPUIGraphics canvas_holder;
  int canvas_h;
  int canvas_w;

  StopButton sb;
  PlayButton pb;
  PPUITabLabel tab = null;
  int millis = 0;
  OverviewView(Controller c) {
    super(c);
    canvas_h = height;
    canvas_w = width;
    main = new PPUICanvas(controller, 0, getYOffset(), width, height-getYOffset(), 0, 0, canvas_w, canvas_h );
    main.name = "overview canvas";
    main.bringToFront(main.vs);
    main.bringToFront(main.hs);
    main.setData(data); // from the main applet
    nav = new PPUICollection(controller, "navigation", 0, 0, width, top_nav_h);
    tabs = new PPUICollection(controller, "tabs", 0, top_nav_h, width, labels_h);

    name = "Overview";

    PGraphics nav_bg = createGraphics(width, top_nav_h);
    nav_bg.beginDraw();
    nav_bg.background(0);
    nav_bg.endDraw();
    nav.addComponent(new PPUIGraphics(controller, "nav bg", 0, 0, width, top_nav_h, nav_bg ));

    font_size = 20;
    m_font = createFont("Arial", font_size);
    pb = new PlayButton(c);
    sb = new StopButton(c);
    pb._stop = sb;
    sb._play = pb;
    sb.makeInvisible();
    PGraphics p = createGraphics(40, 40);
    PImage img = loadImage("new.png");
    p.beginDraw();
    p.background(255);
    p.image(img, 0, 0, 40, 40);
    p.endDraw();
    NewScene ns = new NewScene(c, "new scene", "", p, width-220, 10, 50, 50);
    p = createGraphics(40, 40);
    img = loadImage("edit.png");
    p.beginDraw();
    p.background(255);
    p.image(img, 0, 0, 40, 40);
    p.endDraw();
    EditSceneIcon es = new EditSceneIcon(c, "edit scene", "", p, width-120, 10, 50, 50);
    p = createGraphics(40, 40);
    img = loadImage("delete.png");
    p.beginDraw();
    p.background(255);
    p.image(img, 0, 0, 40, 40);
    p.endDraw();
    DeleteScene ds = new DeleteScene(c, "delete scene", "", p, width-170, 10, 50, 50);
    p = createGraphics(40, 40);
    img = loadImage("newfile.png");
    p.beginDraw();
    p.background(255);
    p.image(img, 0, 0, 40, 40);
    p.endDraw();
    NewFile nf = new NewFile(c, "new file", "", p, 70, 10, 50, 50);
    p = createGraphics(40, 40);
    img = loadImage("save.png");
    p.beginDraw();
    p.background(255);
    p.image(img, 0, 0, 40, 40);
    p.endDraw();
    SaveFile sf = new SaveFile(c, "save file", "", p, 120, 10, 50, 50);
    p = createGraphics(40, 40);
    img = loadImage("load.png");
    p.beginDraw();
    p.background(255);
    p.image(img, 0, 0, 40, 40);
    p.endDraw();
    LoadFile lf = new LoadFile(c, "load file", "", p, 170, 10, 50, 50);


    ResizeButton rb = new ResizeButton(c);

    nav.addComponent(rb);

    nav.addComponent(sb);
    nav.addComponent(pb);
    nav.addComponent(ns);
    nav.addComponent(es);
    nav.addComponent(ds);
    nav.addComponent(nf);
    nav.addComponent(sf);
    nav.addComponent(lf);

    PPUITabLabel[] tab_labels = c.getTabs();
    if (tab_labels.length == 4) {
      tabs.addComponent(tab_labels[0]);
      tabs.addComponent(tab_labels[1]);
      tabs.addComponent(tab_labels[2]);
      tabs.addComponent(tab_labels[3]);
      tab = tab_labels[0];
    }

    addComponent(main);
    addComponent(nav);
    addComponent(tabs);
  }

  int getYOffset() {
    return top_nav_h + labels_h;
  }

  void calcCanvas() {
    if (scenes != null) {
      canvas_h = 50;
      canvas_w = 50;
      for (int i = 0; i < scenes.size (); i++) {
        PPScene s = scenes.get(i);      
        if (s.getBottom() + 50 > canvas_h) canvas_h = s.getBottom()  + 50;
        if (s.getRight()  + 50 > canvas_w) canvas_w = s.getRight()  + 50;
      }
      main.updateDrawingArea(canvas_w, canvas_h);
    }
  }
  PPData isInsideData(int x, int y) {
    main.setData(data);
    PPData d = main.isInsideData(x, y);
    return d;
  }
  PPUIComponent isInsideComponent(int x, int y) {
    PPUIComponent c = super.isInside(x, y, true);
    return c;
  }
  boolean isInside(PPScene s, int x, int y) {
    return s.isInside(int(x-main.getEffectiveLeft()), int(y-main.getEffectiveTop()));
  }
  boolean isInside(PPTransition t, int x, int y) {
    return t.isInside(int(x-main.getEffectiveLeft()), int(y-main.getEffectiveTop()));
  }

  int moveCursorToPosition(PPUIText t, int x, int y) {
    if (t.fixed_position) {
      int pos = t.moveCursorToPosition(mouseX, mouseY);
      return pos;
    } else {
      int pos = t.moveCursorToPosition(mouseX-main.getEffectiveLeft(), mouseY-main.getEffectiveTop());
      return pos;
    }
  }
  void update(PPScene s, int _mouseX, int  _mouseY, int lastX, int lastY) {
    s.update(_mouseX-lastX, _mouseY-lastY);
    calcCanvas();
    main.updateDrawingArea( canvas_w, canvas_h );
  }
  void update(PPTransition t, int _mouseX, int  _mouseY, int lastX, int lastY) {
    if (t.type == "stub") {
      t.update(int(_mouseX-main.getEffectiveLeft()), int(_mouseY-main.getEffectiveTop()));
    } else {
      t.update(_mouseX-lastX, _mouseY-lastY);
    }
  }

  void display() {
    tab.setStatus(SELECTED);
    main.setData(data);
    calcCanvas();
    if (pb.status != INVISIBLE && !controller.singleStart()) pb.status = DISABLE;
    else if (pb.status != INVISIBLE) pb.status = IDLE;
    main.updateDrawingArea(canvas_w, canvas_h );

    if (status == PLAYING) {
      int diff = millis() - millis;
      millis = millis();
      int done = 0;
      if (controller.selected_s.status == PLAYING) {
        done = controller.selected_s.updatePosition(diff);
      }

      if (done == 0 && controller.selected_s.isDone == true ) {
        if (controller.selected_s.isEnd || isDone()) {
          sb.trigger();
        } else {
          controller.selected_s.activateSensors();
          controller.selected_s.status = IDLE;
          controller.selected_s.isDone = false;
        }
      }
    }
    if   (status == PLAYING && controller.selected_s.status == IDLE) {
      checkTransitions();
    }
    super.display();
  }

  void verticalScroll(float e) {
    // move vs by e (if it is visible)
    main.verticalScroll(e);
  }
  void update(int deltaX, int deltaY) {
    main.update(deltaX, deltaY);
  }

  void play() {
    status = PLAYING;
    millis = millis();
    controller.selected_s.setPosition(0);
    controller.selected_s.play();
  }
  void activateTransitions() {
    PPScene s = controller.selected_s;
    for (int i = 0; i<s.outgoing.size (); i++) {
      if (s.outgoing.get(i).type != "stub") {
        ((PPTransition)s.outgoing.get(i)).activateSensors();
      }
    }
  }
  boolean isDone() {
    boolean events = false;
    int count = 0;
    PPScene s = controller.selected_s;
    for (int i = 0; i<s.outgoing.size (); i++) {
      if (s.outgoing.get(i).type != "stub") {
        count++;
        events = events || ((PPTransition)s.outgoing.get(i)).anyEvents();
      }
    }
    if (events == false || count == 0) return true;
    return false;
  }
  void checkTransitions() {
    if (status == PLAYING) {
      PPScene s = controller.selected_s;
      for (int i = 0; i<s.outgoing.size (); i++) {
        if (s.outgoing.get(i).type != "stub" && ((PPTransition)s.outgoing.get(i)).isTriggered()) {
          controller.selected_s = ((PPTransition)s.outgoing.get(i)).destination;
          play();
        }
      }
    }
  }
  void pause() {
    status = IDLE;
    controller.selected_s.pause();
  }
}

//////////////////////////////////////////////
// SceneView
/////////////////////////////////////////////
class SceneView extends PPUIView {
  ArrayList<PPScene> scenes;
  ArrayList<PPTransition> trans;

  PPUICanvas main;
  PPUICollection nav;
  PPUICollection tabs;
  PPUICanvas variables;
  PPTable var_list = null;

  PPScene current_scene;

  Controller controller;
  PGraphics tracks;
  PPUIGraphics tracks_holder;
  int tracks_h;
  int tracks_w;

  int text_area_w = width/4;
  PPUITabLabel tab = null;

  PPUIText scene_name;
  PPUIText text;
  PPUIText rename;

  float scale = 0.023;
  int millis;
  PlayButton pb;
  StopButton sb;
  ZoomIn zi;
  ZoomOut zo;
  SceneView(Controller c) {
    super(c);
    tracks_h = height;
    tracks_w = width;
    main = new PPUICanvas(controller, text_area_w, getYOffset(), width-text_area_w, height-getYOffset(), 0, 0, tracks_w, tracks_h );
    main.name = "scene canvas";
    tracks = createGraphics( width, height);
    tracks.beginDraw();
    tracks.background(180);
    tracks.endDraw();
    main.bringToFront(main.vs);
    main.bringToFront(main.hs);

    variables= new PPUICanvas(controller, 0, height-height/4, text_area_w, height/4, 0, height-height/4, text_area_w, height/4 );
    variables.name = "variables canvas";
    variables.setData(vars); 
    variables.disableHorizontalScroll=true;

    nav = new PPUICollection(controller, "navigation", 0, 0, width, top_nav_h);
    tabs = new PPUICollection(controller, "navigation", 0, top_nav_h, width, labels_h);

    name = "Sceneview";
    scenes = c.getScenes();
    trans = c.getTransitions();

    PGraphics nav_bg = createGraphics(width, top_nav_h);
    nav_bg.beginDraw();
    nav_bg.background(0);
    nav_bg.endDraw();
    nav.addComponent(new PPUIGraphics(controller, "nav bg", 0, 0, width, top_nav_h, nav_bg ));

    font_size = 20;
    m_font = createFont("Arial", font_size);
    pb = new PlayButton(c);
    sb = new StopButton(c);
    pb._stop = sb;
    sb._play = pb;
    sb.makeInvisible();
    nav.addComponent(sb);
    nav.addComponent(pb);

    PGraphics p = createGraphics(40, 40);
    PImage img = loadImage("zoomin.png");
    p.beginDraw();
    p.background(255);
    p.image(img, 0, 0, 40, 40);
    p.endDraw();
    zi = new ZoomIn(c, "zoom in", "", p, width-120, 10, 50, 50);
    p = createGraphics(40, 40);
    img = loadImage("zoomout.png");
    p.beginDraw();
    p.background(255);
    p.image(img, 0, 0, 40, 40);
    p.endDraw();
    zo = new ZoomOut(c, "zoom out", "", p, width-170, 10, 50, 50);
    p = createGraphics(40, 40);
    img = loadImage("prev.png");
    p.beginDraw();
    p.background(255);
    p.image(img, 0, 0, 40, 40);
    p.endDraw();
    PrevScene ps = new PrevScene(c, "prev scene", "", p, width-280, 10, 50, 50);
    p = createGraphics(40, 40);
    img = loadImage("next.png");
    p.beginDraw();
    p.background(255);
    p.image(img, 0, 0, 40, 40);
    p.endDraw();
    NextScene ns = new NextScene(c, "next scene", "", p, width-230, 10, 50, 50);
    p = createGraphics(40, 40);
    img = loadImage("colors.png");
    p.beginDraw();
    p.background(255);
    p.image(img, 0, 0, 40, 40);
    p.endDraw();
    SceneColor sc = new SceneColor(c, "scene color", "", p, width-340, 10, 50, 50);
    p = createGraphics(40, 40);
    img = loadImage("record.png");
    p.beginDraw();
    p.background(255);
    p.image(img, 0, 0, 40, 40);
    p.endDraw();
    Record rec = new Record(c, "record", "", p, 230, 10, 50, 50);
    p = createGraphics(40, 40);
    img = loadImage("stop.png");
    p.beginDraw();
    p.background(255);
    p.image(img, 5, 5, 30, 30);
    p.endDraw();
    StopRecord stop_rec = new StopRecord(c, "stop record", "", p, 230, 10, 50, 50);
    stop_rec.status = INVISIBLE;
    stop_rec.rec = rec;
    rec.stop = stop_rec;
    p = createGraphics(40, 40);
    img = loadImage("movement.png");
    p.beginDraw();
    p.background(255);
    p.image(img, 5, 5, 30, 30);
    p.endDraw();
    AddAnimation anim = new AddAnimation(c, "add animation", "", p, 280, 10, 50, 50);

    p = createGraphics(40, 40);
    img = loadImage("newfile.png");
    p.beginDraw();
    p.background(255);
    p.image(img, 0, 0, 40, 40);
    p.endDraw();
    NewFile nf = new NewFile(c, "new file", "", p, 70, 10, 50, 50);
    p = createGraphics(40, 40);
    img = loadImage("save.png");
    p.beginDraw();
    p.background(255);
    p.image(img, 0, 0, 40, 40);
    p.endDraw();
    SaveFile sf = new SaveFile(c, "save file", "", p, 120, 10, 50, 50);
    p = createGraphics(40, 40);
    img = loadImage("load.png");
    p.beginDraw();
    p.background(255);
    p.image(img, 0, 0, 40, 40);
    p.endDraw();
    LoadFile lf = new LoadFile(c, "load file", "", p, 170, 10, 50, 50);

    ResizeButton rb = new ResizeButton(c);  
    nav.addComponent(rb);

    nav.addComponent(zi);
    nav.addComponent(zo);
    nav.addComponent(ps);
    nav.addComponent(ns);
    nav.addComponent(sc);
    nav.addComponent(nf);
    nav.addComponent(sf);
    nav.addComponent(lf);

    nav.addComponent(stop_rec);
    nav.addComponent(rec);
    nav.addComponent(anim);

    PPUITabLabel[] tab_labels = c.getTabs();
    if (tab_labels.length == 4) {
      tabs.addComponent(tab_labels[0]);
      tabs.addComponent(tab_labels[1]);
      tabs.addComponent(tab_labels[2]);
      tabs.addComponent(tab_labels[3]);
      tab = tab_labels[1];
    }

    addComponent(main);
    addComponent(nav);
    addComponent(tabs);
    addComponent(variables);
  }
  PPData isInsideData(int x, int y) {
    PPData d = main.isInsideData(x, y);
    return d;
  }
  PPUIComponent isInsideComponent(int x, int y) {
    PPUIComponent c = super.isInside(x, y, true);
    return c;
  }
  void setScene(PPScene s) {
    ArrayList<PPData> data;
    if (current_scene != null) {
      data = current_scene.getData();
      for (int i = 0; i<data.size (); i++) {
        unregisterComponents(data.get(i));
      }
      for (int i = 0; i<current_scene.associated_components.size (); i++) {
        removeComponent(current_scene.associated_components.get(i));
      }
      for (int i = 0; i<vars.size (); i++) {
        variables.removeComponent(((Variable)vars.get(i)).interactions);
      }
    }

    current_scene = s;
    data = current_scene.getData();
    calcCanvas();
    for (int i = 0; i<data.size (); i++) {
      PPData d = data.get(i);
      if (d.type == "audio" || d.type == "animation") {
        ((PPTrack)d).rename.status = INVISIBLE;
      }
    }

    for (int i = 0; i<data.size (); i++) {
      registerComponents(data.get(i));
    }
    current_scene.syncInteractions();
    for (int i = 0; i<vars.size (); i++) {
      variables.addComponent(((Variable)vars.get(i)).interactions);
      current_scene.setInteraction(((Variable)vars.get(i)).interactions, vars.get(i).id);
    }

    for (int i = 0; i<s.associated_components.size (); i++) {
      addComponent(s.associated_components.get(i));
      if (s.associated_components.get(i).name == "scene name") {
        scene_name = (PPUIText)s.associated_components.get(i);
        scene_name.updateDrawingAreas(_left+10, _top+getYOffset(), text_area_w-20, 35, _left+10, _top+getYOffset(), text_area_w-20, 35);
        scene_name.status = IDLE;
      }
      if (s.associated_components.get(i).name == "text") {
        text = (PPUIText)s.associated_components.get(i);
        text.updateDrawingAreas( _left+10, _top+getYOffset()+40, text_area_w-20, height-getYOffset()-55 - height/4, _left+10, _top+getYOffset()+40, text_area_w-20, height-getYOffset()-55 - height/4);
        text.status = IDLE;
      }
    }
    main.setData(s.getData());
  }
  int getYOffset() {
    return top_nav_h + labels_h;
  }
  PPUIText editTrackName(PPData d) {

    PPTrack track = (PPTrack)d;
    track.rename.setText(track.name);
    track.rename.makeVisible();
    return track.rename;
  }
  void doneTrackName(PPData d) {
    if (d == null) return;
    if (((PPTrack)d).rename != null) {
      ((PPTrack)d).rename.makeInvisible();
      d.name = ((PPTrack)d).rename.getText();
    }
    if (d.type == "audio") {
      // rename the file itself
    }
  }
  void calcVariables() {
    int h = 10;
    int top_offset = 0;
    for (int i =0; i<vars.size (); i++) {
      Variable c = (Variable)vars.get(i);

      c._top = h;
      c.interactions._top = h;
      h+=c.interactions._height;
    }
    h = max(h, vars.size()*25);
    variables.updateDrawingArea(width/4, h+20 );
  }
  void calcCanvas() {

    if (current_scene != null) {


      if (current_scene.isUpdated) {
        ArrayList<PPData> data = current_scene.getData();
        tracks_w = 0;
        tracks_h = 0;
        // the playing header is the top 20 pixels of canvas
        int offset = 20;
        for (int i = 0; i<data.size (); i++) {
          PPData d = data.get(i);
          if (d.name != "header") {
            d._left = 0;
            d._top = offset;
            offset+=d.getHeight()+5;
            rename = ((PPTrack)d).rename;
            rename.updateDrawingAreas(rename._left, d._top+track_h/2-12, rename._width, rename._height, rename._left, d._top+track_h/2-12, rename._width, rename._height);
          }

          if (tracks_w < d.getWidth()) {
            tracks_w = d.getWidth();
          }
        }
        tracks_h = offset;
        current_scene.isUpdated = false;
      }
    }
  }
  int moveCursorToPosition(PPUIText t, int x, int y) {
    if (t.fixed_position) {
      int pos = t.moveCursorToPosition(mouseX, mouseY);
      return pos;
    } else {
      int pos = t.moveCursorToPosition(mouseX-main.getEffectiveLeft(), mouseY-main.getEffectiveTop());
      return pos;
    }
  }
  boolean isInside(PPScene s, int x, int y) {
    return s.isInside(int(x+main.getEffectiveLeft()), int(y+main.getEffectiveTop()));
  }

  void display() {
    calcCanvas(); 
    calcVariables();
    tab.setStatus(SELECTED);
    for (int i = 0; i<vars.size (); i++) {
      addComponent(((Variable)vars.get(i)).interactions);
      current_scene.copyInteraction(((Variable)vars.get(i)).interactions, vars.get(i).id);
    }
    zo.scale = scale;
    zi.scale = scale;
    current_scene.name = scene_name.getText();
    current_scene.text = text.getText();

    main.updateDrawingArea(tracks_w+10, tracks_h );
    if (status == PLAYING) {
      int diff = millis() - millis;
      millis = millis();
      int done = current_scene.updatePosition(diff);
      if (done == 0) sb.activate();   // activate stop button
    }
    super.display();
  }
  void addAnimation(PPAnimation anim) {
    registerComponents(anim);
    current_scene.isUpdated = true;
  }
  void verticalScroll(float e) {
    // move vs by e (if it is visible)
    main.verticalScroll(e);
  }

  void registerComponents(PPData d) {
    for (int i = 0; i<d.associated_components.size (); i++) {
      main.addComponent(d.associated_components.get(i));
    }
  }
  void unregisterComponents(PPData d) {
    for (int i = 0; i<d.associated_components.size (); i++) {
      main.removeComponent(d.associated_components.get(i));
    }
  }
  void update(PPTrack tr, int _mouseX, int  _mouseY, int lastX, int lastY) {
    tr.update(int(_mouseX-main.getEffectiveLeft()), lastX, int(_mouseY-main.getEffectiveTop()), lastY);
  }

  void keyFrameAt(PPTrack tr, int x, int y) {
    ((PPAnimation)tr).keyFrameAt(x- main.getEffectiveLeft(), y-main.getEffectiveTop());
  }
  void update(int deltaX, int deltaY) {
    main.update(deltaX, deltaY);
    text.update(deltaX, deltaY);
    variables.update(deltaX, deltaY);
  }
  void play() {
    status = PLAYING;
    millis = millis();
    current_scene.play();
  }
  void pause() {
    status = IDLE;
    current_scene.pause();
  }
}

//////////////////////////////////////////////
// SettingView
/////////////////////////////////////////////
class SettingsView extends PPUIView {
  PPUICanvas main;
  PPUICanvas panel;
  PPUICollection nav;
  PPUICollection tabs;

  Controller controller;
  PGraphics canvas;
  PPUIGraphics canvas_holder;
  int canvas_h;
  int canvas_w;
  int panel_h;
  int panel_w;
  PPUITabLabel tab = null;

  Representation current_representation = null;
  Representation targeted = null;

  SettingsView(Controller c) {
    super(c);
    canvas_h = height;
    canvas_w = width;
    main = new PPUICanvas(controller, 0, getYOffset(), width, height/3, 0, 0, canvas_w, canvas_h );
    main.name = "resources canvas";
    main.bringToFront(main.vs);
    main.bringToFront(main.hs);

    panel_h = height - height/3-getYOffset()-2;
    panel_w = width*2/3-2;
    panel = new PPUICanvas(controller, width/3+2, height/3 + getYOffset()+2, panel_w, panel_h, 0, 0, panel_w, panel_h );
    panel.name = "resources panel";
    panel.bringToFront(panel.vs);
    panel.bringToFront(panel.hs);

    nav = new PPUICollection(controller, "navigation", 0, 0, width, top_nav_h);
    tabs = new PPUICollection(controller, "tabs", 0, top_nav_h, width, labels_h);

    name = "Resources";

    PGraphics nav_bg = createGraphics(width, top_nav_h);
    nav_bg.beginDraw();
    nav_bg.background(0);
    nav_bg.endDraw();
    nav.addComponent(new PPUIGraphics(controller, "nav bg", 0, 0, width, top_nav_h, nav_bg ));

    font_size = 20;
    m_font = createFont("Arial", font_size);
    PlayButton pb = new PlayButton(c);
    StopButton sb = new StopButton(c);
    pb._stop = sb;
    sb._play = pb;
    sb.makeInvisible();
    ResizeButton rb = new ResizeButton(c);

    PGraphics p = createGraphics(40, 40);
    PImage img = loadImage("new.png");
    p.beginDraw();
    p.background(255);
    p.image(img, 0, 0, 40, 40);
    p.endDraw();
    NewResource nr = new NewResource(c, "new scene", "", p, width-220, 10, 50, 50);

    p = createGraphics(40, 40);
    img = loadImage("delete.png");
    p.beginDraw();
    p.background(255);
    p.image(img, 0, 0, 40, 40);
    p.endDraw();
    DeleteResource dr = new DeleteResource(c, "delete scene", "", p, width-170, 10, 50, 50);

    p = createGraphics(40, 40);
    img = loadImage("newfile.png");
    p.beginDraw();
    p.background(255);
    p.image(img, 0, 0, 40, 40);
    p.endDraw();
    NewFile nf = new NewFile(c, "new file", "", p, 70, 10, 50, 50);
    p = createGraphics(40, 40);
    img = loadImage("save.png");
    p.beginDraw();
    p.background(255);
    p.image(img, 0, 0, 40, 40);
    p.endDraw();
    SaveFile sf = new SaveFile(c, "save file", "", p, 120, 10, 50, 50);
    p = createGraphics(40, 40);
    img = loadImage("load.png");
    p.beginDraw();
    p.background(255);
    p.image(img, 0, 0, 40, 40);
    p.endDraw();
    LoadFile lf = new LoadFile(c, "load file", "", p, 170, 10, 50, 50);

    nav.addComponent(sb);
    nav.addComponent(pb);
    nav.addComponent(rb);
    nav.addComponent(nr);
    nav.addComponent(dr);
    nav.addComponent(nf);
    nav.addComponent(sf);
    nav.addComponent(lf);

    PPUITabLabel[] tab_labels = c.getTabs();
    if (tab_labels.length == 4) {
      tabs.addComponent(tab_labels[0]);
      tabs.addComponent(tab_labels[1]);
      tabs.addComponent(tab_labels[2]);
      tabs.addComponent(tab_labels[3]);
      tab = tab_labels[2];
    }

    addComponent(main);
    addComponent(panel);
    addComponent(nav);
    addComponent(tabs);
  }

  void setResource(PPData d) {
    if (current_representation != null) {
      for (int i = 0; i<current_representation.associated_components.size (); i++) {
        PPUIComponent c = current_representation.associated_components.get(i);
        if (c.type=="list") ((PPUIList)c).shrink();
      }
      calcPanel();
      current_representation.status = IDLE;
      unregisterComponents((PPData)current_representation);
    }
    current_representation = (Representation)d;
    if (current_representation != null) {
      current_representation.status = SELECTED;
      current_representation.bringToFocus();
      // add panel elements for representation
      registerComponents(current_representation);
    }
    calcPanel();
  }

  void registerComponents(PPData d) {
    for (int i = 0; i<d.associated_components.size (); i++) {
      d.associated_components.get(i).status = IDLE;
      panel.addComponent(d.associated_components.get(i));
    }
  }
  void unregisterComponents(PPData d) {
    for (int i = 0; i<d.associated_components.size (); i++) {
      d.associated_components.get(i).status = INVISIBLE;
      panel.removeComponent(d.associated_components.get(i));
    }
  }
  int getYOffset() {
    return top_nav_h + labels_h;
  }
  void calcPanel() {
    int w = 10;
    int h = 10;
    int top_offset = 0;
    for (int i =0; i<panel.components.size (); i++) {
      PPUIComponent c =   panel.components.get(i);

      c._top += top_offset;
      if (c.type != "scroller") {
        w = max(w, c._left + c._width+10);
        h = max(h, c._top+c._height+10);
      }
      if (c.canResize && c.isUpdated) {
        top_offset += c.offsetBy;
        c.isUpdated = false;
      }
    }
    panel_w = w;
    panel_h = h;
    panel.updateDrawingArea(panel_w, panel_h);
  }
  void calcCanvas() {
    canvas_h = 50;
    canvas_w = 50;
    int x = 10;
    int y = 10;
    for (int i = 0; i<representations.size (); i++) {
      Representation r = (Representation)representations.get(i);      
      r._left = x;
      r._top = y;
      canvas_h = max(canvas_h, y+110);
      canvas_w = max(canvas_w, x+90);
      x += 90;
      if (x + 90 > _width) {
        y += 110;
        x = 10;
      }
    }
    main.updateDrawingArea(canvas_w, canvas_h);
  }
  PPData isInsideData(int x, int y) {
    PPData d = main.isInsideData(x, y);
    return d;
  }
  PPUIComponent isInsideComponent(int x, int y) {
    PPUIComponent c = super.isInside(x, y, true);
    return c;
  }
  int moveCursorToPosition(PPUIText t, int x, int y) {
    if (t.fixed_position) {
      int pos = t.moveCursorToPosition(mouseX, mouseY);
      return pos;
    } else {
      int pos = t.moveCursorToPosition(mouseX-panel.getEffectiveLeft(), mouseY-panel.getEffectiveTop());
      return pos;
    }
  }
  void display() {
    background(255);
    tab.setStatus(SELECTED);
    main.setData(representations);
    calcCanvas();
    calcPanel();
    noStroke();
    fill(120);
    rect(0, height/3+getYOffset(), width/3, height - height/3-getYOffset());
    if (current_representation != null) {
      int x = (width/3 - current_representation.preview.width)/2;
      int y = height/3+getYOffset()+ (height - height/3-getYOffset() - current_representation.preview.height)/2;
      textSize(16);
      textAlign(CENTER, CENTER);
      fill(170);
      text("ID:("+current_representation.data.id+")", 0, y, width/3, 20);
      image(current_representation.preview, x, y);
      fill(0);
      text(current_representation.data.name, 0, y+140, width/3, 20);
    }
    stroke(0);
    strokeWeight(2);
    line(0, height/3+getYOffset(), width, height/3+getYOffset());
    line(width/3, height/3+getYOffset(), width/3, height);
    super.display();
    if (current_representation != null) {
      if (current_representation.status == DRAGGED && mouseX < width-15) {
        fill(255);
        stroke(0);
        rect(mouseX, mouseY, current_representation._width, current_representation._height, 10); 
        image( current_representation.icon, mouseX, mouseY);
      }
    }
  }

  void dragging(Representation r) {
    if (!main.isInside(mouseX, mouseY)) {
      if (r!=null) {
        r.status=SELECTED;
      } 
      return;
    }
    if (r != null) {
      PPData d_in = isInsideData(mouseX, mouseY);
      if (d_in != null && d_in != current_representation) {
        if (targeted != null && targeted != d_in) {
          targeted.status = IDLE;
        }
        Representation d = (Representation)d_in;
        if (r.data.type == "animation" && d.data.type=="actuator") {
          targeted = (Representation)d;
          d.status = TARGETED;
        } else if (r.data.type == "actuator" && (d.data.type=="animation" || d.data.type=="hardware controller")) {
          targeted = (Representation)d;
          d.status = TARGETED;
        } else if (r.data.type == "sensor" && (d.data.type=="hardware controller" || d.data.type=="transition")) {
          targeted = (Representation)d;
          d.status = TARGETED;
        } else if (r.data.type == "hardware controller" && (d.data.type=="sensor" || d.data.type=="actuator")) {
          targeted = (Representation)d;
          d.status = TARGETED;
        } else if (r.data.type == "variable" && d.data.type=="variable event") {
          targeted = (Representation)d;
          d.status = TARGETED;
        } else if (r.data.type == "transition" && (d.data.type=="scene" || d.data.type=="sensor" || d.data.type=="timer" || d.data.type=="variable event")) {
          targeted = (Representation)d;
          d.status = TARGETED;
        } else if (r.data.type == "variable event" && (d.data.type=="variable" || d.data.type=="transition")) {
          targeted = (Representation)d;
          d.status = TARGETED;
        } else if (r.data.type == "timer" && d.data.type=="transition") {
          targeted = (Representation)d;
          d.status = TARGETED;
        } else if (r.data.type == "scene" && (d.data.type=="audio" || d.data.type=="transition")) {
          targeted = (Representation)d;
          d.status = TARGETED;
        } else if (r.data.type == "audio" && d.data.type=="scene") {
          targeted = (Representation)d;
          d.status = TARGETED;
        }
      }
    }
  }
  void verticalScroll(float e) {
    // move vs by e (if it is visible)
    main.verticalScroll(e);
  }
  void update(int deltaX, int deltaY) {
    main.update(deltaX, deltaY);
    panel.update(deltaX, deltaY);
  }
}

//////////////////////////////////////////////
// CodeView
/////////////////////////////////////////////
class CodeView extends PPUIView {
  PPUICanvas main;
  PPUICollection nav;
  PPUICollection tabs;

  Controller controller;
  PGraphics canvas;
  PPUIGraphics canvas_holder;
  int canvas_h;
  int canvas_w;

  PPUIText p_code = null;
  PPUIText a_code = null;
  PPUIList ctrl_selector = null;
  PPUITabLabel tab = null;

  CodeView(Controller c) {
    super(c);
    canvas_h = height-getYOffset();
    canvas_w = width;
    main = new PPUICanvas(controller, 0, getYOffset(), width, height-getYOffset(), 0, 0, width, canvas_h );
    PFont font = createFont("Courier", 13);
    p_code = new PPUIText(controller, "processing code", 10, 10+getYOffset(), (canvas_w -30)/2, canvas_h-20, "", font, 13);
    a_code = new PPUIText(controller, "arduino code", (canvas_w -30)/2 + 20, 10+getYOffset()+30, (canvas_w -30)/2, canvas_h-20, "", font, 13);
    PPData[] controllers = getControllersList();
    ctrl_selector = new PPUIList(controller, "controllers list", (canvas_w -30)/2 + 20, 10+getYOffset(), makeStringsFromDataList(controllers) );
    ctrl_selector.fixed_position = false;

    p_code.isDisabled = true;
    a_code.isDisabled = true;
    p_code.multiline = true;
    a_code.multiline = true;
    addComponent(a_code);
    addComponent(p_code);
    addComponent(ctrl_selector);
    main.name = "code canvas";
    main.bringToFront(main.vs);
    main.bringToFront(main.hs);
    nav = new PPUICollection(controller, "navigation", 0, 0, width, top_nav_h);
    tabs = new PPUICollection(controller, "tabs", 0, top_nav_h, width, labels_h);

    name = "Code";

    PGraphics nav_bg = createGraphics(width, top_nav_h);
    nav_bg.beginDraw();
    nav_bg.background(0);
    nav_bg.endDraw();
    nav.addComponent(new PPUIGraphics(controller, "nav bg", 0, 0, width, top_nav_h, nav_bg ));

    font_size = 20;
    m_font = createFont("Arial", font_size);
    PlayButton pb = new PlayButton(c);
    StopButton sb = new StopButton(c);
    pb._stop = sb;
    sb._play = pb;
    sb.makeInvisible();
    ResizeButton rb = new ResizeButton(c);

    PGraphics p = createGraphics(40, 40);
    PImage img = loadImage("newfile.png");
    p.beginDraw();
    p.background(255);
    p.image(img, 0, 0, 40, 40);
    p.endDraw();
    NewFile nf = new NewFile(c, "new file", "", p, 70, 10, 50, 50);
    p = createGraphics(40, 40);
    img = loadImage("save.png");
    p.beginDraw();
    p.background(255);
    p.image(img, 0, 0, 40, 40);
    p.endDraw();
    SaveFile sf = new SaveFile(c, "save file", "", p, 120, 10, 50, 50);
    p = createGraphics(40, 40);
    img = loadImage("load.png");
    p.beginDraw();
    p.background(255);
    p.image(img, 0, 0, 40, 40);
    p.endDraw();
    LoadFile lf = new LoadFile(c, "load file", "", p, 170, 10, 50, 50);

    nav.addComponent(sb);
    nav.addComponent(pb);
    nav.addComponent(rb);
    nav.addComponent(nf);
    nav.addComponent(sf);
    nav.addComponent(lf);

    PPUITabLabel[] tab_labels = c.getTabs();
    if (tab_labels.length == 4) {
      tabs.addComponent(tab_labels[0]);
      tabs.addComponent(tab_labels[1]);
      tabs.addComponent(tab_labels[2]);
      tabs.addComponent(tab_labels[3]);
      tab = tab_labels[3];
    }

    addComponent(nav);
    addComponent(tabs);
  }

  int getYOffset() {
    return top_nav_h + labels_h;
  }

  void activate() {
    p_code.setText(processing_code);
    a_code.setText(arduino_code);
    String[] controller_names = makeStringsFromDataList(getControllersList());
    ctrl_selector.updateOptions(controller_names);
    if (controller_names.length > 0) ctrl_selector.selected =0; 
    super.activate();
  }

  int moveCursorToPosition(PPUIText t, int x, int y) {
    if (t.fixed_position) {
      int pos = t.moveCursorToPosition(mouseX, mouseY);
      return pos;
    } else {
      int pos = t.moveCursorToPosition(mouseX-main.getEffectiveLeft(), mouseY-main.getEffectiveTop());
      return pos;
    }
  }
  void calcCanvas() {
  }

  PPUIComponent isInsideComponent(int x, int y) {
    PPUIComponent c = super.isInside(x, y, true);
    return c;
  }

  void display() {
    tab.setStatus(SELECTED);
    if (ctrl_selector.isUpdated) {
      ctrl_selector.isUpdated = false;
      int index = ctrl_selector.selected;
      if (index>0) {
        HardwareController h = (HardwareController)getControllersList()[index];
        generateArduinoCode(h);
        a_code.setText(arduino_code);
      }
    }
    super.display();
  }

  void verticalScroll(float e) {
    // move vs by e (if it is visible)
    main.verticalScroll(e);
  }
  void update(int deltaX, int deltaY) {
    a_code.update(deltaX, deltaY);
    p_code.update(deltaX, deltaY);
  }
}

