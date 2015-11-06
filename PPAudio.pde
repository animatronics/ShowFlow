///////////////////////////////////////////////////
// PPTrack class, 
// and its decendants: PPAudio, PPHeader, PPAnimation
// also has the PPKeyFrame class used by PPAnimation
// These are all possible tracks in the scene view.
///////////////////////////////////////////////////
class PPTrack extends PPData {
  PPScene parent;  
  int duration;  // length of file in milliseconds
  int _width;
  boolean onLabel = false;
  PPUIText rename;
  void deleteSelection() {
  }
  int getWidth() {
    return _width+text_label_w;
  }
  int getHeight() {
    return track_h;
  }
  void componentTriggered(PPUIComponent d) {
    if (d != null && d.name == "rename") {
      name = ((PPUIText)d).getText();
    }
  }
  boolean isInside(int x, int y) {
    if (x>_left && x<_left+getWidth()  && y>_top && y<_top + track_h) {
      if (x>_left && x<_left+text_label_w && y < _top + track_h/2 + 10 && y > _top + track_h/2 - 10) {
        onLabel = true;
      }
      return true;
    }
    return false;
  }
  void updateDuration(int d) {
  }
  void update(int x, int lastx, int y, int lasty) {
  }
}

////////////////////////////////////////////////
// PPAudio
///////////////////////////////////////////////
class PPAudio extends PPTrack {
  String file_name;  
  AudioSample sample;
  AudioPlayer file;

  PGraphics wave;
  boolean donePlaying = true;
  boolean isMuted = false;

  int start_pos = 0;

  int sel_pos1 = -1;
  int sel_pos2 = -1;

  Controller controller;

  PPAudio() {
  }

  PPAudio(Controller c, String _name, String _file_name, PPScene _parent) {
    name = _name;
    file_name = _file_name;
    parent = _parent;
    position = 0;
    scale = parent.scale;
    
    
    sample = minim.loadSample(file_name);
    file = minim.loadFile(file_name);
    duration = file.length();      
    
    
    _width = max(ceil(scale * duration), 20); 
    type = "audio";
    id = data_cnt.getCounter();
    status = IDLE;
    wave = drawWave(sample);
    // register with your parent
    parent.addData(this);
    MuteButton mute = new MuteButton(this);
    mute.fixed_position = false;
    associateComponent(mute);

    rename = new PPUIText(controller, "rename", _left, _top+track_h/2+5, text_label_w, 20, name);
    rename.restricted_length = 21;
    rename.expandWidth = true;
    rename.fixed_position = false;
    rename.parent = this;
    rename.makeInvisible();
    associateComponent(rename);
    
  }
  boolean isParent(PPData p) {
    if (parent == p) return true;
    return false;
  }
  JSONObject writeToJSON() {
    JSONObject audio = new JSONObject();
     audio.setString("type", type);
    audio.setString("name", name);
    audio.setInt("id", id);
    audio.setString("file_name", file_name);
    audio.setString("parent", parent.name);
    audio.setInt("parent id", parent.id);
    audio.setInt("start_pos", start_pos);
    return audio;
  }

  void readFromJSON(JSONObject jo) {
    id = jo.getInt("id");
    start_pos = jo.getInt("start_pos");
    updateRep();
  }
  PGraphics drawWave(AudioSample s) {
    // change to take only every 10 sample (or more)
    // draw the top and flip for the bottom
    float[] leftChannel = sample.getChannel(AudioSample.LEFT);
    int l = leftChannel.length;
    if (l==0) {
      PGraphics wave = createGraphics(10, track_h-2);
      println("shouldnt be here");
      wave.beginDraw();
      wave.background(0);
      wave.endDraw();
      return wave;
    }
    PGraphics wave = createGraphics(_width, track_h-2);
    PGraphics p = createGraphics(_width, track_h/2 - 2);
    p.beginDraw();
    // draw the wave in the color of the scene
    p.strokeWeight(1);
    p.stroke(parent.s_color);
    p.fill(parent.s_color);

    float unit = float(_width)/l;
    int skip = 10;
    p.beginShape();
    float m = max(leftChannel);
    for (int i = 0; i< l; i=i+skip) {
      float val = map(leftChannel[i], 0, m, 0, track_h/2 -2);
      p.vertex(i*unit, track_h/2 - val);
    }
    p.endShape();
    p.endDraw();
    wave.beginDraw();
    wave.image(p, 0, 2);
    wave.pushMatrix();
    wave.scale(1, -1);
    wave.image(p, 0, -track_h+2);
    wave.popMatrix();
    wave.endDraw();

    return wave;
  }

