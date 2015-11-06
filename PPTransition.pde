////////////////////////////////////////////////////////////
// PPTransition and PPStub are for connectinf scenes
// and describing the events that switch between them
////////////////////////////////////////////////////////////
class PPTransition extends PPData {
  PPScene source;
  PPScene destination;
  ArrayList<PPEvent> events;
  ArrayList<PPData> chosen_events;

  int destX, destY, srcX, srcY;
  int pre_destX, pre_destY, post_srcX, post_srcY;
  int extention = 30; 
  int padding = 10;

  int status;
  boolean flagOnRight = false;
  boolean flagOnLeft = false;
  int selectTolerance = 3;
  boolean and = true;
  boolean or = false;
  int src_loc = 0;
  int dest_loc = 0;

  PPUIModal mod = null; // this will be called to add events

  PPTransition() {
  }
  PPTransition(PPScene _s, PPScene _d) {
    this.source = _s;
    this.destination = _d;
    events = new ArrayList<PPEvent>();
    chosen_events =new ArrayList<PPData>();
    _s.registerTransaction(this, false);
    _d.registerTransaction(this, true);
    status = IDLE;
    type = "transition";
    id = data_cnt.getCounter();
    name=source.name+","+destination.name;
  }
  boolean isParent(PPData p) {
    if (source == p || destination == p) return true;
    if (chosen_events.indexOf(p) >= 0) return true;
    return false;
  }
  JSONObject writeToJSON() {
    JSONObject tran = new JSONObject();
    tran.setString("type", type);
    tran.setString("name", name);
    tran.setInt("id", id);
    tran.setString("source", source.name);
    tran.setInt("source id", source.id);
    tran.setString("destination", destination.name);
    tran.setInt("destination id", destination.id);
    JSONArray event_list = new JSONArray();
    for (int i=0; i<chosen_events.size (); i++) {
      PPData d = chosen_events.get(i);
      JSONObject jo = d.writeToJSON();
      if (jo != null) event_list.setJSONObject(i, jo);
    }  
    tran.setJSONArray("events", event_list);
    return tran;
  }

  void readFromJSON(JSONObject jo) {
    name = jo.getString("name");
    id = jo.getInt("id");
    int src = jo.getInt("source id");
    int dest = jo.getInt("destination id");
    PPScene s = (PPScene)getDataById(src);
    PPScene d = (PPScene)getDataById(dest);
    if (s == null) s=source;
    if (d== null) d=destination;
    changeConnection(s, d);

    JSONArray events = jo.getJSONArray("events");
    for (int i = 0; i<events.size (); i++) {
      JSONObject event = events.getJSONObject(i);
      int event_id = event.getInt("id");
      PPData ev = (Sensor)getDataById(event_id);
      if (ev!=null) addEvent(ev);
    }
    updateRep();
  }
  void changeConnection(PPScene _s, PPScene _d) {
    if (_s == source && _d == destination) {
      source.updateTransactions();
      destination.updateTransactions();
      return;
    }
    this.source.removeTransaction(this, false);
    this.source = _s;
    _s.registerTransaction(this, false);
    this.destination.removeTransaction(this, true);
    this.destination = _d;
    _d.registerTransaction(this, true);
    name=source.name+","+destination.name;
  }

  // used by scenes when they calculate where to position transitions
  void setSourceXY(int _x, int _y) {
    this.srcX = _x;
    this.srcY = _y;
    this.post_srcX = _x+extention+src_loc*5;
    this.post_srcY = _y;
  }

  void setDestinationXY(int _x, int _y) {
    this.destX = _x;
    this.destY = _y;
    this.pre_destX = _x-extention-dest_loc*5;
    this.pre_destY = _y;
  }

  // returns the middle point of the incline
  PVector middle() {
    int x, y;
    if (this.source == this.destination) {
      y = destination.top + destination.s_height + 10;
      x = abs((post_srcX+pre_destX)/2);
    } else {
      x = abs((post_srcX+pre_destX)/2);
      y = abs((post_srcY+pre_destY)/2);
    }
    return new PVector(x, y);
  }

