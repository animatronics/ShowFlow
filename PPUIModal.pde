//////////////////////////////////////////////////////////
// PPUIModal
// this class isn't used as much anymore
//////////////////////////////////////////////////////////
class PPUIModal  extends PPUICollection {

  PPTransition t_parent = null;
  PPScene s_parent = null;

  boolean isBlocking = true;
  int padding = 10;
  PPUIGraphics black_holder;
  PPUICanvas main;
  CloseButton cb;
  PPUIModal(Controller c, int rd_l, int rd_t, int rd_w, int rd_h, int cd_l, int cd_t, int cd_w, int cd_h ) {
    super(c, "modal", rd_l, rd_t, rd_w, rd_h);

    // black stripe and close button on the top
    main = new PPUICanvas(c, rd_l, rd_t+50, rd_w, rd_h-50, cd_l, cd_t+50, cd_w, cd_h-50 );
    super.addComponent(main);

    PGraphics black = createGraphics(rd_w, 50);
    black.beginDraw();
    black.fill(0);
    black.rect(0, 0, rd_w, 50);
    black.endDraw();
    black_holder = new PPUIGraphics(c, "banner", rd_l, rd_t, rd_w, 50, black);
    super.addComponent(black_holder);
    cb = new CloseButton(c, _left+padding, _top+padding);
    super.addComponent(cb);

    type = "modal";
  }
  void addComponent(PPUIComponent c) {
    if (main!= null) main.addComponent(c);
  }

  void updateDrawingAreas(int rd_l, int rd_t, int rd_w, int rd_h, int cd_l, int cd_t, int cd_w, int cd_h) {
    main.updateDrawingAreas( rd_l, rd_t, rd_w, rd_h, cd_l, cd_t, cd_w, cd_h );  
    if (black_holder != null) {
      if (black_holder._width != _width) {  
        PGraphics black = createGraphics(rd_w, 50);
        black.beginDraw();
        black.fill(0);
        black.rect(0, 0, rd_w, 50);
        black.endDraw();
        black_holder.image = black;
      }
      black_holder._left = _left;
      black_holder._top = _top;
      black_holder.moveOrigin(_left, _top);
      cb._left = _left + padding;
      cb._top = _top + padding;
    }
  }
  void setParent(PPTransition p) {
    t_parent = p;
  }
  void setParent(PPScene p) {
    s_parent = p;
  }
  void verticalScroll(float e) {
  }
  void dismiss() {
    status = INVISIBLE;
    deactivate();
  }

  PPUIComponent isInside(int x, int y, boolean propogate) {
    PPUIComponent c = super.isInside(x, y, true);
    if (c == main) {
      return main.isInsideComponent(x, y);
    }
    return c;
  }

  void update(int deltaX, int deltaY) {
    main.update(deltaX, deltaY);
  }

  void display() {
    if (status != INVISIBLE ) {
      fill(222, 100);
      rect(0, 0, width, height);
      fill(255);
      rect(_left, _top, _width, _height);
      super.display();
    }
  }
}

