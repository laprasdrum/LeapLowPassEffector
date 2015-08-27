import controlP5.*;
import java.util.*;

import com.onformative.leap.LeapMotionP5;
import ddf.minim.*;
import ddf.minim.signals.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;

LeapMotionP5 leap;

ControlP5 controlP5;
final ArrayList<Runnable> runs = new ArrayList<Runnable>();

Minim minim;
AudioPlayer audio;
float sampleRate;
LowPassSP lpFilter;
Flock flock;
int flocks = 150;

void setup() {
  size(800, 800);
  leap = new LeapMotionP5(this);
  setupController();
  setupAudio();
  setupFlock();
}


void setupController() {
  controlP5 = new ControlP5(this);
  addFileChooser();
}

void keyPressed() {
  if (key == ' ') {
    addFileChooser();
  }
}

void addFileChooser() {
  final Group fileGroup = controlP5.addGroup("file_chooser")
    .setPosition(100, 50)
    .setSize(300, 300)
    .setBackgroundColor(color(0, 160))
    .hideBar();

  final Textfield textfield = controlP5.addTextfield("file")
    .setPosition(8, 210)
    .setSize(284, 20)
    .setGroup("file_chooser")
    .setColorBackground(color(100))
    .setColorForeground(color(100));

  textfield.getCaptionLabel().hide();

  final ListBox listBox = controlP5.addListBox("select_files")
    .setSize(300, 300)
    .setPosition(0, 0)
    .setColorBackground(color(120))
    .hideBar()
    .setStringValue(new File(sketchPath("")).toString())
    .setGroup("file_chooser")
    .addListener(new ControlListener() {
    public void controlEvent(final ControlEvent ev) {
      runs.add(new Runnable() {
        public void run() {
          updateFileChooser( ((ListBox) ev.getGroup()), textfield, int(ev.getValue()) );
        }
      }
      );
    }
  }
  );

  controlP5.addButton("save")
    .setPosition(7, 240)
    .setSize(120, 20)
    .setGroup("file_chooser")
    .setColorBackground(color(100))
    .setColorForeground(color(150))
    .addListener(new ControlListener() {
    public void controlEvent(ControlEvent ev) {
      println("now save something to "+
        new File( new File( listBox.getStringValue() ), 
        textfield.getText() ).toString()
        );
    }
  }
  );

  controlP5.addButton("cancel")
    .setPosition(173, 240)
    .setSize(120, 20)
    .setGroup("file_chooser")
    .setColorBackground(color(100))
    .setColorForeground(color(150))
    .addListener(new ControlListener() {
    // when cancel is triggered, add a new runnable to 
    // safely remove the filechooser from controlP5 in
    // a post event.
    public void controlEvent(ControlEvent ev) {
      runs.add(new Runnable() { 
        public void run() {
          fileGroup.remove();
        }
      }
      );
    }
  }
  );

  updateFileChooser( listBox, textfield, 0 );
}

final void updateFileChooser(ListBox lb, Textfield tf, int theValue) {

  String s = (lb.getListBoxItems( ).length==0) ? "" : lb.getListBoxItems( )[theValue][0];

  File f;

  if (s.equals("..") ) {
    f = new File( lb.getStringValue( ) ).getParentFile( );
  } else {
    f = new File ( new File( lb.getStringValue( ) ), s );
  }

  if ( f!=null ) {
    if (f.isDirectory( ) ) {
      String[] strs = f.list( );
      lb.clear();
      lb.setColorForeground(color(0, 128, 100));
      lb.setColorActive(color(0, 210, 150));
      int n = 0;
      lb.addItem(f.getName(), n++).setColorBackground(color(80));
      lb.addItem("..", n++);
      for (String s1 : strs) {
        ListBoxItem item = lb.addItem( s1, n++);
        if (new File(f, s1).isDirectory()) {
          item.setColorBackground(color(60, 90, 100));
        }
      }
      lb.scroll(0);
      lb.setStringValue( f.getAbsolutePath().toString( ) );
    } else if ( theValue != 0 ) {
      println("file selected : "+f.getAbsolutePath());
      tf.setText(f.getName());
    }
  }
}

public void post() {
  Iterator<Runnable> it = runs.iterator();
  while (it.hasNext ()) {
    it.next().run();
    it.remove();
  }
}

void setupAudio() {
  minim = new Minim(this);
  audio = minim.loadFile("sample.wav", 512*4);
  audio.play();

  sampleRate = audio.sampleRate();
  lpFilter = new LowPassSP(sampleRate, sampleRate);
  audio.addEffect(lpFilter);
}

void setupFlock() {
  flock = new Flock();
  // Add an initial set of boids into the system
  for (int i = 0; i < flocks; i++) {
    flock.addBoid(new Boid(width / 2, height / 2));
  }
}

void draw() {
  background(0);
  flock.run();
  if (isHandDetected()) {
    PVector fingerPos = leap.getTip(leap.getFinger(0));
    setLPFFromPosition(fingerPos.y);
  }
}

void stop() {
  audio.close();
  minim.stop();
  super.stop();
}

void setLPFFromPosition(float pos) {
  float cutoff = getValidatedCutoff(pos);
  lpFilter.setFreq(cutoff);
  flock.setBorder(pos / 2);
}

float getValidatedCutoff(float pos) {
  // 手を離すほどフィルターを無効にする (pos -> -∞)
  if (pos <= 0) {
    return sampleRate;
  } else {
    return sampleRate * pow(1 - pos / height, 2);
  }
}

boolean isHandDetected() {
  return leap.getFrame().hands().count() > 0;
}

void printLeapInfo() {
  PVector fingerPos = leap.getTip(leap.getFinger(0));
  println(leap.getFrame().hands().count() + " hand(s) " + leap.getFrame().fingers().count() + " finger(s): (" + fingerPos.x + ", " + fingerPos.y + ")");
}