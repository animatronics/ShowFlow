//////////////////////////////////////////////////////////
// PPUIComponent is the base for the UI components
//
// this file also contain other basic classed such as
// collection, canvas, and scrollers
//////////////////////////////////////////////////////////

class PPUIComponent {
  int _top, _left, _width, _height;
  Controller controller;
  int status;
  String name;
  String type;
  boolean fixed_position = true;
  boolean canResize = false;
  boolean isUpdated = false;
  int offsetBy = 0;
  PPData parent = null;

  PPUIComponent() {
  }
  PPUIComponent(Controller c, String n, int left, int top, int c_width, int c_height) {
    controller = c;
    name = n;
    status = INVISIBLE;
    _left = left;
    _top = top;
    _width = c_width;
    _height = c_height; 
    type = "component";
  }

  boolean isInside(int x, int y) {
    if (status != INVISIBLE) { 
      if (x>_left && x<_left+_width &&
        y>_top && y<_top+_height) return true;
    }
    return false;
  }

  PPUIComponent isInside(int x, int y, boolean propogate) {
    if (isInside(x, y)) return this;
    return null;
  }

  void display() {
  }
  void display(PGraphics canvas) {
  } 
  void display(int x, int y) {
  }

  void activate() {
  }
  void deactivate() {
  }

  void update() {
  }

  void setStatus(int s) {
    status = s;
  }
  int status() {
    return status;
  }

  void makeVisible() {
    setStatus(IDLE);
  }
  void makeInvisible() {
    setStatus(INVISIBLE);
    if (this.name != "hscroll" && this.name != "vscroll") {
    }
  }
}

//////////////////////////////////////////////////////////
// PPUIGraphics
//////////////////////////////////////////////////////////
class PPUIGraphics extends PPUIComponent {
  PGraphics image;
  int startX, startY;
  PPUIGraphics(Controller c, String n, int left, int top, int c_width, int c_height, PGraphics img) {
    super(c, n, left, top, c_width, c_height);
    image = img;
    startX = 0;
    startY = 0;
    type = "graphics";
  }
  void update(int w, int h, PGraphics img) {
    _width = w;
    _height = h; 
    image = img;
  } 
  void setGraphics(PGraphics g) {
    image = g;
  }
  void moveOrigin(int x, int y) {
    startX = x;
    startY = y;
  }
  void display() {
    if (status != INVISIBLE) {
      if (image != null) image(image, startX, startY);
    }
  }
  void display(PGraphics canvas) {
    if (status != INVISIBLE) {
      if (image != null) canvas.image(image, startX, startY);
    }
  }
}

//////////////////////////////////////////////////////////
// PPUICollection
//////////////////////////////////////////////////////////
class PPUICollection extends PPUIComponent {
  ArrayList<PPUIComponent> components;
  PPUICollection(Controller c, String n, int left, int top, int c_width, int c_height) {
    super(c, n, left, top, c_width, c_height);
    components = new ArrayList<PPUIComponent>();
    type = "collection";
  }
  void addComponent(PPUIComponent c) {
    if (components.indexOf(c) < 0) components.add(c);
  }
  void removeComponent(PPUIComponent c) {
    int i = components.indexOf(c);
    if (i>=0) components.remove(i);
  }

  void removeAllComponents() {
    for (int i = components.size ()-1; i>=0; i--) {
      components.remove(i);
    }
  }
  void bringToFront(PPUIComponent c) {
    removeComponent(c);
    addComponent(c);
  }
  PPUIComponent isInside(int x, int y, boolean propogate) {

    if (propogate) {
      // looking from the elements that are more forward to the back
      for (int i = components.size () - 1; i >= 0; i--) {
        PPUIComponent c = components.get(i);
        c = c.isInside(x, y, true);
        if (c != null) return c;
      }
    }
    if (this.isInside(x, y)) return this;
    return null;
  }

