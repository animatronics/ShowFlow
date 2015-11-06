//////////////////////////////////////////////////////////
// PPUIText
// class for text areas
// this class is still very buggy
//////////////////////////////////////////////////////////

final String endOfText = "\u0003";

class PPUIText extends PPUICanvas {
  String text = "";
  PFont font;
  int padding = 5;
  boolean isInFocus = false; // Should just be SELECTED
  boolean multiline = false;
  boolean isDisabled = false;
  int restricted_length = -1;   // if this is more than -1, only that number of characters are allowed
  int font_size;
  int cursor_pos = 0; // in characters
  float leading = 1.5;
  ArrayList<PPData> lines;
  int current_line;

  boolean isHighlighted = false;
  int s_highlight = -1;
  int e_highlight = -1;

  int blinker_count = 0;
  int blinker_direction = 1;

  boolean expandWidth = false;
  boolean isNumerical = false;

  PPUIText(Controller c, String _n, int _l, int _t, int _w, int _h, String txt) {
    super(c, _l, _t, _w, _h, _l, _t, _w-10, _h);
    name = _n;
    font = createFont("Arial", 13);
    textFont(font);
    font_size = 13;
    type = "text";
    setText(txt);
    for (int i = 0; i<lines.size (); i++) {
      PPLine l = (PPLine)lines.get(i);
    }
    setData(lines);

    cursor_pos = text.length();
  } 
  PPUIText(Controller c, String _n, int _l, int _t, int _w, int _h, String txt, int _font_size) {
    super(c, _l, _t, _w, _h, _l, _t, _w-10, _h);
    name = _n;
    font = createFont("Arial", _font_size);
    textFont(font);
    font_size = _font_size;
    type = "text";
    setText(txt);
    setData(lines);

    cursor_pos = text.length();
  }   

  PPUIText(Controller c, String _n, int _l, int _t, int _w, int _h, String txt, PFont _font, int _font_size) {
    super(c, _l, _t, _w, _h, _l, _t, _w-10, _h);
    name = _n;
    font = _font;
    font_size = _font_size;
    type = "text";
    setText(txt);
    setData(lines);
    cursor_pos = text.length();
  }   
  void makeInvisible() {
    outOfFocus();
    super.makeInvisible();
  }
  void outOfFocus() {
    if (parent != null) {
      parent.componentTriggered(this);
    }
  }
  String getText() {
    return text.replaceAll(endOfText, "");
  }