  // This hit function checks for several cases
  // If we hit next to the source line, it raises the left flag
  // If we hit next to the destination line, it raises the right flag
  // It checks the case of the transition with same src and dest (rectangle shape)
  // And it checks for a hit on the incline
  boolean isInside(int x, int y) {
    flagOnRight = false;
    flagOnLeft = false;
    if (y > srcY - selectTolerance && y < srcY+selectTolerance && x > srcX && x < srcX+extention+src_loc*5) {
      flagOnLeft = true;
      return true;
    }
    if (y > destY - selectTolerance && y < destY+selectTolerance && x < destX && x > destX-extention-dest_loc*5) {
      flagOnRight = true;
      return true;
    }

    if (this.source == this.destination) {
      int bm = destination.top + destination.s_height + 10 + dest_loc*5;
      if (isBetween(x, post_srcX - selectTolerance, post_srcX+selectTolerance) && isBetween(y, post_srcY, bm)) return true;
      if (isBetween(y, bm - selectTolerance, bm+selectTolerance) && isBetween(x, post_srcX, pre_destX)) return true;
      if (isBetween(x, pre_destX - selectTolerance, pre_destX+selectTolerance) && isBetween(y, pre_destX, bm)) return true;
    }

    // checking if we are on the slanted part
    int x1, x2, y1, y2;
    float dx, dy, dl, t, dist, nearestX, nearestY;
    x1 = srcX+extention+src_loc*5;
    y1 = srcY;
    x2 = destX-extention-dest_loc*5;
    y2 = destY;
    if (!isBetween(x, x1, x2) || !isBetween(y, y1, y2)) return false; // x, y not even in correct rect
    dx = x1-x2;
    dy = y1-y2;
    if (dx == 0 && dy == 0) return false; // same points
    dl = dx*dx + dy*dy;
    t = ((x - x1)*dx + (y - y1)*dy)/dl;

    nearestX = x1 + t*dx;
    nearestY = y1 + t*dy;

    dist = dist(nearestX, nearestY, x, y);
    if (dist <= selectTolerance) {
      return true;
    }

    // no hit
    return false;
  }
  boolean isBetween(int a, int x1, int x2) {
    if (x1 > x2) return (a <= x1 && a >= x2);
    else return (a >= x1 && a <= x2);
  }

  // This is called when a transition line is dragged
  void update (int delta_x, int delta_y) {
    if (status == DRAGGED) {
      if (this.flagOnLeft) {
        setSourceXY(this.srcX+delta_x, this.srcY+delta_y);
      } else if (this.flagOnRight) {
        setDestinationXY(this.destX+delta_x, this.destY+delta_y);
      }
      // dragging on middle section has no effect
    }
  }

  void setStatus(int s) {
    status = s;
  } 
  int status() {
    return status;
  }

  void updateEventsLocation() {
    PVector m = middle();
    int x = int(m.x + 5);
    int y = int(m.y + 5);
    for (int i = 0; i<chosen_events.size (); i++) {
      chosen_events.get(i)._left = x;
      chosen_events.get(i)._top = y;
      x+=32;
    }
  }

  void display(PGraphics p) {
    if (chosen_events.size() > 0) {
      updateEventsLocation();
      for (int i = 0; i<chosen_events.size (); i++) {
        Sensor s = (Sensor)chosen_events.get(i);
        p.strokeWeight(1);
        p.stroke(0);
        p.fill(255);
        p.rect(s._left, s._top, 30, 30, 5);
        p.image(s.icon, s._left, s._top);
      }
    }

    p.strokeWeight(3);
    color line_color;
    if (this.destination != null) {
      line_color = this.destination.s_color;
    } else { 
      line_color = color(120);
    } 

    if (status == SELECTED || status == DRAGGED) {
      // make a shadowed version of the line slightly moved down
      color shadowed = color(0);
      p.stroke(shadowed);
      p.line(srcX, srcY+1, post_srcX, post_srcY+1);
      if (this.source == this.destination) {
        int bm = destination.top + destination.s_height + 10+dest_loc*5;
        p.line(post_srcX, post_srcY+1, post_srcX, bm+1);
        p.line(post_srcX, bm+1, pre_destX, bm+1);
        p.line(pre_destX, pre_destY+1, pre_destX, bm+1);
      } else {
        p.line(post_srcX, post_srcY+1, pre_destX, pre_destY+1);
      }
      p.line(pre_destX, pre_destY+1, destX-10, destY+1);
      p.fill(shadowed);
      p.noStroke();
      p.triangle(destX-10, destY-4, destX-10, destY+6, destX, destY+1);
      p.ellipse(srcX, srcY+1, 8, 8);
    }
    if (chosen_events.size() == 0) {
      p.stroke(120);
    } else {
      p.stroke(line_color);
    }
    p.line(srcX, srcY, post_srcX, post_srcY);
    if (this.source == this.destination) {
      int bm = destination.top + destination.s_height + 10 + dest_loc*5;
      p.line(post_srcX, post_srcY, post_srcX, bm);
      p.line(post_srcX, bm, pre_destX, bm);
      p.line(pre_destX, pre_destY, pre_destX, bm);
    } else {
      p.line(post_srcX, post_srcY, pre_destX, pre_destY);
    }

    p.line(pre_destX, pre_destY, destX-10, destY);
    if (chosen_events.size() == 0) { 
      p.fill(120);
    } else {  
      p.fill(line_color);
    }
    p.noStroke();
    p.triangle(destX-10, destY-5, destX-10, destY+5, destX, destY);
    p.ellipse(srcX, srcY, 8, 8);
  }

