import processing.video.*;
import jp.nyatla.nyar4psg.*;

Capture cam;
MultiMarker nya;
PImage eye1;
PImage eye2;

void setup() {
  eye1 = loadImage("eye1.png");
  eye2 = loadImage("eye2.png");
  size(640,480,P3D);
  colorMode(RGB, 100);
  println(MultiMarker.VERSION);  
  cam=new Capture(this,640,480);
  nya=new MultiMarker(this,width,height,"data/camera_para.dat",NyAR4PsgConfig.CONFIG_PSG);
  //nya.addARMarker("data/patt.hiro",80);//id=0
  nya.addARMarker("data/pattern-marker.patt",80);//id=0
  nya.addARMarker("data/patt.kanji",80);//id=1
  cam.start();
}

void draw()
{
  if (cam.available() !=true) {
      return;
  }
  cam.read();
  nya.detect(cam);
  background(0);
  nya.drawBackground(cam);
  for(int i=0;i<2;i++){
    if((!nya.isExist(i))){
      continue;
    }
    nya.beginTransform(i);
    //fill(0,100*(i%2),100*((i+1)%2));
    translate(0,0,20);
    //box(40);  
    image(eye1, 0, 0);
    delay(500);
    image(eye2, 0, 0); 
    nya.endTransform();
  }
}