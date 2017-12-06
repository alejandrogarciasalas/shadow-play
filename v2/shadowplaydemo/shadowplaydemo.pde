import gab.opencv.*;
import SimpleOpenNI.*;
import KinectProjectorToolkit.*;

OpenCV opencv;
SimpleOpenNI kinect;
KinectProjectorToolkit kpc;
ArrayList<ProjectedContour> projectedContours;
ArrayList<PGraphics> projectedGraphics;

ArrayList<Fireball> fireballs;
PGraphics pgFireball;

PImage snapshot;
PImage mirrorSnapshot;

boolean mirrorMode = false;

boolean debugging = false;

boolean clear=false;

//gif
boolean recording = false;
PImage curr_frame;
ArrayList<PImage> newGifFrames = new ArrayList<PImage>();
ArrayList<PImage> gifFrames = new ArrayList<PImage>();
int gifStartingTime;
int gifRecordingTimePassed = 0;
int gifMaxDuration = 5000;
int gifFrameIndex = 0;
boolean gifForward = true;


// ARDUINO
import processing.serial.*;
import cc.arduino.*;
Arduino arduino;
int buttonState = 0;             //reading from input
int lastButtonState = Arduino.LOW;   //previous reading for debounce
int pot = 0; 
int potValue = 0;
int buttonPin = 2;
// the following variables are unsigned longs because the time, measured in
// milliseconds, will quickly become a bigger number than can be stored in an int.
int lastDebounceTime = 0;  // the last time the output pin was toggled
int debounceDelay = 50;    // the debounce time; increase if the output flickers
boolean pressed = false;

//
 
int effectState = 1;

void setup()
{
  size(displayWidth, displayHeight, P2D); 

//  fullScreen(P2D);

  // setup Kinect
  kinect = new SimpleOpenNI(this); 
  kinect.enableDepth();
  kinect.enableUser();
  kinect.alternativeViewPointDepthToImage();
  
  // setup OpenCV
  opencv = new OpenCV(this, kinect.depthWidth(), kinect.depthHeight());  
  
  // setup Kinect Projector Toolkit
  kpc = new KinectProjectorToolkit(this, kinect.depthWidth(), kinect.depthHeight());
  kpc.loadCalibration("calibration.txt");
  
  kpc.setContourSmoothness(2);
  
  projectedGraphics = initializeProjectedGraphics();
  
  snapshot = loadImage("blank.jpg");
  
  // load fireballs data
  pgFireball = createGraphics(400, 400);
  fireballs = new ArrayList<Fireball>();
  
  // ARDUINO
  println(Arduino.list());
  arduino = new Arduino(this, Arduino.list()[3], 57600);
  int builtinPin = 13;
  arduino.pinMode(builtinPin, Arduino.OUTPUT);
  arduino.analogWrite(builtinPin, 255);
  
  arduino.pinMode(pot, Arduino.INPUT);
  arduino.pinMode(buttonPin, Arduino.INPUT);
}