  void setText(StringList new_lines) {
    if (new_lines.size() == 0) {
      setText(""); 
      return;
    }
    lines = new ArrayList<PPData>();
    int line_width = 10;
    textFont(font);
    textLeading(leading*font_size);
    int index = 0;
    ;
    int l_width =0;
    for (int i = 0; i<new_lines.size (); i++) {
      l_width = int(textWidth(new_lines.get(i)));
      line_width = max(line_width, l_width);
      PPLine line = new PPLine(5, 5+i*int(font_size*leading), l_width, int(font_size*leading), 0);
      line.font = font;
      line.text = new_lines.get(i) + endOfText;
      line.s_index = index;
      line.e_index = index + line.text.length()-1;
      index = index + line.text.length();
      lines.add(line);
    }
    current_line = 0;
    setData(lines);    
    //Calculate and update the canvas' height
    multiline = true;
    int line_height = int(lines.size() * font_size*leading);
    updateDrawingArea(line_width+10, line_height+10);
    scrollToShow(0, int(current_line*font_size*leading));
  }  
  void setText(String txt) {
    if (isNumerical && txt.length() > 0) {
      if (Float.isNaN(float(txt)) && !txt.equals("-")) {
        message("Please input a valid number.");
        return;
      }
    }
    text = txt + endOfText;
    textFont(font);
    textLeading(leading*font_size);
    lines = new ArrayList<PPData>();
    int line_width = _width -20;
    PPLine line = new PPLine(5, 5, line_width, int(font_size*leading), 0);
    line.font = font;
    lines.add(line);
    current_line = 0;

    if (expandWidth) {
      line.text = text;
      line.s_index = 0;
      line.e_index = text.length()-1;
      setData(lines); 
      int w = int(textWidth(text));
      if (w > cd_width) {
        updateDrawingArea(w, cd_height);
        disableHorizontalScroll = true;
        scrollToShow(w, 0);
      } else {
        updateDrawingArea(rd_width, cd_height);
        scrollToShow(w, 0);
      }
      return;
    }
    String str = "";
    int s_index = 0;
    for (int i=0; i<text.length (); i++) {
      str += str(text.charAt(i));
      if (textWidth(str) <= line_width) {
        line.text = str;
        line.s_index = s_index;
        line.e_index = i;
      } else {
        int space = str.lastIndexOf(" ");
        if (str(text.charAt(i)) == " ") {
          line.text = str;
          line.s_index = s_index;
          line.e_index = i;
        } 
        if (space == -1) {  // no spaces in that line
          line.text = text.substring(s_index, i);
          line.s_index = s_index;
          line.e_index = i-1;
          s_index = i;
          i = i--;
          str = "";
          current_line++;
          line = new PPLine(5, 5, line_width, int(font_size*leading)*current_line, 0);
          line.font = font;
          lines.add(line);
        } else {
          line.text = text.substring(s_index, s_index+space+1);
          line.s_index = s_index;
          line.e_index = s_index+space;
          i = s_index+ space;
          s_index = s_index+ space+1;

          str = "";
          current_line++;
          line = new PPLine(5, 5 + int(font_size*leading)*current_line, line_width, int(font_size*leading), 0);
          line.font = font;
          lines.add(line);
        }
      }
    }
    setData(lines);    
    //Calculate and update the canvas' height
    if (lines.size() == 1) multiline = false;
    else multiline = true;
    int h = int(lines.size() * font_size*leading);
    if (h != cd_height) {
      updateDrawingArea(_width-10, h);
    }
    scrollToShow(0, int(current_line*font_size*leading));
  }

  void display() {
    super.display();
    if (status == IDLE) {
      if (isHighlighted) clearHighlights();
      strokeWeight(1);
      noFill();
      stroke(200);
      rect(_left, _top, _width, _height);
    }
    if (status == SELECTED || status == DRAGGED) {
      strokeWeight(1);
      noFill();
      stroke(120);
      rect(_left, _top, _width, _height);
      // this is a hack to not use millis. Timing doesn't have to be exact
      if (blinker_count > 0) {
        PVector location = getCoordinatesForCurrentPos();
        if (location.y > _top &&  location.y < _top+_height) {
          line(location.x, location.y, location.x, location.y+font_size);
        }
      }
      blinker_count += blinker_direction*1;
      if (blinker_count == 20 || blinker_count == -15) {
        blinker_direction = -blinker_direction;
      }
    }
    if (isDisabled) {
      fill(color(30), 60);
      rect(_left, _top, _width, _height);
    }
  }

  void display(PGraphics p) {
    p.fill(255);
    p.noStroke();
    p.rect(_left+1, _top, _width-2, _height);

    if (status == IDLE) {
      if (isHighlighted) clearHighlights();
      p.strokeWeight(1);
      p.noFill();
      p.stroke(200);
      p.rect(_left, _top, _width, _height);
    }
    if (status == SELECTED || status == DRAGGED) {
      p.strokeWeight(1);
      p.noFill();
      p.stroke(120);
      p.rect(_left, _top, _width, _height);
      // this is a hack to not use millis. Timing doesn't have to be exact
      if (blinker_count > 0) {
        PVector location = getCoordinatesForCurrentPos();
        if (location.y > _top &&  location.y < _top+_height) {
          p.line(location.x, location.y, location.x, location.y+font_size);
        }
      }
      blinker_count += blinker_direction*1;
      if (blinker_count == 20 || blinker_count == -15) {
        blinker_direction = -blinker_direction;
      }
    }
    if (isDisabled) {
      p.fill(color(30), 60);
      p.rect(_left, _top, _width, _height);
    }

    PGraphics tmp = createGraphics(_width, _height);
    tmp.beginDraw();
    tmp.fill(0);
    if (data != null) {

      for (int i = 0; i < data.size (); i++) {
        PPData d = data.get(i);
        d.display(tmp);
      }
    }
    tmp.endDraw();
    p.image(tmp, _left, _top);
  }