  void addEvent(PPData event) {
    chosen_events.add(event);
  }
  void removeEvent(PPData event) {
    chosen_events.remove(event);
  }
  void openModal() {
    mod.makeVisible();
  }

  void activateSensors() {
    for (int i = 0; i<chosen_events.size (); i++) {
      ((Sensor)chosen_events.get(i)).activateSensor();
    }
  }
  boolean anyEvents() {
    if  (chosen_events.size() == 0) return false;
    return true;
  }
  boolean isTriggered() {
    if (and) {  
      for (int i = 0; i<chosen_events.size (); i++) {
        if (chosen_events.get(i).status != SELECTED) return false;
      }
      return true;
    } else {
      for (int i = 0; i<chosen_events.size (); i++) {
        if (chosen_events.get(i).status == SELECTED) return true;
      } 
      return false;
    }
  }
  PPUIModal setModal(int _left, int _top, int _width, int _height, ArrayList<PPEvent> events, Controller c) {
    // we use padding to space elements, and we assume standard button size is 50 (close button is the execption
    int button_s = 50;

    PFont font = createFont("Arial", 20);  
    textFont(font);
    String str = source.name + " -> "+destination.name;
    int tw = int(textWidth(str));
    _width = max(tw+2*padding, 250);
    int p_height = (button_s + 25) + events.size()*padding + events.size()*button_s + padding + 30 + padding+30+padding;
    if (_height < p_height) _height = p_height;
    // check if we need to raise the window
    if (_height + _top + 2*padding > height) _top = height - _height - 2*padding;
    if (_width + _left + 2*padding > width) _left = width - _width - 2*padding;

    mod = new PPUIModal(c, _left, _top, _width, _height, _left, _top, _width, _height);
    int max_label = 0;
    if (events != null) {
      int num = events.size();
      int offset = button_s + 25;    

      // create buttons and labels based on events and position them 
      for (int i = 0; i < events.size (); i++) {
        PPEvent e = events.get(i);
        EventButton b = new EventButton(c, e, padding, offset+padding); 
        mod.addComponent(b);
        offset = offset + padding+ button_s;

        PFont font14 = createFont("Arial", 14);  

        PPUILabel l = new PPUILabel(c, e.name, e.name+" Event", null, b._left+padding+button_s, b._top, 100+padding, button_s);
        l.font = font14;
        l.alignment = A_LEFT;
        mod.addComponent(l);
      }
    }
    mod.updateDrawingAreas(_left, _top, _width, _height, _left, _top, _width, _height);

    PPUILabel title = new PPUILabel(c, "Title", str, null, 0, button_s, _width, 25);
    title.font = font;

    mod.addComponent(title);

    InsertScene insert = new InsertScene(c, "Insert", "+ Insert Scene", null, padding, _height-80, _width-2*padding, 30);
    mod.addComponent(insert);

    RemoveTrans remove = new RemoveTrans(c, "Remove", "- Remove Link", null, padding, _height-40, _width-2*padding, 30);
    mod.addComponent(remove);

    mod.setParent(this);
    mod.makeVisible();
    return mod;
  }
}

///////////////////////////////////////////////////////
// PPTransitionStub
// part of every PPScene, used to create new transitions
///////////////////////////////////////////////////////

class PPTransitionStub extends PPTransition {
  boolean isMoved = false;
  PPTransitionStub(PPScene _s) {
    this.source = _s;
    this.destination = _s;
    events = new ArrayList<PPEvent>();
    chosen_events =new ArrayList<PPData>();
    status = IDLE;
    type = "stub";
    name=source.name+" stub";
  }