void draw(){  
  PImage cameraIcon = loadImage("camera_icon.png");  
  PImage loopIcon = loadImage("loop_icon.png");
  PImage mirrorIcon = loadImage("mirror_icon.png");
  PImage clearIcon = loadImage("clear_icon.png");
  PImage fireIcon = loadImage("fire_icon.png");
  
    
  // ARDUINO
  int potValue = arduino.analogRead(pot); 
  int reading = arduino.digitalRead(buttonPin);
  
  if (reading != lastButtonState) {
    // reset debouncing timer
    lastDebounceTime = millis();
  }

  if ((millis() - lastDebounceTime) > debounceDelay) { 
      // if the button state has changed:
      if (reading != buttonState) {
        buttonState = reading;
        
        // only toggle the LED if the new button state is HIGH
        if (buttonState == Arduino.LOW) {
          pressed = true;
          if (potValue < 204) {
            effectState = 1;
          }
          if ((potValue >= 204) && (potValue < 409)) {
            effectState = 2;
          }
          if ((potValue >= 409) && (potValue < 614)) {
            effectState = 3;
          }
          if ((potValue >= 614) && (potValue < 819)) {
            effectState = 4;
          }
          if ((potValue >= 819) && (potValue < 1024)) {
            effectState = 5;          
          }
          println("effect state: " + effectState);
        }
       if (buttonState == Arduino.HIGH) {
          pressed = false;
//          if (effectState == 3) {
//            recording = false;
//            gifFrames = newGifFrames;
//            println("stop recording");      
//          }
      
        }
       }
    }
    lastButtonState = reading;
  // ARDUINO END /.
  
  // CAMERA!  
  if (effectState == 1 && pressed == true) {
      snapshot = get();
      println("snapshot");
  }
  if (effectState == 2 && pressed == true) {  
    mirrorMode = !mirrorMode;
    println("mirror: " + mirrorMode);
  }
  
  if (effectState == 3 && pressed == true && recording == false) {
    println("start recording");
    gifStartingTime = millis();
    newGifFrames = new ArrayList<PImage>();
    recording = true;  
  }

  if (effectState == 4 && pressed == true) {
    int[] userList = kinect.getUsers();
    if (userList.length > 0)
      addFireBall(userList[(int)random(userList.length)]);
      println("fireball!");
  }  
  
  if (effectState == 5 && pressed == true) {
    clear = true;
    println("clear");  
  }
  // CAMERA END /.
  
  kinect.update();  
  kpc.setDepthMapRealWorld(kinect.depthMapRealWorld()); 
  
  kpc.setKinectUserImage(kinect.userImage());
  opencv.loadImage(kpc.getImage());
  
  // get projected contours
  projectedContours = new ArrayList<ProjectedContour>();
  ArrayList<Contour> contours = opencv.findContours();
  for (Contour contour : contours) {
    if (contour.area() > 2000) {
      ArrayList<PVector> cvContour = contour.getPoints();
      ProjectedContour projectedContour = kpc.getProjectedContour(cvContour, 1.0);
      projectedContours.add(projectedContour);
    }
  }
  
  background(255); 
  if (clear == true) {
    snapshot = loadImage("blank.jpg");
    gifFrames = new ArrayList<PImage>();
    clear = false;
  }

  if (gifFrames.size() > 0) {
    if (gifForward) {
      image(gifFrames.get(gifFrameIndex), 0, 0, width, height); // SHOW      
      gifFrameIndex += 1;
      if (gifFrameIndex >= gifFrames.size()) {
        gifForward = false;
        gifFrameIndex = gifFrames.size() - 1;
      } 
    } else {  
      image(gifFrames.get(gifFrameIndex), 0, 0, width, height); // SHOW
      gifFrameIndex -= 1;
      if (gifFrameIndex < 0) {
        gifForward = true;
        gifFrameIndex = 0;
      }      
    }


  } else { // just static
    image(snapshot, 0, 0); // SHOW   
  }  
//  image(snapshot, 0, 0);
  

  
  for (int i=0; i<projectedContours.size(); i++) {
    ProjectedContour projectedContour = projectedContours.get(i);
    PGraphics pg = projectedGraphics.get(i%3);    
    beginShape();
    texture(pg);
    for (PVector p : projectedContour.getProjectedContours()) {
      PVector t = projectedContour.getTextureCoordinate(p);
      vertex(p.x, p.y, pg.width * t.x, pg.height * t.y);
    }
    endShape();
  }
  
  renderFireball(); 
  if (debugging == true) {
    drawProjectedSkeletons();
  }
  drawFireballs();  
  
  if (mirrorMode == true) {
    mirrorSnapshot = get();
    pushMatrix();
    translate(mirrorSnapshot.width,0);
    scale(-1,1);
    image(mirrorSnapshot,0,0);
    popMatrix();  
  }
 
  if (recording) {
      curr_frame = get();
      newGifFrames.add(curr_frame);
      
      // PRINT HOW MUCH TIME IT HAS PASSED FROM RECORDING EVERY SECOND
      if (millis() > gifStartingTime + 1000) {
        println(millis());
        gifRecordingTimePassed += 1;
        println("time passed: "  + gifRecordingTimePassed);
      }

      // DONE WITH RECORDING
      if (millis() > gifStartingTime + gifMaxDuration) {
        recording = false;
        gifFrames = newGifFrames;
        println("stop recording");
      }    
  }
  if (potValue < 204) {;
    image(cameraIcon, displayWidth - 120, 10);
  }
  if ((potValue >= 204) && (potValue < 409)) {
    image(mirrorIcon, displayWidth - 120, 10);
  }
  if ((potValue >= 409) && (potValue < 614)) {
    image(loopIcon, displayWidth - 120, 10);
  }
  if ((potValue >= 614) && (potValue < 819)) {
    image(fireIcon, displayWidth - 120, 10);
  }
  if ((potValue >= 819) && (potValue < 1024)) { 
    image(clearIcon, displayWidth - 120, 10);         
  }   
}