  void addChar(String c) {
    if (isDisabled) return;
    if (restricted_length > 0 && text.length() == restricted_length) {
      message("Can only type "+(restricted_length-1)+" characters");
      return;
    }
    if (isHighlighted) {
      cursor_pos = s_highlight;
      deleteHighlight();
    }

    int orig_pos = cursor_pos;
    String txt;
    text = text.replaceAll(endOfText, "");
    if (cursor_pos > text.length() || cursor_pos < 0) cursor_pos = 0;
    if (cursor_pos == text.length()) {
      txt = text + c;
    } else {
      txt = text.substring(0, cursor_pos) + c +text.substring(cursor_pos, text.length());
    }

    setText(txt);
    cursor_pos = orig_pos + c.length();
    current_line = lineForPos(cursor_pos);
  }

  // removes one char in current position. Either forward or backwards
  void deleteChar(boolean forward) {
    if (isDisabled) return;
    if (isHighlighted) deleteHighlight();
    String txt;
    text = text.replaceAll(endOfText, "");
    if (forward) {
      if (cursor_pos >= text.length() ) return;
      if (cursor_pos == text.length()-1) {
        txt = text.substring(0, cursor_pos);
      } else {
        txt = text.substring(0, cursor_pos) + text.substring(cursor_pos+1, text.length());
      }
      setText(txt);
    } else {
      if (cursor_pos <= 0) return;
      txt = text.substring(0, cursor_pos-1) + text.substring(cursor_pos, text.length());
      int orig_pos = cursor_pos;
      setText(txt);
      cursor_pos = orig_pos -1;
      current_line = lineForPos(cursor_pos);
      scrollToShow(0, int(current_line*font_size*leading));
    }
  }

  void deleteHighlight() {
    if (isDisabled) return;
    if (s_highlight < 0 || e_highlight <0 ) return;
    text = text.replaceAll(endOfText, "");
    text = text.substring(0, s_highlight) + text.substring(e_highlight);
    clearHighlights();
    setText(text);
  }

  String cut() {
    if (isHighlighted) {
      String txt = text.substring(s_highlight, e_highlight);
      deleteHighlight();
      return txt;
    }
    return "";
  }

  String copy() {
    if (isHighlighted) {
      String txt = text.substring(s_highlight, e_highlight);
      return txt;
    }
    return "";
  }

  void paste(String str) {
    if (isHighlighted) deleteHighlight();
    String txt;
    txt = text.replaceAll(endOfText, "");
    int orig_cursor = cursor_pos;
    txt = text.substring(0, cursor_pos) + str +text.substring(cursor_pos);
    setText(txt);
    cursor_pos = orig_cursor + str.length();
    current_line = lineForPos(cursor_pos);
  }
  void arrowUp() {
    if (isHighlighted) clearHighlights();
    if (current_line >0) {
      PPLine line = (PPLine)lines.get(current_line);
      if (cursor_pos >= line.s_index && cursor_pos <= line.e_index) {
        int offset = cursor_pos - line.s_index;
        PPLine prev = (PPLine)lines.get(current_line-1);
        cursor_pos = prev.s_index+offset;
      }
      current_line = lineForPos(cursor_pos);
      scrollToShow(0, int(current_line*font_size*leading));
    }
  }
  void arrowDown() {
    if (isHighlighted) clearHighlights();
    if (current_line < lines.size()-1) {
      PPLine line = (PPLine)lines.get(current_line);
      if (cursor_pos >= line.s_index && cursor_pos <= line.e_index) {
        int offset = cursor_pos - line.s_index;

        PPLine next = (PPLine)lines.get(current_line+1);
        if (next.text.length() < offset) offset = next.e_index-next.s_index;
        cursor_pos = next.s_index+offset;
      }
      current_line = lineForPos(cursor_pos);
      scrollToShow(0, int(current_line*font_size*leading));
    }
  }
  void arrowLeft() {
    if (isHighlighted) clearHighlights();
    cursor_pos--;

    if (cursor_pos <0) cursor_pos = 0;
    current_line = lineForPos(cursor_pos);
  }
  void arrowRight() {
    if (isHighlighted) clearHighlights();
    cursor_pos++;
    if (cursor_pos > text.length()) cursor_pos = text.length();
    current_line = lineForPos(cursor_pos);
  }
  int lineForPos(int pos) {
    for (int i = 0; i<lines.size (); i++) {
      PPLine l = (PPLine)lines.get(i);
      if (pos>=l.s_index && pos<=l.e_index) return i;
    }
    return 0;
  }

