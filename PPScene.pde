/////////////////////////////////////////////////////////
// PPData and PPScene
//
// PPData is the root for all data related classes
////////////////////////////////////////////////////////

class PPData {
  int id = -1;
  String type="";
  String name="";
  int _top;
  int _left;
  int position;
  boolean isUpdated = false;
  boolean isDone = false;
  int status;
  float scale;
  ArrayList<PPUIComponent> associated_components = new ArrayList<PPUIComponent>();
  Representation rep;
  PPData() {
  }
  void display() {
  }
  void display(PGraphics c) {
  }
  boolean isInside(int x, int y) {
    return false;
  }
  ArrayList<PPUIComponent> associateComponent(PPUIComponent c) {
    if (associated_components.indexOf(c) < 0) associated_components.add(c);
    return associated_components;
  }
  ArrayList<PPUIComponent> associateComponents(ArrayList<PPUIComponent> list) {
    for (int i = 0; i<list.size (); i++) 
      associateComponent(list.get(i));
    return associated_components;
  }
  ArrayList<PPUIComponent> unassociateComponent(PPUIComponent c) {
    if (associated_components.indexOf(c) >= 0) associated_components.remove(c);
    return associated_components;
  }
  ArrayList<PPUIComponent> unassociateComponents(ArrayList<PPUIComponent> list) {
    for (int i = 0; i<list.size (); i++) 
      unassociateComponent(list.get(i));
    return associated_components;
  }

  PGraphics getImage() {
    return null;
  }
  int getWidth() {
    return 0;
  }
  int getHeight() {
    return 0;
  }
  void play() {
  }
  void pause() {
  }
  int updatePosition(int p) {
    return position;
  }
  void updateScale(float s) {
  }
  void reDraw() {
  }
  void clearSelection() {
  }
  String writeToString() {
    return "";
  }
  JSONObject writeToJSON() { 
    return null;
  }
  void readFromJSON(JSONObject jo) {
  }
  PPData readFromString() {
    return null;
  }
  void componentTriggered(PPUIComponent c) {
  }
  void updateRep() {
    if (rep != null) rep.updateControlls();
  }
  //void dataUpdated(PPData d) {}
  boolean isChild(PPData child) {
    return false;
  }
  boolean isParent(PPData child) {
    return false;
  }
  void removeData(PPData d) {
  }
  void editData(PPData d) {
  }
}

/////////////////////////////////////////////////////////
// PPScene
////////////////////////////////////////////////////////

class PPScene extends PPData { 
  String text = "";
  int top;
  int left;
  int s_width = 220;
  int s_height = 100;
  color s_color;
  color drag_color;
  int padding = 10;

  boolean isStart = true;
  boolean isEnd = true;
  boolean nameEdit = false;
  boolean isModifyable = true;
  boolean isUpdated = false;
  PPUIModal mod;
  ArrayList<PPData> outgoing;
  ArrayList<PPData> incoming;

  ArrayList<PPData> scene_data;
  int audio_cnt = 0;
  int animation_cnt = 0;

  int data_width = 0;
  int duration = 0;

  IntDict interactions = new IntDict();

  PPHeader header;
  PPTransitionStub stub;

  PPUIText scene_name;
  PPUIText text_box;
  PImage animwave = loadImage("animwave.png");
  PImage audiowave = loadImage("audiowave.png");

