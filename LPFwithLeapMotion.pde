import com.onformative.leap.LeapMotionP5;
import ddf.minim.*;
import ddf.minim.signals.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;

LeapMotionP5 leap;
Minim minim;
AudioPlayer audio;
float sampleRate;
LowPassSP lpFilter;
Flock flock;
int flocks = 150;

void setup() {
  size(800, 800);
  leap = new LeapMotionP5(this);
  setupAudio();
  setupFlock();
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