  PVector getCoordinatesForCurrentPos() {
    if (lines.size() == 0) return new PVector( _left+5, _top+5);
    PPLine l = (PPLine)lines.get(current_line);
    if (cursor_pos >= l.s_index && cursor_pos <= l.e_index) {
      int o = l.getOffset(cursor_pos);
      return new PVector(getEffectiveLeft() + o + 5, getEffectiveTop() + current_line*leading*font_size+5);
    }
    return new PVector( _left+5, _top+5);
  }
  int moveCursorToPosition(int x, int y) {
    if (lines.size() == 0) {
      cursor_pos = 0;
      current_line = 0;
      return 0;
    }
    PPLine line = (PPLine)isInsideData(x, y); 
    if (line == null) { 
      cursor_pos = 0;
      current_line = 0;
      return -1;
    }
    current_line = lines.indexOf(line);
    cursor_pos = line.getIndex(x-getEffectiveLeft()-5);
    return cursor_pos;
  }
  void setHighlighStart(int pos) {
    clearHighlights();
    int i = lineForPos(pos);
    if (i < 0) return;
    s_highlight = pos;
    e_highlight = pos;
    isHighlighted = true;
  }
  void updateHighlight(int pos) {
    if (pos == -1) return;
    int start = s_highlight;
    int end = e_highlight;
    clearHighlights();
    s_highlight = start;
    e_highlight = end;
    if (pos>s_highlight && pos <e_highlight) {
      e_highlight = pos;
    } else if (pos<s_highlight) {
      s_highlight = pos;
    } else if (pos>e_highlight) {
      e_highlight = pos;
    }

    int i1 = lineForPos(s_highlight);
    int i2 = lineForPos(e_highlight);
    if (i1 < 0 || i2 < 0) return;
    for (int i = i1; i <=i2; i++) {
      PPLine line = (PPLine)lines.get(i);
      line.s_highlight = max(s_highlight, line.s_index);
      line.e_highlight = min(e_highlight, line.e_index);
      line.status = SELECTED;
    }
    isHighlighted = true;
  }
  void setHighlighEnd(int pos) {
    if (s_highlight == e_highlight) {
      clearHighlights();
      isHighlighted = false;
    }
  }
  void clearHighlights() {
    s_highlight = -1;
    e_highlight = -1;
    for (int i=0; i<lines.size (); i++) {
      PPLine line = (PPLine)lines.get(i);
      line.s_highlight = -1;
      line.e_highlight = -1;
      line.status = IDLE;
    }
    isHighlighted = false;
  }

  PPUIComponent isInside(int x, int y, boolean propogate) {  
    if (!multiline) {
      if (isInside(x, y)) return this;
      else return null;
    }   
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
}
 
////////////////////////////////////////////////////////
// PPLine, used by PPUIText
////////////////////////////////////////////////////////
class PPLine extends PPData {
  int _width;
  int _height;
  String text = "";
  int s_index = -1;
  int e_index = -1;
  boolean spaceBefore = false;
  boolean spaceAfter = false;
  int s_highlight = -1;
  int e_highlight = -1;

  PFont font = null;

  PPLine(int _l, int _t, int _w, int _h, int index) {
    _left = _l;
    _top = _t;
    _width = _w;
    _height = _h;
    s_index = index;
    e_index = index;
    name = "line";
  }