  PPScene(String _name, int _left, int _top) {
    this.name = _name;
    this.top = _top;
    this.left = _left;
    s_color = color(random(255), random(255), random(255));
    float H = hue(s_color);
    float S = saturation(s_color);
    colorMode(HSB);
    drag_color=color(H, S, 70, 255);
    colorMode(RGB);
    scale = 0.023;
    outgoing = new ArrayList<PPData>();  
    incoming = new ArrayList<PPData>();
    scene_data = new ArrayList<PPData>();
    header = new PPHeader(int(1000*scale), 20, this);
    header._top = 0;
    header._left = text_label_w;
    scene_data.add(header);
    status = IDLE;
    stub = new PPTransitionStub(this);

    incoming.add(stub);
    outgoing.add(stub);
    updateTransactions();

    type= "scene";
    id = data_cnt.getCounter();

    scene_name = new PPUIText(controller, "scene name", 0, 0, 100, 35, name, 20);
    scene_name.restricted_length = 11;
    scene_name.expandWidth = true;
    scene_name.parent = this;
    text_box = new PPUIText(controller, "text", 0, 0, 100, height, text);
    text_box.parent = this;
    associateComponent(scene_name);
    associateComponent(text_box);
  }
  PPScene(SceneCounter count, int _left, int _top) {
    this.name = "scene"+count.getCounter();
    this.top = _top;
    this.left = _left;
    s_color = color(random(255), random(255), random(255));
    float H = hue(s_color);
    float S = saturation(s_color);
    colorMode(HSB);
    drag_color=color(H, S, 70, 255);
    colorMode(RGB);
    scale = 0.023;
    outgoing = new ArrayList<PPData>();
    incoming = new ArrayList<PPData>();
    scene_data = new ArrayList<PPData>();
    header = new PPHeader(int(1000*scale), 20, this);
    header._top = 0;
    header._left = text_label_w;
    scene_data.add(header);
    stub = new PPTransitionStub(this);

    incoming.add(stub);
    outgoing.add(stub);
    updateTransactions();

    type="scene";
    id = data_cnt.getCounter();

    scene_name = new PPUIText(controller, "scene name", 0, 0, 100, 35, name, 20);
    scene_name.restricted_length = 11;
    scene_name.expandWidth = true;
    scene_name.parent = this;
    text_box = new PPUIText(controller, "text", 0, 0, 100, height, text);
    text_box.parent = this;
    associateComponent(scene_name);
    associateComponent(text_box);
  }

  void componentTriggered(PPUIComponent c) {
    if (c != null && c.name == "scene name") {
      name = ((PPUIText)c).getText();
    }
    if (c != null && c.name == "text") {
      text = ((PPUIText)c).getText();
    }
  }

  boolean isChild(PPData child) {
    if (scene_data.indexOf(child) >=0 ) {
      return true;
    }
    if (incoming.indexOf(child) >=0 ) {
      return true;
    }
    if (outgoing.indexOf(child) >=0 ) {
      return true;
    }
    return false;
  }
  PPData getSceneDataById(int _id) {
    for (int i=0; i<scene_data.size (); i++) {
      if (scene_data.get(i).id == _id) return scene_data.get(i);
    }
    return null;
  }
  void setColor(color clr, color drag) {
    s_color = clr;
    drag_color = drag;
    for (int i = 0; i<scene_data.size (); i++) {
      PPData d = scene_data.get(i);
      if (d.name != "header") {
        d.reDraw();
      }
    }
  }

  JSONObject writeToJSON() {
    JSONObject scene = new JSONObject();
    scene.setString("type", type);
    scene.setString("name", name);
    scene.setString("text", text);
    scene.setInt("id", id);
    scene.setInt("top", top);
    scene.setInt("left", left);
    scene.setInt("position", position);
    scene.setFloat("scale", scale);
    scene.setFloat("R", red(s_color));
    scene.setFloat("G", green(s_color));
    scene.setFloat("B", blue(s_color));
    scene.setInt("audio_cnt", audio_cnt);
    scene.setInt("animation_cnt", animation_cnt);
    scene.setInt("data_width", data_width);
    JSONArray tracks = new JSONArray();
    for (int i=0; i<scene_data.size (); i++) {
      PPData d = scene_data.get(i);
      JSONObject jo = d.writeToJSON();
      if (jo != null) tracks.setJSONObject(i, jo);
    }  
    scene.setJSONArray("scene_data", tracks);
    JSONArray var_ints = new JSONArray();
    int i=0;
    syncInteractions();
    for (String k : interactions.keys ()) {
      JSONObject jo = new JSONObject();
      jo.setString("key", k);
      jo.setInt("interaction", interactions.get(k));
      if (jo != null) var_ints.setJSONObject(i++, jo);
    }
    scene.setJSONArray("interactions", var_ints);
    return scene;
  }

