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
float contrast = 1.35;
int brightness = 0;
int threshold = 75;
int blurSize = 4;

// STATE VARS
boolean mirrorMode = false;
boolean debugging = true;
boolean clear=false;

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
    
  //image(processedImage, 0, 0);
  
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
    println("debugging");
    print(debugging);
  }
 
  if (key == 'c' || key == 'C') {
    clear = true;
    println("clear");
  }      
}