  void display() {
    if (status != INVISIBLE) {
      for (int i = 0; i < components.size (); i++) {
        PPUIComponent c = components.get(i);
        c.display();
      }
    }
  }

  void display(PGraphics canvas) {
    if (status != INVISIBLE) {
      for (int i = 0; i < components.size (); i++) {
        PPUIComponent c = components.get(i);
        c.display(canvas);
      }
    }
  }
  void makeVisible() {
    setStatus(IDLE);
    for (int i = 0; i < components.size (); i++) {
      PPUIComponent c = components.get(i);
      c.makeVisible();
    }
  }
  void makeInvisible() {
    setStatus(INVISIBLE);
    for (int i = 0; i < components.size (); i++) {
      PPUIComponent c = components.get(i);
      c.makeInvisible();
    }
  }
}

//////////////////////////////////////////////////////////
// PPUICanvas
//////////////////////////////////////////////////////////
class PPUICanvas extends PPUICollection {
  // The real display area is denoted with rd
  // The complete display area is denoted cd
  int rd_left, rd_top, rd_width, rd_height;
  int cd_left, cd_top, cd_width, cd_height;
  VScroll vs;
  HScroll hs;
  boolean disableVerticalScroll = false;
  boolean disableHorizontalScroll = false;
  PPUIGraphics canvas;
  PGraphics graphics;
  ArrayList<PPData> data = null;

  PPUICanvas(Controller c, int rd_l, int rd_t, int rd_w, int rd_h, int cd_l, int cd_t, int cd_w, int cd_h ) {
    super(c, "canvas container", rd_l, rd_t, rd_w, rd_h);
    graphics = createGraphics(cd_w, cd_h);
    graphics.beginDraw();
    graphics.background(255);
    graphics.endDraw();
    canvas = new PPUIGraphics(c, "canvas", cd_l, cd_t, cd_w, cd_h, graphics);

    vs = new VScroll(c, rd_l, rd_t, rd_w, rd_h, cd_l, cd_t, cd_w, cd_h );
    hs = new HScroll(c, rd_l, rd_t, rd_w, rd_h, cd_l, cd_t, cd_w, cd_h );
    updateDrawingAreas( rd_l, rd_t, rd_w, rd_h, cd_l, cd_t, cd_w, cd_h );

    addComponent(vs);
    addComponent(hs);
    type = "canvas";
  }
  void setData(ArrayList<PPData> d) {
    data = d;
  }
  void makeVisible() {
    canvas.setStatus(IDLE);
    super.makeVisible();
  }
  void makeInvisible() {
    canvas.setStatus(INVISIBLE);
    super.makeInvisible();
  }
  void removeAllComponents() {
    super.removeAllComponents();
    addComponent(vs);
    addComponent(hs);
  }

  void updateDrawingArea(int cd_w, int cd_h) {
    updateDrawingAreas(rd_left, rd_top, rd_width, rd_height, cd_left, cd_top, cd_w, cd_h);
  }
  void updateDrawingAreas(int rd_l, int rd_t, int rd_w, int rd_h, int cd_l, int cd_t, int cd_w, int cd_h) {
    rd_left = rd_l;
    rd_top = rd_t;
    rd_width = rd_w; 
    rd_height = rd_h;
    cd_left = cd_l;
    cd_top = cd_t;
    cd_width = cd_w;
    cd_height = cd_h;

    _left = rd_l;
    _top = rd_t;
    _width = rd_w;
    _height = rd_h;

    // Update VScroll and update HScroll
    vs.updateDrawingAreas(this);

    if (vs.status == INVISIBLE) {
      hs.updateDrawingAreas(this);
    } else {
      hs.updateDrawingAreas(rd_l, rd_t, rd_w-10, rd_h, cd_l, cd_t, cd_w, cd_h );
    }
  }
  void display() {
    if (status != INVISIBLE) {
      graphics = createGraphics(cd_width, cd_height);

      graphics.beginDraw();
      graphics.background(255);
      if (data != null) {

        for (int i = 0; i < data.size (); i++) {
          PPData d = data.get(i);
          d.display(graphics);
        }
      }

      for (int i=0; i<components.size (); i++) {
        components.get(i).display(graphics);
      }
      graphics.endDraw();

      canvas.setGraphics(graphics);
      if (vs.status == INVISIBLE && hs.status == INVISIBLE) {
        vs.position = 0; 
        hs.position=0;
      }
      PImage temp = canvas.image.get(int(hs.position*hs.ratio), int(vs.position*vs.ratio), rd_width, rd_height);
      image(temp, _left, _top);
      if (!disableVerticalScroll) {
        vs.display();
      }
      if (!disableHorizontalScroll) {
        hs.display();
      }
    }
  }