  void readFromJSON(JSONObject jo) {
    id = jo.getInt("id");
    text = jo.getString("text");
    text_box.setText(text);
    name = jo.getString("name");
    scene_name.setText(name);
    top = jo.getInt("top");
    left = jo.getInt("left");
    position = jo.getInt("position");
    scale = jo.getFloat("scale");
    int d_width = jo.getInt("data_width");

    duration = int(d_width/scale);
    // read and make tracks
    JSONArray data = jo.getJSONArray("scene_data");
    for (int i = 0; i < data.size (); i++) {
      JSONObject track = data.getJSONObject(i);
      String type = track.getString("type");
      if (type.equals("audio")) {  
        PPAudio a = creator.createAudio(controller, track.getString("name"), track.getString("file_name"), this);
        a.readFromJSON(track);
      } else if (type.equals("animation")) {
        PPAnimation a = creator.createAnimation(controller, track.getString("name"), this);
        a.updateDuration(duration);
        a.readFromJSON(track);
      }
    }
    syncInteractions();
    JSONArray var_interactions = jo.getJSONArray("interactions");
    for (int i = 0; i < var_interactions.size (); i++) {
      JSONObject var_int = var_interactions.getJSONObject(i);
      interactions.set(var_int.getString("key"), var_int.getInt("interaction"));
    }
    int r = jo.getInt("R");
    int g = jo.getInt("G");
    int b = jo.getInt("B");
    s_color = color(r, g, b);
    float H = hue(s_color);
    float S = saturation(s_color);
    colorMode(HSB);
    drag_color=color(H, S, 70, 255);
    colorMode(RGB);
    setScale(scale);
    isUpdated = true;
    updateRep();
  }
  // will make interactions large enough to match the current vars 
  // or smaller if vars were erased
  void syncInteractions() {
    for (int i=0; i< vars.size (); i++) {
      if (interactions.hasKey(str(vars.get(i).id))) {
      } else {
        interactions.set(str(vars.get(i).id), 0);
      }
    }
    if (interactions.size()>vars.size()) {
      for (String k : interactions.keys ()) {  
        if (getDataById(int(k)) == null) interactions.remove(k);
      }
      isUpdated = true;
    }
  }

  void setInteraction(PPUIList list, int var_id) {
    list.selected = interactions.get(str(var_id));
  }
  void copyInteraction(PPUIList list, int var_id) {
    interactions.set(str(var_id), list.selected);
  }
  String getName() {
    return this.name;
  }
  void setName(String _name) {
    this.name = _name;
  }
  void setStart(boolean _s) {
    isStart = _s;
  }
  void setEnd(boolean _e) {
    isEnd = _e;
  }
  void addData(PPData d) {
    scene_data.add(d);
    if (d.type == "audio") audio_cnt++;
    if (d.type == "animation") animation_cnt++;
    data_width = max(data_width, ((PPTrack)d)._width);
    duration = int(data_width/scale);
    for (int i=0; i<scene_data.size (); i++) {
      ((PPTrack)scene_data.get(i)).updateDuration(duration);
      ((PPTrack)scene_data.get(i)).reDraw();
    }
    int h = header.getHeight()+d.getHeight();
    header.updateWidth(data_width);
    header.updateHeight(h);
    scene_data.remove(header);
    scene_data.add(header);
    isUpdated = true;
  }
  void removeData(PPData d) {
    int i = scene_data.indexOf(d);
    int h = max(header.getHeight(), header.getHeight() - d.getHeight());
    scene_data.remove(i); 
    if (d.type == "audio") audio_cnt--;
    if (d.type == "animation") animation_cnt--;
    int w = 0;
    for (int j = 0; j<scene_data.size (); j++) {
      PPData tmp = scene_data.get(j);
      if (tmp.type == "audio") { 
        w = max(w, ((PPTrack)tmp)._width);
      }
    }
    data_width = w;
    duration = int(data_width/scale);
    for (int j=0; j<scene_data.size (); j++) {
      if (scene_data.get(j).type == "animation") {
        ((PPTrack)scene_data.get(j)).updateDuration(duration);
        ((PPTrack)scene_data.get(j)).reDraw();
      }
    }
    header.updateWidth(w);
    header.updateHeight(h);
    isUpdated = true;
  }
  ArrayList<PPData> getData() {
    return scene_data;
  }
  ArrayList<PPData> getDataList() {
    ArrayList<PPData> list = new ArrayList<PPData>();
    for (int i = 0; i<scene_data.size (); i++) {
      if (scene_data.get(i).name != "header") list.add(scene_data.get(i));
    }
    return list;
  }
  ArrayList<PPData> getOutgoingList() {
    ArrayList<PPData> list = new ArrayList<PPData>();
    for (int i = 0; i<outgoing.size (); i++) {
      if (outgoing.get(i).type != "stub") list.add(outgoing.get(i));
    }
    return list;
  }
  ArrayList<PPData> getIncomingList() {
    ArrayList<PPData> list = new ArrayList<PPData>();
    for (int i = 0; i<incoming.size (); i++) {
      if (incoming.get(i).type != "stub") list.add(incoming.get(i));
    }
    return list;
  }
  int getBottom() {
    return this.top+s_height;
  }
  int getRight() {
    return this.left+s_width;
  }
  String getText() {
    return this.text;
  }
  void setText(String _text) {
    this.text = _text;
  }