  void play() {
    if (position <= duration + start_pos && start_pos >= position) {
      file.cue(position-start_pos);
      if (isMuted) file.mute();
      else file.unmute();
      file.play();
      status = PLAYING;
    }
  }

  void pause() {
    file.pause();
  }
  int updatePosition(int p) {
    if (status == PREPLAY && p>= start_pos) {
      status = PLAYING;
      play();
    }
    else if (status == PLAYING) {
      if (position + p > duration+start_pos) {
        position = 0;
        donePlaying = true;
        status = IDLE;
      } else position+=p;
    }
    return position;
  }

  PGraphics getImage() {
    return wave;
  }
  void reDraw() {
    wave = drawWave(sample);
  }
  void updateWidth(int _w) {
    _width = _w;  
    wave = drawWave(sample);
  }
  void updateScale(float s) {
    float diff = s/scale;
    int new_w = int(_width*diff);
    scale = s;
    updateWidth(new_w);
  }

  void display(PGraphics canvas) {
    if (rename.status != SELECTED) rename.status = INVISIBLE;
    if (status == SELECTED && sel_pos1 == -1) { 
      sel_pos1 = 0;
      sel_pos2 = duration;
    }
    canvas.image(wave, _left+text_label_w, _top);
    canvas.noFill();
    canvas.stroke(210);
    canvas.strokeWeight(0.5);
    canvas.rect(_left, _top, getWidth(), track_h) ;
    canvas.fill(0);
    canvas.text(name, _left + 10, _top+track_h/2-10, text_label_w-10, track_h);
    if (sel_pos1 >= 0 && sel_pos2 >= 0) {
      int begin = min(sel_pos1, sel_pos2);
      int end = max(sel_pos1, sel_pos2);
      canvas.strokeWeight(2);
      canvas.fill(parent.s_color, 60);
      canvas.rect(text_label_w + begin*scale, _top, end*scale-begin*scale, track_h) ;
    }
  }
  void clearSelection() {
    sel_pos1 = -1;
    sel_pos2 = -1;
  }

  void update(int x, int lastx, int y, int lasty) {
    if (status == DRAGGED) {
      if (x<text_label_w) {
        return;
      }
      if (sel_pos1 == -1) {
        sel_pos1 = int(constrain((x-text_label_w)/scale, 0, duration));
      } else if (sel_pos2 == -1) {
        sel_pos2 = int(constrain((x-text_label_w)/scale, 0, duration));
      } else {
        sel_pos2 = int(constrain((x-text_label_w)/scale, 0, duration));
      }
    }
  }
}

////////////////////////////////////////////////
// PPRecording
// (doesn't work right now, should show something while recording)
///////////////////////////////////////////////
class PPRecording extends PPAudio {
  AudioInput in;
  PPRecording(Controller c, String _name, String _file_name, PPScene _parent, AudioInput _in) {
    name = _name;
    file_name = _file_name;
    parent = _parent;
    position = 0;
    scale = parent.scale;
    parent.addData(this);
    type = "recording";
    status = IDLE;
    _width = 10;
    duration = int(_width/scale);
    in = _in;
  }

