import com.shigeodayo.ardrone.processing.*;

import processing.video.*;
import jp.nyatla.nyar4psg.*;
import processing.opengl.*;
import javax.media.opengl.*;

ARDroneForP5 ardrone;

boolean video720p = false;

Tracker tracker;
int numTargets = 4;
int numMarkersTarget = 2;
float targetWidth = 49.0f; // [cm]
String unit = "cm";

int targetId = 3;

boolean autoMode = false;

void setup() {
  if (video720p) {
    size(1280, 720, P3D);
  }
  else {
    size(640, 360, P3D);
  }
  colorMode(RGB, 100);

  tracker = new Tracker(this, width, height, numTargets, numMarkersTarget, targetWidth, unit);

  ardrone=new ARDroneForP5("192.168.1.1");
  // connect to the AR.Drone
  ardrone.connect(video720p);
  // for getting sensor information
  ardrone.connectNav();
  // for getting video information
  ardrone.connectVideo();
  // start to control AR.Drone and get sensor and video data of it
  ardrone.start();
}

void draw() {
  background(204);
  textSize(height/12);  

  // getting image from AR.Drone
  // true: resizeing image automatically
  // false: not resizing
  PImage img = ardrone.getVideoImage(true);
  if (img == null)
    return;

  hint(DISABLE_DEPTH_TEST);
  image(img, 0, 0);
  hint(ENABLE_DEPTH_TEST);

  tracker.Detect(img);
  background(0);
  tracker.DrawBackground(img);
  
  for (int i=0; i<numTargets; i++) {
    if (!tracker.IsExistTarget(i))
      continue;

    // draw marker contour
    int step = 360 / numTargets;
    PVector[] v = tracker.GetTargetCurrentMarkerVertex2D(i);  
    colorMode(HSB, 360, 100, 100, 100);
    stroke(i*step, 100, 100, 100);
    strokeWeight(4);
    noFill();
    beginShape();
    vertex(v[0].x, v[0].y);      
    vertex(v[1].x, v[1].y);
    vertex(v[2].x, v[2].y);
    vertex(v[3].x, v[3].y);
    endShape(CLOSE);

    // Target 2 camera matrix
    PMatrix3D T2C = tracker.GetTargetMatrix(i);

    // draw marker-image sized box
    tracker.BeginTransform(T2C);
    fill(i*step, 100, 100, 50);
    box(0.7 * tracker.GetTargetCurrentMarkerWidth(i));
    tracker.EndTransform();
  }
 
  // draw status bar
  colorMode(RGB, 256, 256, 256, 100);
  fill(0, 0, 0, 50);
  noStroke();
  rect(0, 0, width, height/9);
  fill(255, 255, 255);
    
  text("Position of #" + targetId, width/128*70, height/12*2.5);
  
  // print out AR.Drone information
  ardrone.printARDroneInfo();

  // getting sensor information of AR.Drone
  int battery = ardrone.getBatteryPercentage();
  text("battery:" + battery + " %",0,height-10);
  
  if (!tracker.IsExistTarget(targetId)) {
    text("hover", width/128, height/12);
    if (autoMode) ardrone.stop();
    return;
  }
  
// get marker position
  PVector P = tracker.GetTargetPosition(targetId);
  float x = P.x *  10; //[cm -> mm]
  float y = P.y *  10; //[cm -> mm]
  float z = P.z * -10; //[cm -> mm]
  text(nfp(x/1000,1,3) + ", " + nfp(y/1000,1,3) + ", " + nf(z/1000,2,3), width/128*50, height/12);

  // display the distance to the marker
  float d = sqrt(x * x + y * y + z * z);
  text(nf(d / 1000, 1, 3), width / 128 * 50, height/12 * 2);
  if (d <= 1500) {
    text("OK", width / 128 * 50, height/12 * 3);
  }
  text(nf(d / 1000, 1, 3), width / 128 * 50, height/12 * 2);

  text("hover", width/128, height/12);
  if (autoMode) ardrone.stop();
}

// controlling AR.Drone through key input
void keyReleased() {
  ardrone.stop(); // hovering
}

void keyPressed() {
  autoMode = false;
  
  if (key == CODED) {
    if (keyCode == UP) {
      ardrone.forward((20)); // go forward
    } 
    else if (keyCode == DOWN) {
      ardrone.backward((20)); // go backward
    } 
    else if (keyCode == LEFT) {
      ardrone.goLeft((20)); // go left
    } 
    else if (keyCode == RIGHT) {
      ardrone.goRight((20)); // go right
    } 
    else if (keyCode == SHIFT) {
      ardrone.takeOff(); // take off, AR.Drone cannot move while landing
      tracker.LogEvent("takeoff"); 
    } 
    else if (keyCode == CONTROL) {
      ardrone.landing(); // landing
      tracker.LogEvent("landing"); 
    }
    else if (keyCode == ALT) {
      ardrone.reset(); // reset
    }
  } 
  else {
    if (key == 's') {
      ardrone.stop(); // hovering
    } 
    else if (key == 'r') {
      ardrone.spinRight(50); // spin right
    } 
    else if (key == 'l') {
      ardrone.spinLeft(50); // spin left
    } 
    else if (key == 'u') {
      ardrone.up(50); // go up
    }
    else if (key == 'd') {
      ardrone.down(50); // go down
    }
    else if (key == '1') {
      ardrone.setHorizontalCamera(); // set front camera
    }
    else if (key == '2') {
      ardrone.setHorizontalCameraWithVertical(); // set front camera with second camera (upper left)
    }
    else if (key == '3') {
      ardrone.setVerticalCamera(); // set second camera
    }
    else if (key == '4') {
      ardrone.setVerticalCameraWithHorizontal(); //set second camera with front camera (upper left)
    }
    else if (key == '5') {
      ardrone.toggleCamera(); // set next camera setting
    }
    else if (key == 'a') {
      autoMode = true;
    }
    else if (key == '0') {
      targetId++;
      if(targetId == numTargets) targetId = 0; 
    }
  }
}