  void registerTransaction(PPTransition _trans, boolean in) {
    isStart = true;
    isEnd = true;

    if (in) {
      incoming.add(0, _trans);
    } else {
      outgoing.add(0, _trans);
    }
    updateTransactions();
    if (incoming.size() > 1) isStart = false;
    if (outgoing.size() > 1) isEnd = false;
  }

  void updateTransactions() {
    // set destination coordinates for all incoming edges
    if (incoming.size() > 0) {
      int step = (this.s_height-20)/incoming.size();
      for (int i = 0; i < incoming.size (); i++) {
        PPTransition tran = (PPTransition)incoming.get(i);
        tran.dest_loc = i;
        tran.setDestinationXY(this.left, int(this.top+this.s_height/2 +ceil(float(i)/2)*pow(-1, i)*step));
      }
    }
    // set source coordinates for all outgoing edges
    if (outgoing.size() > 0) {
      int step = (this.s_height-20)/outgoing.size();
      for (int i = 0; i < outgoing.size (); i++) {
        PPTransition tran = (PPTransition)outgoing.get(i);
        tran.src_loc = i;
        tran.setSourceXY(this.left+this.s_width, int(this.top+this.s_height/2 +ceil(float(i)/2)*pow(-1, i)*step));
      }
    }
  }
  ArrayList<PPData> allTransactions() {
    ArrayList<PPData> all = new ArrayList<PPData>();
    all.addAll(incoming);
    all.addAll(outgoing);
    return all;
  }
  void removeTransaction(PPTransition _trans, boolean in) {
    if (in) {
      int i = incoming.indexOf(_trans);
      if (i>=0) incoming.remove(i);
    } else {
      int i = outgoing.indexOf(_trans);
      if (i>=0) outgoing.remove(i);
    }
    isStart = true;
    isEnd = true;
    if (incoming.size() > 1) isStart = false;
    if (outgoing.size() > 1) isEnd = false;
  }

  boolean isInside(int x, int y) {
    if (x>this.left && x<this.left+this.s_width &&
      y>this.top && y<this.top+this.s_height) {
      return true;
    }
    return false;
  }

  void setStatus(int s) {
    status = s;
  } 
  int status() {
    return status;
  }

  // called when the scene is dragged 
  void update(int delta_x, int delta_y) {
    // if dragged - then change location
    if (status == DRAGGED) {
      if (top + delta_y > 1) this.top += delta_y;
      if (left + delta_x > 1) this.left += delta_x;
      updateTransactions();
    }
  }

  void play() {
    status = PLAYING;
    isDone = false;
    interact();
    for (int i=0; i< scene_data.size (); i++) {
      scene_data.get(i).play();
    }
  }

  void pause() {
    status = IDLE;
    for (int i=0; i< scene_data.size (); i++) {
      scene_data.get(i).pause();
    }
  }

  // position is on the timeline of the scene
  int updatePosition(int diff) {
    int done = 0;
    for (int i = 0; i<scene_data.size (); i++) {
      PPData d = scene_data.get(i);
      int p = d.updatePosition(diff);
      if (d != header) {
        done += p;
      }
    }
    if (done == 0) {
      header.position = 0;
      isDone = true;
      status = IDLE;

      return 0;
    }
    if (position + diff > duration) {
      position = 0;
    } else position+=diff;
    return diff;
  }
  void interact() {
    for (String k : interactions.keys ()) {
      Variable v = (Variable)getDataById(int(k));
      if (v != null) v.interact(interactions.get(k));
    }
  }
  void activateSensors() {
    for (int i = 0; i<outgoing.size (); i++) {
      if (outgoing.get(i).type != "stub") ((PPTransition)outgoing.get(i)).activateSensors();
    }
  }
  void setPosition(int p) {
    position = p;
    for (int i = 0; i<scene_data.size (); i++) {
      PPData d = scene_data.get(i);
      d.position = p;
    }
  }