  int getEffectiveLeft() {
    return int(_left - hs.position*hs.ratio);
  }
  int getEffectiveTop() {
    return int(_top - vs.position*vs.ratio);
  }
  void update(int deltaX, int deltaY) {
    vs.update(deltaX, deltaY);
    hs.update(deltaX, deltaY);
  }
  void scrollToShow(int x, int y) {
    vs.scrollToShow(x, y);
    hs.scrollToShow(x, y);
  }
  void verticalScroll(float e) {
    if (vs.status != INVISIBLE) {
      vs.update(0, int(e));
    }
  }

  PPUIComponent isInsideComponent(int x, int y) {
    // offsetting the top of the canvas
     return super.isInside(x-getEffectiveLeft(), y-getEffectiveTop(), true);
  }

  PPUIComponent isInside(int x, int y, boolean propogate) {  
    if (propogate) {
      // looking from the elements that are more forward to the back
      for (int i = components.size () - 1; i >= 0; i--) {
        PPUIComponent c = components.get(i);

        if (!c.fixed_position) {
          c = c.isInside(x-getEffectiveLeft(), y-getEffectiveTop(), true);
        } else {
          c = c.isInside(x, y, true);
        }
        if (c != null) return c;
      }
    }
    if (this.isInside(x, y)) return this;
    return null;
  }
  PPData isInsideData(int x, int y) {
    PPData d;
    if (data != null) {
      for (int i = 0; i < data.size (); i++) {
        d = data.get(i);
        if (d.isInside(int(x-getEffectiveLeft()), int(y-getEffectiveTop()))) {
          return d;
        }
      }
    }
    return null;
  }
}

//////////////////////////////////////////////////////////
// VScroll
//////////////////////////////////////////////////////////
class VScroll extends PPUIComponent {
  float len = 0;
  float position = 0;
  // The real display area is denoted with rd
  // The complete display area is denoted cd
  int rd_left, rd_top, rd_width, rd_height;
  int cd_left, cd_top, cd_width, cd_height;
  float ratio=0;

  PGraphics scroller;

  VScroll(Controller c, int rd_l, int rd_t, int rd_w, int rd_h, int cd_l, int cd_t, int cd_w, int cd_h ) {
    super(c, "vscroll", rd_l+rd_w-10, rd_t, 10, rd_h);
    if (rd_h >0) scroller = createGraphics( 10, rd_h);
    type = "scroller";
  }
  void updateDrawingAreas(PPUICanvas c) {
    updateDrawingAreas(c.rd_left, c.rd_top, c.rd_width, c.rd_height, c.cd_left, c.cd_top, c.cd_width, c.cd_height );
  }
  void updateDrawingAreas(int rd_l, int rd_t, int rd_w, int rd_h, int cd_l, int cd_t, int cd_w, int cd_h) {
    rd_left = rd_l;
    rd_top = rd_t;
    rd_width = rd_w; 
    rd_height = rd_h;
    cd_left = cd_l;
    cd_top = cd_t;
    cd_width = cd_w;
    cd_height = cd_h;

    _left = rd_l+rd_w-10;
    _top = rd_t;
    _height = rd_h;
    if (rd_h > 0) scroller = createGraphics( 10, rd_h);
    ratio = float(cd_h)/float(rd_h);
    len = float(rd_h)/ratio;
    if (len > rd_h) len = rd_h;
    if (rd_h == cd_h || len >= rd_h) {
      makeInvisible();
    } else if (status == INVISIBLE) {
      makeVisible();
    }
  }