// hit the spacebar to shoot a fireball! (needs a detected skeleton)
void keyPressed() {
  if (key==' ') {
    int[] userList = kinect.getUsers();
    if (userList.length > 0)
      addFireBall(userList[(int)random(userList.length)]);
      println("fireball!");
  }
}

void drawProjectedSkeletons() {
  int[] userList = kinect.getUsers();
  for(int i=0; i<userList.length; i++) {
    if(kinect.isTrackingSkeleton(userList[i])) {
      PVector pHead = getProjectedJoint(userList[i], SimpleOpenNI.SKEL_HEAD);
      PVector pNeck = getProjectedJoint(userList[i], SimpleOpenNI.SKEL_NECK);
      PVector pTorso = getProjectedJoint(userList[i], SimpleOpenNI.SKEL_TORSO);
      PVector pLeftShoulder = getProjectedJoint(userList[i], SimpleOpenNI.SKEL_LEFT_SHOULDER);
      PVector pRightShoulder = getProjectedJoint(userList[i], SimpleOpenNI.SKEL_RIGHT_SHOULDER);
      PVector pLeftElbow = getProjectedJoint(userList[i], SimpleOpenNI.SKEL_LEFT_ELBOW);
      PVector pRightElbow = getProjectedJoint(userList[i], SimpleOpenNI.SKEL_RIGHT_ELBOW);
      PVector pLeftHand = getProjectedJoint(userList[i], SimpleOpenNI.SKEL_LEFT_HAND);
      PVector pRightHand = getProjectedJoint(userList[i], SimpleOpenNI.SKEL_RIGHT_HAND);      
      PVector pLeftHip = getProjectedJoint(userList[i], SimpleOpenNI.SKEL_LEFT_HIP);
      PVector pRightHip = getProjectedJoint(userList[i], SimpleOpenNI.SKEL_RIGHT_HIP);
      PVector pLeftKnee = getProjectedJoint(userList[i], SimpleOpenNI.SKEL_LEFT_KNEE);
      PVector pRightKnee = getProjectedJoint(userList[i], SimpleOpenNI.SKEL_RIGHT_KNEE);
      PVector pLeftFoot = getProjectedJoint(userList[i], SimpleOpenNI.SKEL_LEFT_FOOT);
      PVector pRightFoot = getProjectedJoint(userList[i], SimpleOpenNI.SKEL_RIGHT_FOOT);
      
      stroke(0, 0, 255);
      strokeWeight(16);
      line(pHead.x, pHead.y, pNeck.x, pNeck.y);
      line(pNeck.x, pNeck.y, pTorso.x, pTorso.y);
      line(pNeck.x, pNeck.y, pLeftShoulder.x, pLeftShoulder.y);
      line(pLeftShoulder.x, pLeftShoulder.y, pLeftElbow.x, pLeftElbow.y);
      line(pLeftElbow.x, pLeftElbow.y, pLeftHand.x, pLeftHand.y);
      line(pNeck.x, pNeck.y, pRightShoulder.x, pRightShoulder.y);
      line(pRightShoulder.x, pRightShoulder.y, pRightElbow.x, pRightElbow.y);
      line(pRightElbow.x, pRightElbow.y, pRightHand.x, pRightHand.y);
      line(pTorso.x, pTorso.y, pLeftHip.x, pLeftHip.y);
      line(pLeftHip.x, pLeftHip.y, pLeftKnee.x, pLeftKnee.y);
      line(pLeftKnee.x, pLeftKnee.y, pLeftFoot.x, pLeftFoot.y);
      line(pTorso.x, pTorso.y, pRightHip.x, pRightHip.y);
      line(pRightHip.x, pRightHip.y, pRightKnee.x, pRightKnee.y);
      line(pRightKnee.x, pRightKnee.y, pRightFoot.x, pRightFoot.y);   
      
      fill(255, 0, 0);
      noStroke();
      ellipse(pHead.x, pHead.y, 20, 20);
      ellipse(pNeck.x, pNeck.y, 20, 20);
      ellipse(pTorso.x, pTorso.y, 20, 20);
      ellipse(pLeftShoulder.x, pLeftShoulder.y, 20, 20);
      ellipse(pRightShoulder.x, pRightShoulder.y, 20, 20);
      ellipse(pLeftElbow.x, pLeftElbow.y, 20, 20);
      ellipse(pRightElbow.x, pRightElbow.y, 20, 20);
      ellipse(pLeftHand.x, pLeftHand.y, 20, 20);
      ellipse(pRightHand.x, pRightHand.y, 20, 20);
      ellipse(pLeftHip.x, pLeftHip.y, 20, 20);
      ellipse(pRightHip.x, pRightHip.y, 20, 20);
      ellipse(pLeftKnee.x, pLeftKnee.y, 20, 20);
      ellipse(pRightKnee.x, pRightKnee.y, 20, 20);
      ellipse(pLeftFoot.x, pLeftFoot.y, 20, 20);
      ellipse(pRightFoot.x, pRightFoot.y, 20, 20);
    }
  }
  
}

