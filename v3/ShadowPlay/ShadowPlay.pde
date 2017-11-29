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

void setup() {
  frameRate(15);
  
  video = new Capture(this, PROJECTOR_WIDTH, PROJECTOR_HEIGHT);
  //video = new Capture(this, 640, 480, "USB2.0 PC CAMERA");

  video.start();
  
  opencv = new OpenCV(this, PROJECTOR_WIDTH, PROJECTOR_HEIGHT);
  // contours = new ArrayList<Contour>();
  // blobList = new ArrayList<Blob>();
  
  size(1024, 768, P2D);
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
  
  image(processedImage, 0, 0);
  
}