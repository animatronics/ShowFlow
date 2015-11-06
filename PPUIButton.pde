/////////////////////////////////////////////////////////
// The file contains the general PPUIButton class
// followed by specific buttons
/////////////////////////////////////////////////////////

class PPUIButton extends PPUIComponent {

  String text="";
  String tip="";
  PGraphics icon = null;

  color f_color;
  color b_color;

  boolean isDraggable = false;
  boolean isDragged = false;
  boolean isSelected = false;
  boolean isButton = true;

  int hit_left, hit_top, hit_width, hit_height;

  PPUIButton() {
  }
  PPUIButton(Controller c, String _name, String _text, PGraphics _icon, int _l, int _t, int _w, int _h) {
    super(c, _name, _l, _t, _w, _h);
    this.name = _name;
    this.text = _text;
    this.icon = _icon;
    type = "button";
    f_color = color(30);
    b_color = color(255);
    hit_left = _left;
    hit_top = _top;
    hit_width = _width;
    hit_height = _height;
  }

  void moveTo(int x, int y) {
    _top = y;
    _left = x;
    hit_left = _left;
    hit_top = _top;
  }

  boolean isInside(int x, int y) {
    if (status != INVISIBLE) { 
      if (x>hit_left && x<hit_left+hit_width &&
        y>hit_top && y<hit_top+hit_height) return true;
    }
    return false;
  } 


  void display() {
    if (status != INVISIBLE) {
      // it either has an icon or text
      if (icon != null) {
        fill(b_color);
        stroke(f_color);
        strokeWeight(2);
        rect(_left, _top, _width, _height, 10);
        image(icon, _left+10, _top+10, _width-20, _height-20);
      } else {
        fill(b_color);
        stroke(f_color);
        strokeWeight(2);
        rect(_left, _top, _width, _height, 10);
        fill(f_color);

        textFont(createFont("Arial", 14));
        textAlign(CENTER, CENTER);
        text(text, _left+5, _top+5, _width-10, _height-10);
      }
      if (status == HOVERED) {
        fill(180, 50);
        rect(hit_left, hit_top, hit_width, hit_height, 10);
      }
      if (status == DISABLE) {
        fill(f_color, 60);
        rect(_left, _top, _width, _height, 10);
      }
    }
  }

  void display(PGraphics canvas) {
    if (status != INVISIBLE) {
      // it either has an icon or text
      if (icon != null) {
        canvas.fill(b_color);
        canvas.stroke(f_color);
        canvas.strokeWeight(2);
        canvas.rect(_left, _top, _width, _height, 10);
        canvas.image(icon, _left+10, _top+10, _width-20, _height-20);
      } else {
        canvas.fill(b_color);
        canvas.stroke(f_color);
        canvas.strokeWeight(2);
        canvas.rect(_left, _top, _width, _height, 10);
        canvas.fill(f_color);

        canvas.textFont(createFont("Arial", 14));
        canvas.textAlign(CENTER, CENTER);
        canvas.text(text, _left+5, _top+5, _width-10, _height-10);
      }
      if (status == HOVERED) {
        canvas.fill(180, 50);
        canvas.rect(hit_left, hit_top, hit_width, hit_height, 10);
      }
      if (status == DISABLE) {
        canvas.fill(f_color, 60);
        canvas.rect(_left, _top, _width, _height, 10);
      }
    }
  }
  void activate() {
    trigger();
  }
  void trigger() {
    // do something this button is supposed to do
    status = IDLE;
  }

  void update(int delta_x, int delta_y) {
    // if dragged - then change location
    if (status == DRAGGED) {
      _top += delta_y;
      _left += delta_x;
      if (_top < 0) _top = 0;
      if (_left < 0) _left = 0;
    }
    if (status == SELECTED) {
      // do something
    }
  }
}

////////////////////////////////////////////////////////////
// PPUILabel
// not a functioning button, can be aligned
///////////////////////////////////////////////////////////
int A_CENTER = 1;
int A_LEFT = 2;
int A_RIGHT = 3;
class PPUILabel extends PPUIButton {
  PFont font;

  int alignment = A_CENTER;
  PPUILabel(Controller c, String _name, String _text, PGraphics _icon, int _l, int _t, int _w, int _h) {
    super(c, _name, _text, _icon, _l, _t, _w, _h);
    font = createFont("Arial", 14);
  }