  String getText() {
    String str = text;
    if (spaceBefore) {
      str = " "+str;
    }
    if (spaceAfter) {
      str = str + " ";
    }
    return str;
  }
  boolean isInside(int x, int y) {
    if (x>_left && x<_left+_width &&
      y>_top && y<_top+_height) {
      return true;
    }
    return false;
  }
  int getOffset(int pos) {
    if (pos < s_index || pos > e_index) return -1;
    textFont(font);
    pos = pos - s_index;
    return int(textWidth(text.substring(0, pos)));
  }
  int getIndex(int offset) {
    textFont(font);
    for (int i = 0; i<text.length ()-1; i++) {
      float off = textWidth(text.substring(0, i+1));
      if (offset - off < 2) return s_index+ i ;
    }
    if (offset < textWidth("M")) return s_index;
    return e_index;
  }

  void display(PGraphics p) {
    p.noStroke();
    if (status == SELECTED) {
      float x1 = textWidth(text.substring(0, s_highlight-s_index));
      float x2 = textWidth(text.substring(0, e_highlight-s_index));
      p.pushStyle();
      p.noStroke();
      p.fill(255, 215, 0, 150);
      p.rect(x1+2, _top, x2-x1+2, _height);
      p.popStyle();
    }  
    p.fill(0);
    if (font != null) {
      p.textFont(font);
    }
    p.textAlign(LEFT, TOP);
    p.text(text, _left, _top);
  }
}


//////////////////////////////////////////////
// PPUIList
/////////////////////////////////////////////
class PPUIList extends PPUIComponent {
  String[] options;
  int selected;  // index in the options array
  PFont font;
  int item_height = 25;
  int total_height;
  int default_selection = -1;
  PPUIList(Controller c, String _n, int _l, int _t, String[] _options) {
    super(c, _n, _l, _t, 20, 20);  // will correct width and height after calculating them
    type="list";
    font = createFont("Arial", 13);
    options = _options;
    selected = default_selection;
    total_height = (options.length +2)*item_height;
    textFont(font);
    for (int i = 0; i<options.length; i++) {
      int t = int(textWidth(options[i]));
      _width = max(_width, t);
    }
    _width+=40; // for padding + triangle
    canResize = true;
    _height = item_height;
  }

  void updateOptions(String[] n_op) {
    int n_selected = -1;
    if (selected != -1) { // see if that option exists in the new list
      for (int i = 0; i<n_op.length; i++) {
        if (n_op[i].equals(getSelection())) n_selected = i;
      }
    }
    if (n_selected == -1) n_selected = default_selection;
    selected = n_selected;
    options = n_op;
    total_height = (options.length +2)*item_height;
    textFont(font);
    _width = 20;
    for (int i = 0; i<options.length; i++) {
      int t = int(textWidth(options[i]));
      _width = max(_width, t);
    }
    _width+=40; // for padding + triangle
    canResize = true;
    _height = item_height;
  }
  void makeInvisible() {
    outOfFocus();
    super.makeInvisible();
  }
  void outOfFocus() {
    if (parent != null) {
      parent.componentTriggered(this);
    }
  }

  void display(PGraphics p) {
    if (status ==IDLE || status == INVISIBLE) outOfFocus();
    textFont(font);
    if (status == IDLE) {
      if (default_selection != -1 && selected == -1) selected = default_selection;
      p.stroke(140);
      p.strokeWeight(1);
      p.fill(255);
      p.rect(_left, _top, _width, item_height, 10);
      if (selected>= 0) {
        p.textFont(font);
        p.fill(50);
        p.textAlign(LEFT);
        p.text(options[selected], _left+10, _top+17);
      }
      if (options.length>0) {
        p.noStroke();
        p.fill(70);
        p.rect(_left+_width-item_height, _top, item_height, item_height, 0, 10, 10, 0);
        p.fill(210);
        p.triangle(_left+_width-item_height+5, _top+7, _left+_width-5, _top +7, _left+_width-item_height + item_height/2, _top+item_height-5);
      }
    } else if (status == SELECTED && options.length>0) {
      int offset = _top +item_height;
      p.stroke(140);
      p.strokeWeight(1);
      p.fill(255);
      p.rect(_left, _top, _width, _height, 10);
      p.fill(70);
      p.rect(_left, _top, _width, item_height, 10, 10, 0, 0);
      p.textAlign(LEFT);
      if (selected >=0) {
        p.fill(210);
        p.text(options[selected], _left+10, _top+17);
      }
      offset+=item_height;
      p.fill(60);
      for (int i = 0; i<options.length; i++) {
        p.line(_left, offset, _left+_width, offset);
        p.text(options[i], _left+10, offset+17);
        offset+=item_height;
      }
    }
  }