  void display(PGraphics canvas) {
    canvas.noFill();
    canvas.stroke(210);
    canvas.strokeWeight(0.5);
    canvas.rect(_left, _top, getWidth(), track_h) ;
    canvas.fill(0);
    canvas.text(name, _left + 10, _top+track_h/2, text_label_w, track_h);
  } 
  void stopRecording() {
    parent.removeData(this);
  }
}

////////////////////////////////////////////////
// PPHeader
// This is the time ruler and marker at the top
///////////////////////////////////////////////
class PPHeader extends PPTrack {
  float scale;
  int _width;
  int _height;
  PGraphics ruler;
  PGraphics triangle;
  PGraphics line;
  PPHeader(int _w, int _h, PPScene _parent) {
    scale = 0.023;
    name = "header";
    parent = _parent;
    _width = _w;
    _height = _h;
    ruler = createGraphics(_width, 20);
    triangle = createGraphics(20, 20);
    line = createGraphics(5, _height);
    ruler.beginDraw();
    ruler.strokeWeight(2);
    ruler.line(0, 10, _width, 10);
    ruler.strokeWeight(1);
    float tick_space = scale*1000/2;
    int ticks = ceil(_width/tick_space);
    int duality = 0;
    for (int i = 0; i<ticks; i++) {
      if (duality == 0) {
        ruler.line(i*tick_space, 2, i*tick_space, 18);
        duality = 1;
      } else {
        ruler.line(i*tick_space, 7, i*tick_space, 13);
        duality = 0;
      }
    }
    ruler.endDraw();
    triangle.beginDraw();
    triangle.stroke(60);
    triangle.fill(220);
    triangle.triangle(0, 0, 10, 20, 20, 0);
    triangle.endDraw();
    line.beginDraw();
    line.strokeWeight(5);
    line.stroke(255, 0, 0, 180);
    line.line(0, 0, 0, _height);
    line.endDraw();
  }

  void updateScale(float s) {
    float diff = s/scale;
    int new_w = int(_width*diff);
    scale = s;
    updateWidth(new_w);
  }

  void updateWidth(int _w) {
    _width = _w;
    if (_width == 0) _width = 1;
    ruler = createGraphics(_width, 20);
    line = createGraphics(5, _height+20);
    ruler.beginDraw();
    ruler.strokeWeight(2);
    ruler.line(0, 10, _width, 10);
    ruler.strokeWeight(1);
    float tick_space = scale*1000/2;
    int ticks = ceil(_width/tick_space);
    int duality = 0;
    for (int i = 0; i<ticks; i++) {
      if (duality == 0) {
        ruler.line(i*tick_space, 2, i*tick_space, 18);
        duality = 1;
      } else {
        ruler.line(i*tick_space, 7, i*tick_space, 13);
        duality = 0;
      }
    }
    ruler.endDraw();
    line.beginDraw();
    line.strokeWeight(5);
    line.stroke(255, 0, 0, 180);
    line.line(0, 0, 0, _height+20);
    line.endDraw();
  }
  void updateHeight(int _h) {
    _height = _h;
    line = createGraphics(5, _height+20);
    line.beginDraw();
    line.strokeWeight(5);
    line.stroke(255, 0, 0, 180);
    line.line(0, 0, 0, _height+20);
    line.endDraw();
  }
  boolean isInside(int x, int y) {
    if (x > text_label_w-10 && x < text_label_w+_width+10 && y> _top && y<_top+20) return true;
    return false;
  } 
  int getWidth() {
    return _width;
  }
  int getHeight() {
    return _height;
  }
  int updatePosition(int p) {
    position+=p;
    return position;
  }
  void display(PGraphics canvas) {
    canvas.image(ruler, _left, _top);
    canvas.image(line, text_label_w+(position*scale)-1, _top);
    canvas.image(triangle, text_label_w+(position*scale)-10, _top);
  }
  void update(int x, int lastx, int y, int lasty) {
    if (status == DRAGGED || status == SELECTED) {
      int delta_x = x-lastx;
      //position = int(constrain( (x-text_label_w)/scale, 0, (_width-text_label_w)/scale));
      position = int(constrain( (x-text_label_w)/scale, 0, (_width)/scale));
      parent.setPosition(position);
    }
  }
}