  void display() {
    if (status != INVISIBLE) {
      // it either has an icon or text
      if (this.icon != null) {
        image(icon, _left, _top, _width, _height);
      } else {
        fill(f_color);
        textFont(font);
        if (alignment == A_CENTER) 
        {
          textAlign(CENTER, CENTER);
        } else if (alignment == A_RIGHT)
        {
          textAlign(RIGHT, CENTER);
        } else if (alignment == A_LEFT)
        {
          textAlign(LEFT, CENTER);
        } 
        text(text, _left, _top, _width, _height);
      }
    }
  }

  void display(PGraphics canvas) {
    if (status != INVISIBLE) {
      // it either has an icon or text
      if (this.icon != null) {
        canvas.image(icon, _left, _top, _width, _height);
      } else {
        canvas.fill(f_color);
        canvas.textFont(font);
        if (alignment == A_CENTER) 
        {
          canvas.textAlign(CENTER, CENTER);
        } else if (alignment == A_RIGHT)
        {
          canvas.textAlign(RIGHT, CENTER);
        } else if (alignment == A_LEFT)
        {
          canvas.textAlign(LEFT, CENTER);
        }
        canvas.text(text, _left, _top, _width, _height);
      }
    }
  }
}

//////////////////////////////////////////////////////////////
// PPUITabLAbel
// the four tabs that switch views, between button and label
/////////////////////////////////////////////////////////////
class PPUITabLabel extends PPUILabel {
  PPUIComponent activate;
  PGraphics selected;
  PGraphics idle;
  PPUITabLabel(Controller c, String _name, String _text, PGraphics _icon, int _l, int _t, int _w, int _h, PPUIComponent _activate) {
    super(c, _name, _text, _icon, _l, _t, _w, _h);
    activate = _activate;
    font = createFont("Arial", 20);
    String file1="", file2="";
    if (_text == "Overview") {
      file1 = "overview_sel.png";
      file2 = "overview.png";
    } else if (_text == "Scene") {
      file1 = "scene_sel.png";
      file2 = "scene.png";
    } else if (_text == "Resources") {
      file1 = "resources_sel.png";
      file2 = "resources.png";
    } else if (_text == "Code") {
      file1 = "code_sel.png";
      file2 = "code.png";
    }
    selected = createGraphics(_w, _h);
    idle = createGraphics(_w, _h);
    PImage img1 = loadImage(file1);
    PImage img2 = loadImage(file2);
    selected.beginDraw();
    selected.image(img1, 0, 0, 100, 30);
    selected.endDraw();
    idle.beginDraw();
    idle.image(img2, 0, 0, 100, 30);
    idle.endDraw();
  }
  void display() {
    if (status == SELECTED) {
      image(selected, _left, _top);
    }
    if (status == IDLE) {
      fill(120, 20);
      rect(_left, _top, _width, _height-5);
      image(idle, _left, _top);
    }
  }

  void trigger() {
    controller.activate(activate);
  }
}

/////////////////////////////////////////////////////////////
// start of specific buttons
/////////////////////////////////////////////////////////////


class PlayButton extends PPUIButton {

  PPUIButton _stop;
  PlayButton(Controller c) {
    super(c, "play", " ", null, 10, 10, 50, 50);
    PGraphics p = createGraphics(40, 40);
    PImage img = loadImage("play.png");
    p.beginDraw();
    p.background(255);
    p.image(img, 5, 5, 30, 30);
    p.endDraw();
    this.icon = p;
  }