  void setScale(float s) {
    scale = s;
    for (int i = 0; i<scene_data.size (); i++) {
      PPData d = scene_data.get(i);
      d.updateScale(s);
    }
  }

  PPData isInsideData(int x, int y) {
    for (int i = 0; i<scene_data.size (); i++) {
      PPData d = scene_data.get(i);
      if (d.isInside(x, y)) return d;
    }
    return null;
  }
  void display(PGraphics p) {
    if (p == null) return;

    if (isStart) {
      p.noStroke();
      p.fill(0);
      p.arc(left+10 + s_height/4, top, s_height/2, s_height/2, -PI, 0);
      p.fill(255);
      p.textSize(16);
      p.text("S", left + 5  + s_height/4, top-2);
    }
    if (isEnd) {
      p.noStroke();
      p.fill(0);
      p.arc(left+ +s_width - 10 - s_height/4, top + s_height, s_height/2, s_height/2, 0, PI);
      p.fill(255);
      p.textSize(16);
      p.text("E", left+ +s_width - 15 - s_height/4, top + s_height + s_height/4 -4);
    }
    p.fill(255);
    p.strokeWeight(2);
    p.stroke(this.s_color);
    p.rect(this.left, this.top, s_width, s_height, 10);
    if (text.length() == 0) p.stroke(170);
    //p.rect(left+s_width-30, top+10, 15, 20);
    p.beginShape();
    p.vertex(left+s_width-30, top+10);
    p.vertex(left+s_width-30+15, top+10);
    p.vertex(left+s_width-30+15, top+10+15);
    p.vertex(left+s_width-30+10, top+10+20);
    p.vertex(left+s_width-30+10, top+10+15);
    p.vertex(left+s_width-30+15, top+10+15);
    p.vertex(left+s_width-30+10, top+10+15);
    p.vertex(left+s_width-30+10, top+10+20);
    p.vertex(left+s_width-30, top+10+20);
    p.vertex(left+s_width-30, top+10);
    p.endShape();
    p.strokeWeight(0.5);
    if (text.length() != 0) {
      p.line(left+s_width-30+2, top+10+4, left+s_width-30+2+10, top+10+4);
      p.line(left+s_width-30+2, top+10+7, left+s_width-30+2+10, top+10+7);
      p.line(left+s_width-30+2, top+10+10, left+s_width-30+2+10, top+10+10);
      p.line(left+s_width-30+2, top+10+13, left+s_width-30+2+10, top+10+13);
      p.line(left+s_width-30+2, top+10+16, left+s_width-30+2+10, top+10+16);
    }
    if (audio_cnt == 0) {
      p.stroke(170); 
      p.tint(170);
    } else {
      p.stroke(s_color); 
      p.tint(s_color);
    }
    p.rect(left+10, top+10+30, s_width-50, 20);
    p.image(audiowave, left+10, top+10+30, s_width-50, 20);
    if (animation_cnt == 0) {
      p.stroke(170); 
      p.tint(170);
    } else {
      p.stroke(s_color); 
      p.tint(s_color);
    }
    p.rect(left+10, top+10+60, s_width-50, 20);
    p.image(animwave, left+10, top+10+60+2, s_width-50, 20);

    p.noStroke();
    if (audio_cnt == 0) {
      p.fill(170);
    } else p.fill(s_color);
    p.rect(left+s_width-30, top+10+30, 15, 20, 5);
    if (animation_cnt == 0) {
      p.fill(170);
    } else p.fill(s_color);
    p.rect(left+s_width-30, top+10+60, 15, 20, 5);
    p.fill(255);
    p.textSize(10);
    p.text("x"+audio_cnt, left+s_width-30+1, top+10+30+13);
    p.text("x"+animation_cnt, left+s_width-30+1, top+10+60+13);

    if (status == DRAGGED || status == SELECTED) {
      p.fill(this.s_color, 40); 
      p.rect(this.left, this.top, s_width, s_height, 10);
    }
    if (status == PLAYING && duration != 0) {
      p.fill(this.s_color, 70); 
      float ratio = float(position)/float(duration);
      int played = int(s_width*ratio); 
      p.rect(this.left, this.top, played, s_height, 10, 0, 0, 10);
    }

    if (status == DRAGGED || status == SELECTED) {
      p.fill(drag_color);
    } else {
      p.fill(this.s_color, 255);
    }

    p.textSize(22);
    p.text( this.name, this.left+10, this.top+10, s_width-30, s_height-30);
  }

// The next two modals are not used anymore
  PPUIModal setModal1(int _left, int _top, int _width, int _height, Controller c) {
    // we use padding to space elements, and we assume standard button size is 50 (close button is the execption

    int button_s = 50;
    _width = 250; // default size, unless name is long
    PFont font = createFont("Arial", 20);  
    textFont(font);
    String str = name;
    int tw = int(textWidth(str));
    if (_width < tw+2*padding) _width = tw+2*padding;
    if (_height < button_s + 25 + 30 + 30 + 30 + padding*3) _height = button_s + 25 + 30 + 30 + 30 + padding*3;
    if (_height + _top + 2*padding > height) _top = height - _height - 2*padding;
    if (_width + _left + 2*padding > width) _left = width - _width - 2*padding;

    mod = new PPUIModal(c, _left, _top, _width, _height, _left, _top, _width, _height);

    PPUILabel title = new PPUILabel(c, "Title", str, null, 0, button_s, _width, 25);
    title.font = font;
    mod.addComponent(title);

    InsertTrans insert = new InsertTrans(c, "Insert", "+ Insert Link", null, padding, button_s + 25, _width-2*padding, 30);
    insert.modalDim(_left, _top, _width, _height);
    mod.addComponent(insert);

    RemoveScene remove = new RemoveScene(c, "Remove", "- Remove Scene", null, padding, button_s + 25 + 30 + padding, _width-2*padding, 30);  
    mod.addComponent(remove);

    EditScene edit = new EditScene(c, "Edit", " Edit Scene ", null, padding, button_s + 25 + 30 + 30 + padding*2, _width-2*padding, 30);  
    mod.addComponent(edit);

    mod.updateDrawingAreas(_left, _top, _width, _height, _left, _top, _width, _height);

    mod.setParent(this);
    mod.makeVisible();
    return mod;
  }