////////////////////////////////////////////////
// PPKeyFrame
///////////////////////////////////////////////
// interpolations
static int LINEAR = 0;
static int CUBIC_EASE_IN = 1;
static int EXPO_EASE_IN = 2;
static int CUBIC_EASE_OUT = 3;
static int EXPO_EASE_OUT = 4;
static int CUBIC_EASE_IN_OUT = 5;
static int EXPO_EASE_IN_OUT = 6;
static int HOLD = 7;

class PPKeyFrame extends PPData {

  int interpolation = LINEAR;
  int x;
  int y;
  int prevX;
  int prevY;
  PPKeyFrame prev = null;
  PPKeyFrame next = null;
  PPScene scene = null;
  PPKeyFrame(int _x, int _y, PPKeyFrame _prev, PPKeyFrame _next, PPScene s) {
    x = _x;
    y = _y;
    prev = _prev;
    next = _next;
    scene = s;
    type = "keyframe";
    name = "keyframe";
    status = IDLE;
  }  

  JSONObject writeToJSON() {
    JSONObject keypoint = new JSONObject();
    keypoint.setInt("x", x);
    keypoint.setInt("y", y);
    return keypoint;
  }
  
  void display(PGraphics canvas) {
    if (status == IDLE) {
      canvas.fill(255);
      canvas.ellipse(x*scene.scale, y, 6, 6);
    } else if (status == SELECTED) {
      canvas.fill(scene.s_color);
      canvas.ellipse(x*scene.scale, y, 6, 6);
    }
  }
  boolean isInside(int x1, int y1) {
    int x2 = int(x*scene.scale + 3);
    int y2 = y + 3;
    if ( (x1 - x2)*(x1 - x2) + (y1 - y2)*(y1 - y2) < 25) {
      return true;
    }
    return false;
  }
}

////////////////////////////////////////////////
// PPAnimation
///////////////////////////////////////////////
class PPAnimation extends PPTrack {
  int min_range = 0;
  int max_range = 200;
  Actuator actuator;

  PGraphics wave;
  boolean donePlaying = true;

  int sel_pos1 = -1;
  int sel_pos2 = -1;  
  Controller controller;

  PPKeyFrame first = null;
  PPKeyFrame last = null;

  int[] actions = {
  };

  ArrayList<PPKeyFrame> keyPoints;
  boolean inKeyFrameMode = true;
  PPKeyFrame current_keyframe = null;

  PPAnimation(Controller c, String _name, PPScene _parent) {
    name = _name;
    parent = _parent;
    duration = parent.duration;  
    position = 0;
    scale = parent.scale;
    _width = ceil(scale * duration); 

    type = "animation";
    id = data_cnt.getCounter();
    status = IDLE;
    keyPoints = new ArrayList<PPKeyFrame>();
    first = new PPKeyFrame(0, (track_h -2)/2, null, null, parent);
    last = new PPKeyFrame(int(_width/scale), (track_h -2)/2, null, null, parent);
    first.next = last;
    last.prev = first;
    keyPoints.add(first);
    keyPoints.add(last);
    // some points to get us started...
    addKeyFrame(4565, 30);
    addKeyFrame(695, 70);
    addKeyFrame(3695, 64); 
    wave = drawWave();
    parent.addData(this);

    KeyframeButton kb = new KeyframeButton(this);
    kb.fixed_position = false;
    associateComponent(kb);
    rename = new PPUIText(controller, "rename", _left, _top+track_h/2+5, text_label_w, 20, name);
    rename.restricted_length = 21;
    rename.expandWidth = true;
    rename.fixed_position = false;
    rename.parent = this;
    rename.makeInvisible();
    associateComponent(rename);
  }
  boolean isParent(PPData p) {
    if (parent == p || actuator == p) return true;
    return false;
  }
  void addKeyFrame(int x, int y) {
    if (x < 0 || x > duration) return;
    // find location to insert the new keyframe
    for (int i = 0; i< keyPoints.size () - 1; i++) {
      PPKeyFrame kf = keyPoints.get(i);
      if (x > kf.x && x < kf.next.x) {  
        PPKeyFrame new_kf = new PPKeyFrame(int(x), y, kf, kf.next, parent);
        kf.next.prev = new_kf;
        kf.next = new_kf;
        keyPoints.add(i+1, new_kf);
        return;
      }
    }
  }

