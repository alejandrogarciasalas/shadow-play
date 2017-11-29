import gab.opencv.*;
import processing.video.*;

import org.opencv.imgproc.Imgproc;
import org.opencv.core.MatOfPoint2f;
import org.opencv.core.Point;
import org.opencv.core.Size;

import org.opencv.core.Mat;
import org.opencv.core.CvType;


OpenCV opencv;
Capture video;
PImage src, preProcessedImage, processedImage, contoursImage;

float contrast = 1.35;
int brightness = 0;
int threshold = 75;
boolean useAdaptiveThreshold = false; // use basic thresholding
int thresholdBlockSize = 489;
int thresholdConstant = 45;
int blobSizeThreshold = 20;
int blurSize = 4;

Capture cam;

Contour contour;

PImage snapshot;

boolean mirrorMode = false;

boolean debugging = true;

boolean clear=false;

void setup() {
  size(1024, 768, P2D);

  snapshot = loadImage("blank.jpg");
  
  String[] cameras = Capture.list();
  
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(cameras[i]);
    }
    frameRate(15);
    video = new Capture(this, 1024, 768, cameras[0]);
    video.start(); 
    opencv = new OpenCV(this, 1024, 768);
    
  }      
}

void draw() {
  if (video.available() == true) {
    video.read();
  }
  
  opencv.loadImage(video);
  
  src = opencv.getSnapshot(); 
  //opencv.blur(1);
  //opencv.threshold(120);  
  //contour = opencv.findContours(false, true).get(0).getPolygonApproximation();

  //background(255);
  image(snapshot, 0, 0);
}

//save image
void keyReleased() {
  if (key == 's' || key == 'S') {
    //snapshot = get();
    //image(video, 0, 0);
    snapshot = opencv.getSnapshot();    
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