  PPUIModal setModal2(int _left, int _top, int _width, int _height, ArrayList<PPScene> scenes, Controller c) {
    // we use padding to space elements, and we assume standard button size is 50 (close button is the execption

    int button_s = 50;
    PFont font = createFont("Arial", 20);  
    textFont(font);
    String str = "Link to";
    int tw = int(textWidth(str));

    int cd_h = _height;
    int cd_w = _width-padding;

    mod = new PPUIModal(c, _left, _top, _width, _height, _left, _top, _width, _height);

    PPUILabel title = new PPUILabel(c, "Title", str, null, 0, button_s, _width, 25);
    title.font = font;
    mod.addComponent(title);

    int offset = button_s + 25+padding;
    for (int i=0; i<scenes.size (); i++) {
      PPScene s = scenes.get(i);

      TransitionToButton tb = new TransitionToButton(c, "Transition to", s.name, null, padding, offset, _width-3*padding, 30, s, this);
      mod.addComponent(tb);
      offset += 30+padding;
    }

    cd_h = offset;

    mod.updateDrawingAreas(_left, _top, _width, _height, _left, _top, cd_w, cd_h);   
    mod.setParent(this);
    mod.makeVisible();
    return mod;
  }
}


// Utility class, to make an automatic default names for new scenes
static class SceneCounter {
  static int count = 0;
  static int max_width = 0;
  static int max_text = 0;
  SceneCounter() {
  }
  int getCounter() {
    return ++count;
  }
  int getMaxWidth() {
    return max_width;
  }
  void calcMaxWidth(ArrayList<PPScene> scenes) {
    max_width = 0;
    for (int i = 0; i<scenes.size (); i++) {
      max_width = max(max_width, scenes.get(i).data_width);
    }
  } 
  int getMaxText() {
    return max_width;
  }
  void calcMaxText(ArrayList<PPScene> scenes) {
    max_text = 0;
    for (int i = 0; i<scenes.size (); i++) {
      max_text = max(max_text, scenes.get(i).text.length());
    }
  }
}

static class DataCounter {
  static int count = 0;
  DataCounter() {
  }
  int getCounter() {
    return ++count;
  }
}

