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

boolean debugging = true;

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

void setup()
{
  size(displayWidth, displayHeight, P2D); 

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
}

void draw(){  
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
      if (gifFrameIndex == gifFrames.size()) {
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

  PImage cameraIcon = loadImage("camera_icon.png");
  image(cameraIcon, displayWidth - 450, 10);
  
  PImage tencameraIcon = loadImage("10_camera_icon.png");
  image(tencameraIcon, displayWidth - 350, 10);

  PImage mirrorIcon = loadImage("mirror_icon.png");
  image(mirrorIcon, displayWidth - 250, 10);

  PImage clearIcon = loadImage("clear_icon.png");
  image(clearIcon, displayWidth - 150, 10); 
 
  if (recording) {
      curr_frame = opencvCropped.getSnapshot();
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