  void removeKeyFrame(PPKeyFrame kf) {
    int i = keyPoints.indexOf(kf);
    kf.prev.next = kf.next;
    kf.next.prev = kf.prev;
    keyPoints.remove(kf); 
    reDraw();
  }
  void setActuator(Actuator a) {
    actuator = a;
    min_range = actuator.min_range;
    max_range = actuator.max_range;
    drawWave();
  }
  JSONObject writeToJSON() {
    JSONObject anim = new JSONObject();
    anim.setString("type", type);
    anim.setString("name", name);
    anim.setInt("id", id);
    if (actuator!= null) anim.setString("actuator", actuator.name);
    else anim.setString("actuator", "");
    if (actuator!= null) anim.setInt("actuator id", actuator.id);
    else anim.setInt("actuator id", -1);
    anim.setFloat("scale", scale);
    anim.setString("parent", parent.name);
    anim.setInt("parent id", parent.id);

    JSONArray keyframes = new JSONArray();
    for (int i=0; i<keyPoints.size (); i++) {
      PPData d = keyPoints.get(i);
      JSONObject jo = d.writeToJSON();
      if (jo != null) keyframes.setJSONObject(i, jo);
    }  
    anim.setJSONArray("keyframes", keyframes);  
    return anim;
  }

  void readFromJSON(JSONObject jo) {
    id = jo.getInt("id");
    int actuator_id = jo.getInt("actuator id");
    if (actuator_id != -1) {
      actuator = (Actuator)getDataById(actuator_id);
    }
    scale = jo.getFloat("scale");
    JSONArray keyframes = jo.getJSONArray("keyframes");
    for (int i = keyPoints.size()-1; i>=0; i--) {
      keyPoints.remove(i);
    }

    JSONObject thefirst = keyframes.getJSONObject(0);
    JSONObject thelast = keyframes.getJSONObject(keyframes.size()-1);
    first = new PPKeyFrame(thefirst.getInt("x"), thefirst.getInt("y"), null, null, parent);
    last = new PPKeyFrame(thelast.getInt("x"), thelast.getInt("y"), null, null, parent);
    first.next = last;
    last.prev = first;
    keyPoints.add(first);
    keyPoints.add(last);
    for (int i = 1; i<keyframes.size()-1; i++){
      JSONObject keypoint = keyframes.getJSONObject(i);
      
      addKeyFrame(int(keypoint.getInt("x")), int(keypoint.getInt("y")));
    }
    
    wave = drawWave();
    updateRep();
  }
  PGraphics drawWave() {
    if (keyPoints.size()==2) {
      PGraphics wave = createGraphics(20, track_h-2);
      println("shouldnt be here");
      wave.beginDraw();
      wave.background(255);
      wave.endDraw();
      return wave;
    }
    PGraphics wave = createGraphics(_width, track_h-2);

    wave.beginDraw();
    wave.strokeWeight(1);
    wave.stroke(parent.s_color);
    wave.fill(parent.s_color, 70);
    wave.beginShape();
    wave.vertex(0, track_h-2);
    wave.vertex(keyPoints.get(0).x, keyPoints.get(0).y);
    for (int i = 1; i< keyPoints.size ()-1; i++) {
      PPKeyFrame kf = keyPoints.get(i);
      if (kf.interpolation == LINEAR) {
        wave.vertex(kf.x*scale, kf.y);
      }
    }
    wave.vertex(keyPoints.get(keyPoints.size()-1).x*scale, keyPoints.get(keyPoints.size()-1).y);
    wave.vertex(_width, track_h-2);
    wave.endShape();  

    wave.fill(255);
    wave.strokeWeight(2);
    for (int i = 0; i< keyPoints.size (); i++) {
      keyPoints.get(i).display(wave);
    }

    wave.endDraw();
    calcActions();
    return wave;
  }