  void display() {    
    if (rd_height == cd_height || len >= rd_height) {
      makeInvisible();
    } else if (status == INVISIBLE) {
      makeVisible();
    }
    if (status != INVISIBLE && scroller!=null) {
      scroller.beginDraw();
      scroller.background(0, 0);
      scroller.fill(155, 70);
      scroller.rect(0, 0, _width, _height);
      scroller.fill(155, 70, 80, 200);
      scroller.rect(0, position, _width, len, 5);
      scroller.endDraw();
      image(scroller, _left, _top);
    }
  }  
  void activate() {
    status = IDLE;
  }
  void update(int delta_x, int delta_y) {
    if (status == DRAGGED) {
      position = int(constrain(position + delta_y, 0, _height-len));
    }
  }
  void scrollToShow(int x, int y) {
    if (y> position+len || y<position) {
      position = int(constrain(y, 0, _height-len));
    }
  }
}

//////////////////////////////////////////////////////////
// HScroll
//////////////////////////////////////////////////////////
class HScroll extends PPUIComponent {
  float len = 0;
  float position = 0;
  // The real display area is denoted with rd
  // The complete display area is denoted cd
  int rd_left, rd_top, rd_width, rd_height;
  int cd_left, cd_top, cd_width, cd_height;
  float ratio=0;

  PGraphics scroller;

  HScroll(Controller c, int rd_l, int rd_t, int rd_w, int rd_h, int cd_l, int cd_t, int cd_w, int cd_h ) {
    super(c, "hscroll", rd_l, rd_t+rd_h-10, rd_w, 10);
    if (rd_w - 10 > 0) scroller = createGraphics( rd_w, 10);
    type = "scroller";
  }
  void updateDrawingAreas(PPUICanvas c) {
    updateDrawingAreas(c.rd_left, c.rd_top, c.rd_width, c.rd_height, c.cd_left, c.cd_top, c.cd_width, c.cd_height );
  }
  void updateDrawingAreas(int rd_l, int rd_t, int rd_w, int rd_h, int cd_l, int cd_t, int cd_w, int cd_h) {
    rd_left = rd_l;
    rd_top = rd_t;
    rd_width = rd_w; 
    rd_height = rd_h;
    cd_left = cd_l;
    cd_top = cd_t;
    cd_width = cd_w;
    cd_height = cd_h;

    _left = rd_l;
    _top = rd_t+rd_h-10;
    _width = rd_w;
    if (rd_w-10>0) scroller = createGraphics( rd_w, 10);
    ratio = float(cd_w)/float(rd_w);
    len = float(rd_w)/ratio;
    if (len > rd_w) len = rd_w;
    if (len >= rd_w) makeInvisible();
    else if (status == INVISIBLE) makeVisible();
  }
  void activate() {
    status = IDLE;
  }
  void display() {    
    if (len >= rd_width) makeInvisible();
    else if (status == INVISIBLE) makeVisible();
    if (status != INVISIBLE && scroller != null) {
      scroller.beginDraw();
      scroller.background(0, 0);
      scroller.fill(155, 70);
      scroller.rect(0, 0, _width, _height);
      scroller.fill(155, 70, 80, 200);
      scroller.rect(position, 0, len, _height, 5);
      scroller.endDraw();
      image(scroller, _left, _top);
    }
  }  

  void update(int delta_x, int delta_y) {
    if (status == DRAGGED) {    
      position = int(constrain(position + delta_x, 0, _width-len));
    }
  }

  void scrollToShow(int x, int y) {
    if (x> position+len || x<position) {
      position = int(constrain(x, 0, _width-len));
    }
  }
}