  void trigger() {
    makeInvisible();
    _stop.makeVisible();
    controller.playClicked();
  }
}
class StopButton extends PPUIButton {
  PPUIButton _play;
  StopButton(Controller c) {
    super(c, "stop", " ", null, 10, 10, 50, 50);
    PGraphics p = createGraphics(40, 40);
    PImage img = loadImage("stop.png");
    p.beginDraw();
    p.background(255);
    p.image(img, 5, 5, 30, 30);
    p.endDraw();
    this.icon = p;
  }
  void trigger() {
    makeInvisible();
    _play.makeVisible();
    controller.stopClicked();
  }
}
class CloseButton extends PPUIButton {
  CloseButton(Controller c, int _left, int _top) {

    super(c, "close", " ", null, _left, _top, 30, 30);

    PGraphics p = createGraphics(10, 10);
    p.beginDraw();
    p.stroke(0);
    p.strokeWeight(2);
    p.line(0, 0, 10, 10);
    p.line(0, 10, 10, 0);
    p.endDraw();
    icon = p;
  }
  void trigger() {
    controller.dismiss();
    super.trigger();
  }
}
class EventButton extends PPUIButton {
  PPEvent e;
  EventButton(Controller c, PPEvent _e, int _left, int _top) {
    super(c, _e.name, _e.name, null, _left, _top, 50, 50);
    e = _e;

    if (e.icon != null) icon = e.icon;
  }
  void trigger() {
    if (status == INVISIBLE) return;
    if (name == "timer") {
      PPTimer t = (PPTimer)createTimer();
      controller.addEvent(t);
      controller.setResource(representationOf(t), true);
    }
    if (name == "sensor") {
      Sensor t = (Sensor)createSensor();
      controller.addEvent(t);
      controller.setResource(representationOf(t), true);
    }
    if (name == "variable event") {
      PPVariable t = (PPVariable)createVariableEvent();
      controller.addEvent(t);
      controller.setResource(representationOf(t), true);
    }
    super.trigger();
  }
}

class InsertScene extends PPUIButton {
  InsertScene(Controller c, String _name, String _text, PGraphics _icon, int _l, int _t, int _w, int _h) {
    super(c, _name, _text, _icon, _l, _t, _w, _h);
  }

  void trigger() {
    if (status == INVISIBLE) return;
    controller.addScene();
    super.trigger();
  }
}

class InsertTrans extends PPUIButton {
  int modal_l, modal_t, modal_w, modal_h;
  InsertTrans(Controller c, String _name, String _text, PGraphics _icon, int _l, int _t, int _w, int _h) {
    super(c, _name, _text, _icon, _l, _t, _w, _h);
  }
  void modalDim(int _l, int _t, int _w, int _h) {
    modal_l = _l;
    modal_t = _t;
    modal_w = _w;
    modal_h = _h;
  }

  void trigger() {
    controller.showPossibleTransitions(modal_l, modal_t, modal_w, modal_h);
    super.trigger();
  }
}

class addResource extends PPUIButton {
  addResource(Controller c, String _name, String _text, PGraphics _icon, int _l, int _t, int _w, int _h) {
    super(c, _name, _text, _icon, _l, _t, _w, _h);
  }

  void trigger() {
    controller.addResource(name);
    super.trigger();
  }
}
class TransitionToButton extends PPUIButton {
  PPScene source;
  PPScene destination;
  TransitionToButton(Controller c, String _name, String _text, PGraphics _icon, int _l, int _t, int _w, int _h, PPScene dest, PPScene src) {
    super(c, _name, _text, _icon, _l, _t, _w, _h);
    source = src;
    destination = dest;
  }
  void trigger() {
    super.trigger();
  }
}
class RemoveScene extends PPUIButton {
  RemoveScene(Controller c, String _name, String _text, PGraphics _icon, int _l, int _t, int _w, int _h) {
    super(c, _name, _text, _icon, _l, _t, _w, _h);
  }

  void trigger() {
    controller.removeScene();
    super.trigger();
  }
}
class RemoveTrans extends PPUIButton {
  RemoveTrans(Controller c, String _name, String _text, PGraphics _icon, int _l, int _t, int _w, int _h) {
    super(c, _name, _text, _icon, _l, _t, _w, _h);
  }

  void trigger() {
    if (status == INVISIBLE) return;
    controller.removeTrans();
    super.trigger();
  }
}
class EditScene extends PPUIButton {
  EditScene(Controller c, String _name, String _text, PGraphics _icon, int _l, int _t, int _w, int _h) {
    super(c, _name, _text, _icon, _l, _t, _w, _h);
  }

  void trigger() {
    controller.editScene();
    super.trigger();
  }
}


class ZoomIn extends PPUIButton {
  float scale;
  ZoomIn(Controller c, String _name, String _text, PGraphics _icon, int _l, int _t, int _w, int _h) {
    super(c, _name, _text, _icon, _l, _t, _w, _h);
  }

  void display() {
    if (scale == 1) status = DISABLE;
    else status = IDLE;
    super.display();
  }

  void trigger() {
    controller.zoomIn();
    super.trigger();
  }
}

class ZoomOut extends PPUIButton {
  float scale;
  ZoomOut(Controller c, String _name, String _text, PGraphics _icon, int _l, int _t, int _w, int _h) {
    super(c, _name, _text, _icon, _l, _t, _w, _h);
  }