  void calcActions() {
    if (actuator != null) {
      min_range = actuator.min_range;
      max_range = actuator.max_range;  
    } else {
      min_range = 0;
      max_range = 100;
    }
    updateDuration(parent.duration);
    int cnt = duration;
    actions = new int[cnt];
    PPKeyFrame kf1 = first;
    PPKeyFrame kf2 = first.next;
    int i = 0;
    int j = 0;
    float unit = float(_width)/cnt;
    while (kf2 != null) {
      i = kf1.x;
      j = kf2.x;
      for (; i<j; i++) {
        int y1 = abs( kf1.y - (track_h -2));
        int y2 = abs( kf2.y - (track_h -2));
        float val = (float(y2-y1)/float(kf2.x - kf1.x))*(i - float(kf1.x)) + y1;
        actions[i] = int(map(val, 0, track_h-2, min_range, max_range));
      }

      kf1 = kf2;
      kf2 = kf2.next;
    }
  }

  void play() {
    calcActions();
    if (position <= duration) {
      status = PLAYING;
      if (actuator != null) {
        int[] a_actions = new int[actions.length - position];
        arrayCopy(actions, position, a_actions, 0, actions.length - position);
        actuator.setActions(a_actions);
      } else {
        message("Cannot find actuator for animation.");
      }
    }
  }

  void pause() {
    status = IDLE;
    
    if (actuator != null) actuator.setActions(null);
  }
  int updatePosition(int p) {
    if (status == PLAYING) {
      if (position + p > duration) {
        position = 0;
        donePlaying = true;
        status = IDLE;
      } else position+=p;
    }
    return position;
  }

  boolean isInside(int x, int y) {
    if (current_keyframe != null) current_keyframe.status = IDLE;
    current_keyframe = null;
    for (int i = 0; i <keyPoints.size (); i++) {
      if (keyPoints.get(i).isInside(x - _left - text_label_w, y-_top)) {
        current_keyframe = keyPoints.get(i);
        current_keyframe.status = SELECTED;
        return true;
      }
    }
    return super.isInside(x, y);
  }
  void deleteSelection() {
    if (current_keyframe != null) {
      removeKeyFrame(current_keyframe);
    }
    
    if (sel_pos1 != -1 && sel_pos2 != -1) {
      for (int i = 0; i<keyPoints.size();i++) {
        if (keyPoints.get(i).x > sel_pos1 && keyPoints.get(i).x < sel_pos2 && keyPoints.get(i).prev != null && keyPoints.get(i).next != null) {
          removeKeyFrame(keyPoints.get(i));  
        }
      }
      clearSelection();  
    }
  }
  PGraphics getImage() {
    return wave;
  }
  void reDraw() {
    wave = drawWave();
  }
  void updateDuration(int d) {
    if (d > duration) {
    duration = d;
    _width = int(scale*duration);
    PPKeyFrame newlast = new PPKeyFrame(duration,track_h -2, null, null, parent);
    newlast.prev = last;
    last.next = newlast;
    keyPoints.add(newlast);
    last = newlast;
    } else {
      duration = d;
    _width = int(scale*duration);
      for (int i = 0; i<keyPoints.size();i++) {
        if (keyPoints.get(i).x > d && keyPoints.get(i).prev != null && keyPoints.get(i).next != null) {
          removeKeyFrame(keyPoints.get(i));
        }
      }
      last.x = duration;
    }
   
  }
  void updateWidth(int _w) {
    _width = _w;  
    wave = drawWave();
  }
  void updateScale(float s) {
    float diff = s/scale;
    int new_w = int(_width*diff);
    scale = s;
    updateWidth(new_w);
  }

