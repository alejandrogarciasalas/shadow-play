import gab.opencv.*;
import java.awt.Rectangle;
import processing.video.*;
import controlP5.*;

OpenCV opencv;
Capture video;
PImage src, preProcessedImage, processedImage;

// CALIBRATION VARS
int PROJECTOR_WIDTH = 1024; // old was 640
int PROJECTOR_HEIGHT = 768; // old was 480

// get from calibration program
float contrast = 1.35; 
int threshold = 75;
int blurSize = 4;

int zoom = 0;

// change if neccesary...
int brightness = 0;


// STATE VARS
boolean mirrorMode = false;
boolean clear=false;
boolean debugging = false;

// EFFECT VARS
PImage snapshot;
PImage mirrorSnapshot;

void setup() {
  frameRate(15);
  
  video = new Capture(this, PROJECTOR_WIDTH, PROJECTOR_HEIGHT);
  //video = new Capture(this, 640, 480, "USB2.0 PC CAMERA");
  video.start();
  
  opencv = new OpenCV(this, PROJECTOR_WIDTH, PROJECTOR_HEIGHT);
  
  size(1024, 768, P2D); // SHOULD MATCH PROJECTOR DIMENSIONS
  
  snapshot = loadImage("blankbg.jpg");
  
  println("debugging: " + debugging);
}

void draw() {
  if (video.available()) {
    video.read();
  }
  opencv.loadImage(video);
  src = opencv.getSnapshot();
  
  // ******************** <1> PRE-PROCESS IMAGE ********************
  opencv.gray();
  //opencv.brightness(brightness);
  opencv.contrast(contrast);
  
  // Save snapshot for display
  preProcessedImage = opencv.getSnapshot();
  
  // ******************** PROCESS IMAGE ********************
  // - Threshold
  // - Noise Supression
  
  opencv.threshold(threshold);

  // Invert (black bg, white blobs)
  opencv.invert();
  
  // Reduce noise - Dilate and erode to close holes
  opencv.dilate();
  opencv.erode();

  opencv.blur(blurSize);
  
  opencv.invert(); // TODO (figure out if we should be calling this twice!)

  processedImage = opencv.getSnapshot();
 
  background(255); 
  if (clear == true) {
    snapshot = loadImage("blankbg.jpg");
    clear = false;
  }
  image(snapshot, 0, 0);
    

  if (mirrorMode == true) {
    mirrorSnapshot = opencv.getSnapshot(); // get whatever is currently on opencv, should be processed image video feed
    pushMatrix();
    translate(mirrorSnapshot.width,0);
    scale(-1,1);
    image(mirrorSnapshot,0,0);
    popMatrix();  
  } 
  if (debugging == true) {
    //image(processedImage, 0, 0, width/4, height/4);
    //println(mouseX);
    zoom = mouseX;
    image(processedImage, 0 - zoom, 0 - zoom, width + zoom, height + zoom);
  }
  
}


void keyReleased() {
  if (key == 's' || key == 'S') {
    //snapshot = get();
    snapshot = opencv.getSnapshot(); // get whatever is currently on opencv, should be processed image video feed
    println("snapshot");
  }
  if (key == 'm' || key == 'M') {
    mirrorMode = !mirrorMode;
    println("mirror");
    print(mirrorMode);
  }  

  if (key == 'd' || key == 'D') {
    debugging = !debugging;
    println("debugging: " + debugging);
  }
 
  if (key == 'c' || key == 'C') {
    clear = true;
    println("clear");
  }      
}

void keyPressed() {
  if (key == CODED) {
    if (keyCode == UP) {
      zoom += 1;
      println(zoom);
    } else if (keyCode == DOWN) {
      zoom -= 1;
      println(zoom);
    } 
  }
}