  void display() {
    if (scale == 0.01) status = DISABLE;
    else status = IDLE;
    super.display();
  }

  void trigger() {
    controller.zoomOut();
    super.trigger();
  }
}

class PrevScene extends PPUIButton {
  PrevScene(Controller c, String _name, String _text, PGraphics _icon, int _l, int _t, int _w, int _h) {
    super(c, _name, _text, _icon, _l, _t, _w, _h);
  }

  void trigger() {
    controller.prevScene();
    super.trigger();
  }
}

class NextScene extends PPUIButton {
  NextScene(Controller c, String _name, String _text, PGraphics _icon, int _l, int _t, int _w, int _h) {
    super(c, _name, _text, _icon, _l, _t, _w, _h);
  }

  void trigger() {
    controller.nextScene();
    super.trigger();
  }
}

class AddAnimation extends PPUIButton {
  AddAnimation(Controller c, String _name, String _text, PGraphics _icon, int _l, int _t, int _w, int _h) {
    super(c, _name, _text, _icon, _l, _t, _w, _h);
  }

  void trigger() {
    controller.addAnimation();
    super.trigger();
  }
}
class NewScene extends PPUIButton {
  NewScene(Controller c, String _name, String _text, PGraphics _icon, int _l, int _t, int _w, int _h) {
    super(c, _name, _text, _icon, _l, _t, _w, _h);
  }

  void trigger() {
    controller.addScene();
    super.trigger();
  }
}

class DeleteScene extends PPUIButton {
  DeleteScene(Controller c, String _name, String _text, PGraphics _icon, int _l, int _t, int _w, int _h) {
    super(c, _name, _text, _icon, _l, _t, _w, _h);
  }

  void trigger() {
    if (status != DISABLE) {
      controller.removeScene();
      super.trigger();
    }
  }

  void display() {
    if (controller.selected_s == null) {
      status = DISABLE;
    } else {
      status = IDLE;
    }
    super.display();
  }
}

class NewResource extends PPUIButton {
  NewResource(Controller c, String _name, String _text, PGraphics _icon, int _l, int _t, int _w, int _h) {
    super(c, _name, _text, _icon, _l, _t, _w, _h);
  }

  void trigger() {
    controller.chooseResource();
    super.trigger();
  }
}

class DeleteResource extends PPUIButton {
  DeleteResource(Controller c, String _name, String _text, PGraphics _icon, int _l, int _t, int _w, int _h) {
    super(c, _name, _text, _icon, _l, _t, _w, _h);
  }

  void trigger() {
    if (status != DISABLE) {
      controller.removeResource();
      super.trigger();
    }
  }

  void display() {
    if (controller.selected_r == null) {
      status = DISABLE;
    } else {
      status = IDLE;
    }
    super.display();
  }
}
class EditSceneIcon extends PPUIButton {
  EditSceneIcon(Controller c, String _name, String _text, PGraphics _icon, int _l, int _t, int _w, int _h) {
    super(c, _name, _text, _icon, _l, _t, _w, _h);
  }

  void trigger() {
    if (status == DISABLE) return;
    if (status != DISABLE) {
      controller.editScene();
      super.trigger();
    }
  }

  void display() {
    if (controller.selected_s == null) {
      status = DISABLE;
    } else {
      status = IDLE;
    }
    super.display();
  }
}


class NewFile extends PPUIButton {
  NewFile(Controller c, String _name, String _text, PGraphics _icon, int _l, int _t, int _w, int _h) {
    super(c, _name, _text, _icon, _l, _t, _w, _h);
  }

  void trigger() {
    controller.newFile();
    super.trigger();
  }
}
class SaveFile extends PPUIButton {
  SaveFile(Controller c, String _name, String _text, PGraphics _icon, int _l, int _t, int _w, int _h) {
    super(c, _name, _text, _icon, _l, _t, _w, _h);
  }

  void trigger() {
    controller.saveToFile();
    super.trigger();
  }
}
class LoadFile extends PPUIButton {
  LoadFile(Controller c, String _name, String _text, PGraphics _icon, int _l, int _t, int _w, int _h) {
    super(c, _name, _text, _icon, _l, _t, _w, _h);
  }

  void trigger() {
    controller.loadFile();
    super.trigger();
  }
}
class SceneColor extends PPUIButton {
  SceneColor(Controller c, String _name, String _text, PGraphics _icon, int _l, int _t, int _w, int _h) {
    super(c, _name, _text, _icon, _l, _t, _w, _h);
  }