  void display(PGraphics canvas) {
    if (isUpdated) {
      setActuator(actuator);
      isUpdated = false;
    }
    if (status == SELECTED && sel_pos1 == -1) { 
      sel_pos1 = 0;
      sel_pos2 = duration;
    }
    if (actuator == null || actuator.isConnected == false) {
      canvas.tint(0);
      canvas.fill(170);
      canvas.text("Not connected", _left+8, _top+20);
      
    }
    canvas.image(wave, _left+text_label_w, _top);
    canvas.tint(255);
    canvas.noFill();
    canvas.stroke(210);
    canvas.strokeWeight(0.5);
    canvas.rect(_left, _top, getWidth(), track_h) ;

    canvas.fill(0);
    canvas.text(name, _left + 10, _top+track_h/2-10, text_label_w-10, track_h);

    if (sel_pos1 >= 0 && sel_pos2 >= 0) {
      int begin = min(sel_pos1, sel_pos2);
      int end = max(sel_pos1, sel_pos2);
      canvas.strokeWeight(2);
      canvas.fill(parent.s_color, 60);
      canvas.rect(text_label_w + begin*scale, _top, end*scale-begin*scale, track_h) ;
    }
  }
  void clearSelection() {
    sel_pos1 = -1;
    sel_pos2 = -1;
  }
  void keyFrameAt(int _x, int _y) {
    if (inKeyFrameMode) {
      if (_y < _top || _y > _top+track_h) return;
      addKeyFrame(int((_x-_left-text_label_w)/scale), _y - _top);
      reDraw();
      status = IDLE;
    }
  }
  void update(int x, int lastx, int y, int lasty) {
    if (y -_top <=0 || y-_top >= track_h) return;
    if (current_keyframe != null && (current_keyframe.prev != null && current_keyframe.next != null)) {
      current_keyframe.x = int(constrain((x-text_label_w)/scale, 0, duration));
      current_keyframe.y = int(constrain(y-_top, 0, track_h)); 

      if (current_keyframe.x < current_keyframe.prev.x) { //switch their order
        int i = keyPoints.indexOf(current_keyframe.prev);
        PPKeyFrame tmp = current_keyframe.prev;
        current_keyframe.prev = tmp.prev;
        tmp.next = current_keyframe.next;
        tmp.prev.next = current_keyframe;
        tmp.prev = current_keyframe;
        current_keyframe.next.prev = tmp;
        current_keyframe.next = tmp;
        keyPoints.remove(current_keyframe);
        keyPoints.add(i, current_keyframe);
      }
      if (current_keyframe.x > current_keyframe.next.x) { //switch their order
        PPKeyFrame tmp = current_keyframe.next;
        int i = keyPoints.indexOf(current_keyframe);
        current_keyframe.next = tmp.next;
        tmp.prev = current_keyframe.prev;
        tmp.next.prev = current_keyframe;
        tmp.next = current_keyframe;
        current_keyframe.prev.next = tmp;
        current_keyframe.prev = tmp;
        keyPoints.remove(tmp);
        keyPoints.add(i, tmp);
      }
      reDraw();
      return;
    }

    if (status == DRAGGED) {
      if (x<text_label_w) {
        return;
      }
      if (sel_pos1 == -1) {
        sel_pos1 = int(constrain((x-text_label_w)/scale, 0, duration));
      } else if (sel_pos2 == -1) {
        sel_pos2 = int(constrain((x-text_label_w)/scale, 0, duration));
      } else {
        sel_pos2 = int(constrain((x-text_label_w)/scale, 0, duration));
      }
    }
  }
}

static class TrackCounter {
  static int count = 0;
  TrackCounter() {
  }
  int getCounter() {
    return ++count;
  }
}