PVector getProjectedJoint(int userId, int jointIdx) {
  PVector jointKinectRealWorld = new PVector();
  PVector jointProjected = new PVector();
  kinect.getJointPositionSkeleton(userId, jointIdx, jointKinectRealWorld);
  jointProjected = kpc.convertKinectToProjector(jointKinectRealWorld);
  return jointProjected;
}

ArrayList<PGraphics> initializeProjectedGraphics() {
  ArrayList<PGraphics> projectedGraphics = new ArrayList<PGraphics>();
  for (int p=0; p<3; p++) {
    color col = color(0);
    PGraphics pg = createGraphics(800, 400, P2D);
    pg.beginDraw();
    pg.background(0);
    pg.endDraw();
    projectedGraphics.add(pg);
  }  
  return projectedGraphics;
}


//save image
void keyReleased() {
  if (key == 's' || key == 'S') {
    snapshot = get();
    println("snapshot");
  }
  if (key == 'm' || key == 'M') {
    mirrorMode = !mirrorMode;
    println("mirror: " + mirrorMode);
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

  if (key == 'r' || key == 'R') {
    println("start recording");
    gifStartingTime = millis();

    newGifFrames = new ArrayList<PImage>();
    // gifFrames = new ArrayList<PImage>(); // clean gif frames
    recording = true;
  }    
}


// -----------------------------------------------------------------
// SimpleOpenNI events -- do not need to modify these...

void onNewUser(SimpleOpenNI curContext, int userId) {
  println("onNewUser - userId: " + userId);
  curContext.startTrackingSkeleton(userId);
}

void onLostUser(SimpleOpenNI curContext, int userId) {
  println("onLostUser - userId: " + userId);
}

void onVisibleUser(SimpleOpenNI curContext, int userId) {
  println("onVisibleUser - userId: " + userId);
}