  void trigger() {
    controller.setSceneColor();
    super.trigger();
  }
}

class ColorButton extends PPUIButton {
  color _color;
  color _drag;
  ColorButton(Controller c, color clr, color drg, int _l, int _t) {
    super(c, "color", "", null, _l, _t, 10, 10);
    _color = clr;
    _drag = drg;
    PGraphics p = createGraphics(10, 10);
    p.beginDraw();
    p.noStroke();
    p.fill(_color);
    p.rect(0, 0, 10, 10);
    p.endDraw();
    icon = p;
  }
  void trigger() {
    if (status != INVISIBLE) {
      controller.setSceneColorTo(_color, _drag);
      super.trigger();
    }
  }
  void display(PGraphics canvas) {
    canvas.fill(_color);
    canvas.noStroke();
    canvas.rect(_left, _top, 10, 10);
  }
}

class Record extends PPUIButton {
  PPUIButton stop;
  Record(Controller c, String _name, String _text, PGraphics _icon, int _l, int _t, int _w, int _h) {
    super(c, _name, _text, _icon, _l, _t, _w, _h);
  }

  void trigger() {
    makeInvisible();
    stop.makeVisible();
    controller.record();
  }
}
class StopRecord extends PPUIButton {
  PPUIButton rec;
  StopRecord(Controller c, String _name, String _text, PGraphics _icon, int _l, int _t, int _w, int _h) {
    super(c, _name, _text, _icon, _l, _t, _w, _h);
  }

  void trigger() {
    makeInvisible();
    rec.makeVisible();
    controller.stopRecord();
  }
}

class KeyframeButton extends PPUIButton {
  PPAnimation parent;
  KeyframeButton(PPAnimation anim) {
    parent = anim;

    _width = 17;
    _height = 17;
    icon = createGraphics(20, 20);
    icon.beginDraw();
    icon.fill(255);
    icon.noStroke();
    icon.beginShape();
    icon.vertex(2, 10);
    icon.vertex(10, 2);
    icon.vertex(18, 10);
    icon.vertex(10, 18);
    icon.endShape();
    icon.endDraw();
    name = "keyframe";
    type = "button";
    status = CLICKED;
  }

  void trigger() {
    if (status == IDLE) {
      status = CLICKED;
      parent.inKeyFrameMode = true;
    } else if (status == CLICKED) {
      status = IDLE;
      parent.inKeyFrameMode = false;
    }
  }  

  boolean isInside(int x, int y) {
    if (status != INVISIBLE) { 
      if (x>_left && x<_left+_width &&
        y>_top && y<_top+_height) return true;
    }
    return false;
  } 

  void display(PGraphics canvas) {
    // making sure values are synced
    _left = parent._left + 10;
    _top = parent._top + track_h - 25;
    if (parent.inKeyFrameMode == true) status = CLICKED;
    else status = IDLE;

    canvas.stroke(0);
    canvas.fill(255);
    canvas.strokeWeight(2);
    canvas.rect(_left, _top, _width, _height, 5);
    if (status == IDLE) {
      canvas.tint(0);
      canvas.image(icon, _left+4, _top+4, 10, 10);
    } else if (status == CLICKED) {
      canvas.fill(0);
      canvas.rect(_left, _top, _width, _height, 5);
      canvas.tint(140, 140, 0);
      canvas.image(icon, _left+4, _top+4, 10, 10);
    }
  }
}

class DeleteInlineButton extends PPUIButton {
  PPData parent;
  PPData item;
  int top_offset;
  int left_offset;
  DeleteInlineButton(Controller c, PPData p, PPData _item, int xoffset, int yoffset) {
    parent = p;
    item = _item;
    controller = c;
    left_offset = xoffset;
    top_offset = yoffset;

    _width = 17;
    _height = 17;
    icon = createGraphics(20, 20);
    icon.beginDraw();
    icon.fill(255);
    icon.strokeWeight(1);
    icon.stroke(0);
    icon.line(2, 2, 18, 18);
    icon.line(2, 18, 18, 2);
    icon.endDraw();
    name = "delete";
    type = "inline button";
    status = IDLE;
  }

  void trigger() {
    parent.removeData(item);
  }  

  boolean isInside(int x, int y) {
    if (status != INVISIBLE) { 
      if (x>_left && x<_left+_width &&
        y>_top && y<_top+_height) return true;
    }
    return false;
  } 