  boolean isInside(int x, int y) {
    flagOnRight = false;
    flagOnLeft = false;
    if (y > srcY - selectTolerance && y < srcY+selectTolerance && x > srcX && x < srcX+extention-5) {
      flagOnRight = true;
      return true;
    }
    if (y > destY - selectTolerance && y < destY+selectTolerance && x < destX && x > destX-extention+5) {
      flagOnLeft = true;
      return true;
    }
    return false;
  }

  void update (int x, int y) {
    if (status == DRAGGED) {
      isMoved = true;
      if (this.flagOnLeft) {
        setSourceXY(x, y);
      } else if (this.flagOnRight) {
        setDestinationXY(x, y);
      }
      // dragging on middle section has no effect
    }
  }
  void display(PGraphics p) {
    p.strokeWeight(3);
    color line_color;
    if (this.destination != null) {
      line_color = this.destination.s_color;
    } else { 
      line_color = color(120);
    } 
    if (status == SELECTED) {
      color shadowed = color(0);
      p.stroke(shadowed);
      p.line(srcX, srcY+1, post_srcX-8, post_srcY+1);
      p.line(pre_destX+8, pre_destY+1, destX-10, destY+1);
      p.fill(shadowed);
      p.noStroke();
      p.triangle(destX-10, destY-5+1, destX-10, destY+5+1, destX, destY+1);
      p.ellipse(srcX, srcY+1, 8, 8);  
      p.triangle(post_srcX-8-10, post_srcY-5+1, post_srcX-8-10, post_srcY+5+1, post_srcX-8, post_srcY+1);
      p.ellipse(pre_destX+8, pre_destY+1, 8, 8);
    }
    if (status == IDLE || status == SELECTED) {
      p.stroke(line_color);
      p.line(srcX, srcY, post_srcX-8, post_srcY);
      p.line(pre_destX+8, pre_destY, destX-10, destY);
      p.fill(line_color);
      p.noStroke();
      p.triangle(destX-10, destY-5, destX-10, destY+5, destX, destY);
      p.ellipse(srcX, srcY, 8, 8);  
      p.triangle(post_srcX-8-10, post_srcY-5, post_srcX-8-10, post_srcY+5, post_srcX-8, post_srcY);
      p.ellipse(pre_destX+8, pre_destY, 8, 8);
      return;
    }
    if (status == DRAGGED && isMoved) {
      color shadowed = color(0);
      p.stroke(shadowed);
      p.line(srcX, srcY+1, post_srcX, post_srcY+1);
      p.line(post_srcX, post_srcY+1, pre_destX, pre_destY+1);
      p.line(pre_destX, pre_destY+1, destX-10, destY+1);
      p.fill(shadowed);
      p.noStroke();
      p.triangle(destX-10, destY-4, destX-10, destY+6, destX, destY+1);
      p.ellipse(srcX, srcY+1, 8, 8);

      p.stroke(line_color);
      p.line(srcX, srcY, post_srcX, post_srcY);
      p.line(post_srcX, post_srcY, pre_destX, pre_destY);
      p.line(pre_destX, pre_destY, destX-10, destY);
      p.fill(line_color);
      p.noStroke();
      p.triangle(destX-10, destY-5, destX-10, destY+5, destX, destY);
      p.ellipse(srcX, srcY, 8, 8);
    }
  }

  void changeConnection(PPScene _s, PPScene _d) {
    if (_s != _d) return; // this shouldn't happen
    this.source.removeTransaction(this, false);
    this.source = _s;
    _s.registerTransaction(this, false);
    this.destination.removeTransaction(this, true);
    this.destination = _d;
    _d.registerTransaction(this, true);
    _s.updateTransactions();
  }
}

// this function is not used anymore
void dashedLine(PGraphics canvas, int x1, int y1, int x2, int y2, int interval) {
  float D = dist(x1, y1, x2, y2);
  float x3;
  float y3;
  while ( D > 0) {
    x3 = (interval*(x2-x1))/D + x1;
    y3 = (interval*(y2-y1))/D + y1;
    canvas.line(x1, y1, x3, y3);
    D = D-interval;
    x1 = int((interval*(x2-x3))/D + x3);
    y1 = int((interval*(y2-y3))/D + y3);
    D = D-interval;
  }
}