  void display() {
    if (parent != null) return;
    if (status ==IDLE || status == INVISIBLE) outOfFocus();
    textFont(font);
    if (status == IDLE) {
      if (default_selection != -1 && selected == -1) selected = default_selection;
      stroke(140);
      strokeWeight(1);
      fill(255);
      rect(_left, _top, _width, item_height, 10);
      if (selected>= 0) {
        textFont(font);
        fill(50);
        textAlign(LEFT);
        text(options[selected], _left+10, _top+17);
      }
      if (options.length>0) {
        noStroke();
        fill(70);
        rect(_left+_width-item_height, _top, item_height, item_height, 0, 10, 10, 0);
        fill(210);
        triangle(_left+_width-item_height+5, _top+7, _left+_width-5, _top +7, _left+_width-item_height + item_height/2, _top+item_height-5);
      }
    } else if (status == SELECTED && options.length>0) {
      int offset = _top +item_height;
      stroke(140);
      strokeWeight(1);
      fill(255);
      rect(_left, _top, _width, _height, 10);
      fill(70);
      rect(_left, _top, _width, item_height, 10, 10, 0, 0);
      textAlign(LEFT);
      if (selected >=0) {
        fill(210);
        text(options[selected], _left+10, _top+17);
      }
      offset+=item_height;
      fill(60);
      for (int i = 0; i<options.length; i++) {
        line(_left, offset, _left+_width, offset);
        text(options[i], _left+10, offset+17);
        offset+=item_height;
      }
    }
  }
  String getSelection() {
    if (selected == -1) return "";
    else return options[selected];
  }
  void select(int index) {
    if (index > 0 && index <options.length) {
      selected = index;
    }
  }
  void shrink() {
    if (_height != item_height) activate();
  }
  void activate() {
    if (_height == item_height && options.length>0) {
      status = SELECTED;
      _height = total_height;
      offsetBy = _height - item_height;
      isUpdated = true;
    } else {

      status = IDLE;
      _height = item_height;
      isUpdated = true;
      offsetBy = -(total_height - item_height);
    }
    isUpdated = true;
  }
  boolean isInside(int x, int y) {
    if (status == IDLE) {
      if (x>_left && x<_left+_width &&
        y>_top && y<_top+item_height) {

        return true;
      }
      return false;
    } else if (status == SELECTED) {
      int offset = _top;
      if (x>_left && x<_left+_width) {
        if (y> offset && y< offset +item_height) {
          return true;
        }  
        offset += item_height;
        if (y> offset && y< offset +item_height) {
          selected = -1;
          return true;
        }
        offset += item_height;
        for (int i = 0; i< options.length; i++) {
          if (y> offset && y< offset +item_height) {
            selected = i;
            return true;
          }
          offset += item_height;
        }
        return false;
      }
      return false;
    }
    return false;
  }
}

//////////////////////////////////////////////
// PPTable
/////////////////////////////////////////////
class PPTable extends PPData {
  ArrayList<PPData> data;
  //int selected;  // index in the options array
  PFont font;
  int _width;
  int _height;
  int item_height = 25;
  int total_height;
  PPData parent = null;
  PPTable(String _n, int _l, int _t, ArrayList<PPData> _data) {
    name = _n;
    _left = _l;
    _top = _t;
    type="table";
    status = IDLE;
    font = createFont("Arial", 13);
    data = _data;
    total_height = data.size()*item_height;
    textFont(font);
    for (int i = 0; i<data.size (); i++) {
      int t = int(textWidth(data.get(i).name+" (ID:"+data.get(i).id+")"));
      _width = max(_width, t);
    }
    _width+=80; // for padding + two buttons
    int y_off = 0;
    for (int i = 0; i<data.size (); i++) {
      DeleteInlineButton del = new DeleteInlineButton(controller, this, data.get(i), _width -50, y_off+3);
      EditInlineButton edit = new EditInlineButton(controller, this, data.get(i), _width -25, y_off+3);
      del.fixed_position = false;
      edit.fixed_position = false;
      associateComponent(del);
      associateComponent(edit);
      y_off += item_height;
    }
    _height = max(item_height, total_height);
  }

