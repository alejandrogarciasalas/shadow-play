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
boolean recording = false;

// EFFECT VARS
PImage snapshot;
PImage mirrorSnapshot;

//gif
PImage curr_frame;
ArrayList<PImage> gifFrames = new ArrayList<PImage>();
int gifStartingTime;
int gifRecordingTimePassed = 0;
int gifMaxDuration = 6000;
int gif_frame_index = 0;

void setup() {
  // frameRate(15);
  
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

  if (gifFrames.size() > 0) {
    image(gifFrames.get(gif_frame_index), 0 - zoom/2, 0 - zoom/2, width + zoom, height + zoom); // SHOW   
    gif_frame_index = (gif_frame_index + 1) % gifFrames.size(); // so it loops around...  
  } else { // just static
    image(snapshot, 0 - zoom/2, 0 - zoom/2, width + zoom, height + zoom); // SHOW   
  }
  
  
    

  if (mirrorMode == true) {
    mirrorSnapshot = opencv.getSnapshot(); // get whatever is currently on opencv, should be processed image video feed
    pushMatrix();
    translate(mirrorSnapshot.width,0);
    scale(-1,1);
    image(mirrorSnapshot, 0 - zoom/2, 0 - zoom/2, width + zoom, height + zoom); // SHOW
    popMatrix();  
  } 
  if (debugging == true) {
    image(processedImage, 0, 0, width/4, height/4);
    //zoom = mouseX;
    // println("zoom: " + zoom);
    //image(processedImage, 0 - zoom/2, 0 - zoom/2, width + zoom, height + zoom);
  }

  if (recording == true) {
      curr_frame = opencv.getSnapshot();
      gifFrames.add(curr_frame);
      
      // PRINT HOW MUCH TIME IT HAS PASSED FROM RECORDING EVERY SECOND
      if (millis() > gifStartingTime + 1000) {
        println(millis());
        gifRecordingTimePassed += 1;
        println("time passed: "  + gifRecordingTimePassed);
      }

      // DONE WITH RECORDING
      if (millis() > gifStartingTime + gifMaxDuration) {
        recording = false;
        println("stop recording");
      }    
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

  if (key == 'r' || key == 'R') {
    println("start recording");
    gifStartingTime = millis();
    gifFrames = new ArrayList<PImage>(); // clean gif frames
    recording = true;
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