  void display(PGraphics canvas) {
    // making sure values are synced
    _left = parent._left + left_offset;
    _top = parent._top + top_offset  ;

    canvas.stroke(0);
    canvas.fill(255);
    canvas.strokeWeight(2);
    canvas.rect(_left, _top, _width, _height, 5);
    canvas.image(icon, _left+4, _top+4, 10, 10);
  }
}

class EditInlineButton extends PPUIButton {
  PPData parent;
  PPData item;
  int top_offset;
  int left_offset;
  EditInlineButton(Controller c, PPData p, PPData _item, int xoffset, int yoffset) {
    parent = p;
    item = _item;
    controller = c;
    left_offset = xoffset;
    top_offset = yoffset;

    _width = 17;
    _height = 17;
    icon = createGraphics(20, 20);
    icon.beginDraw();
    icon.strokeWeight(4);
    icon.stroke(0);

    icon.line(6, 14, 18, 2);
    icon.noStroke();
    icon.fill(0);
    icon.triangle(1, 19, 3, 15, 5, 18);
    icon.endDraw();
    name = "edit";
    type = "inline button";
    status = IDLE;
  }

  void trigger() {
    controller.setResource(item.rep, true);
  }  

  boolean isInside(int x, int y) {
    if (status != INVISIBLE) { 
      if (x>_left && x<_left+_width &&
        y>_top && y<_top+_height) return true;
    }
    return false;
  } 

  void display(PGraphics canvas) {
    // making sure values are synced
    _left = parent._left + left_offset;
    _top = parent._top + top_offset  ;

    canvas.stroke(0);
    canvas.fill(255);
    canvas.strokeWeight(2);
    canvas.rect(_left, _top, _width, _height, 5);
    canvas.image(icon, _left+4, _top+4, 10, 10);
  }
}

class MuteButton extends PPUIButton {
  PPAudio parent;
  MuteButton(PPAudio audio) {
    parent = audio;

    _width = 17;
    _height = 17;
    icon = createGraphics(20, 20);
    icon.beginDraw();
    icon.fill(255);
    icon.noStroke();
    icon.beginShape();
    icon.vertex(2, 7);
    icon.vertex(8, 7);
    icon.vertex(14, 2);
    icon.vertex(14, 18);
    icon.vertex(8, 13);
    icon.vertex(2, 13);
    icon.vertex(2, 7);
    icon.endShape();
    icon.strokeWeight(1);
    icon.stroke(255);
    icon.line(14, 14, 20, 6);
    icon.line(20, 14, 14, 6);
    icon.endDraw();
    name = "mute";
    type = "button";
    status = CLICKED;
  }

  void trigger() {
    if (status == IDLE) {
      status = CLICKED;
      parent.isMuted = true;
    } else if (status == CLICKED) {
      status = IDLE;
      parent.isMuted = false;
    }
  }  

  boolean isInside(int x, int y) {
    if (status != INVISIBLE) { 
      if (x>_left && x<_left+_width &&
        y>_top && y<_top+_height) return true;
    }
    return false;
  } 

  void display(PGraphics canvas) {
    // making sure values are synced
    _left = parent._left + 10;
    _top = parent._top + track_h - 25;
    if (parent.isMuted == true) status = CLICKED;
    else status = IDLE;

    canvas.stroke(0);
    canvas.fill(255);
    canvas.strokeWeight(2);
    canvas.rect(_left, _top, _width, _height, 5);
    if (status == IDLE) {
      canvas.tint(0);
      canvas.image(icon, _left+4, _top+4, 10, 10);
    } else if (status == CLICKED) {
      canvas.fill(0);
      canvas.rect(_left, _top, _width, _height, 5);
      canvas.tint(140, 140, 0);
      canvas.image(icon, _left+4, _top+4, 10, 10);
    }
  }
}



class ResizeButton extends PPUIButton {

  ResizeButton(Controller c) {
    super(c, "resize", " ", null, width-50-10, 10, 50, 50);
    PGraphics p = createGraphics(40, 40);
    PImage img;
    if (fullScreen) {
      img = loadImage("smaller.png");
    } else {
      img = loadImage("bigger.png");
    }
    p.beginDraw();
    p.background(255);
    p.image(img, 5, 5, 30, 30);
    p.endDraw();
    icon = p;
  }

  void trigger() {
    fullScreen = !fullScreen;
    resize();
  }
}