  int size() {
    return data.size();
  }
  void updateOptions(ArrayList<PPData> n_data) {

    for (int i = 0; i<associated_components.size (); i++) {
      associated_components.remove(associated_components.get(i));
    }
    data = n_data;
    _width = 20;
    total_height = data.size()*item_height;
    textFont(font);
    for (int i = 0; i<data.size (); i++) {
      int t = int(textWidth(data.get(i).name+" (ID:"+data.get(i).id+")"));
      _width = max(_width, t);
    }
    _width+=80; // for padding + two buttons

    int y_off = 0;
    for (int i = 0; i<data.size (); i++) {
      DeleteInlineButton del = new DeleteInlineButton(controller, this, data.get(i), _width -50, y_off+3);
      EditInlineButton edit = new EditInlineButton(controller, this, data.get(i), _width -25, y_off+3);
      del.fixed_position = false;
      edit.fixed_position = false;
      associateComponent(del);
      associateComponent(edit);
      y_off += item_height;
    }

    _height = max(item_height, total_height);
  }

  void display(PGraphics p) {
    if (status == IDLE && data.size()>0) {
      p.stroke(140);
      p.strokeWeight(1);
      p.fill(0);
      //p.rect(_left, _top, _width, _height);
      p.textAlign(LEFT);
      int y_off = 0;
      p.line(_left, _top, _left+_width, _top);
      for (int i = 0; i<data.size (); i++) {
        if (i %  2 == 0) {
          p.fill(210);

          p.noStroke();
          p.rect(_left, _top+y_off, _width, item_height);
          p.fill(0);
          p.stroke(140);
        }
        p.text(data.get(i).name+" (ID:"+data.get(i).id+")", _left+10, _top+y_off+17);
        y_off += item_height;
        p.line( _left, _top+y_off, _left+_width, _top+y_off);
      }
    }
  }
  void removeData(PPData d) {
    unassociateComponents(associated_components);
    creator.deleteRepresentation(d.rep);
    ((Representation)parent).bringToFocus();
    controller.setResource(parent, true);
  }
  void editData(PPData d) {
    controller.setResource(d.rep, true);
  }

  boolean isInside(int x, int y) {
    if (status == IDLE) {
      if (x>_left && x<_left+_width &&
        y>_top && y<_top+item_height) {

        return true;
      }
    }
    return false;
  }
}

//////////////////////////////////////////////
// PPUITable
// holds a PPTable
/////////////////////////////////////////////
class PPUITable extends PPUIComponent {
  PPTable table;
  PPUITable(String _n, int _l, int _t, ArrayList<PPData> _data) {
    table = new PPTable(_n, _l, _t, _data);
    _top = table._top;
    _left = table._left;
    _width = table._width;
    _height = table._height;
    name = "ui table";
  }
  void display(PGraphics p) {
    table._top =_top;
    table._left =_left;
    table.parent = parent;
    table.display(p);
  }

  ArrayList<PPUIComponent> getAssociatedComponents() {
    return table.associated_components;
  }
  void updateOptions(ArrayList<PPData> n_data) {
    table.updateOptions(n_data);

    _width = table._width;
    _height = table._height;
  }
  boolean isInside(int x, int y) {
    return table.isInside(x, y);
  }
}

