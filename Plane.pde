// This is the code for bomber control, written by Yuxuan Huang and Jiajun Tang
// for the final project of CSCI 5611

import java.lang.Math;

String projectTitle = "Bomber";
PImage bomberimg,gun;
Bomber B;
Bomb b;
Fort fort;
Float bullet_v=50.0; //bullet velocity

void setup() {
  size(1600, 900, P2D);
  noStroke();
  bomberimg = loadImage("Bomber.png");
  gun = loadImage("gun.png");
  init();
  
}

void init() {
  B = new Bomber();
  b = new Bomb(B);
  fort = new Fort(new PVector(800,920));
}

class Bomber{
  int health;
  float vel; // velocity
  float angle; // angle of elevation
  PVector pos = new PVector(); // position
  float sens; // sensitivity
  boolean up;
  boolean down;
  boolean cooldown; // cooldown time for bomb
  
  public Bomber(){
    health = 5;
    vel = 30;
    angle = 0;
    pos.x = 0;
    pos.y = 450;
    up = false;
    down = false;
    sens = 80;
    cooldown = false;
  }
}

class Bomb{
  PVector pos = new PVector();
  PVector vel = new PVector();
  Bomb(Bomber B){
    pos = new PVector(B.pos.x, B.pos.y);
    vel = new PVector(cos(B.angle*PI/180.0), sin(B.angle*PI/180.0)).mult(B.vel);
    pos.add(vel);
  }
}


//Animation Principle: Separate Physical Update 
void update(float dt){
  float acceleration = 10;
  
  
  // Bomber Flight Update
  if (B.health > 0){ // if bomber not destroyed
    PVector v = new PVector(cos(B.angle*PI/180.0), sin(B.angle*PI/180.0));
    v.mult(B.vel);
    B.pos.add(PVector.mult(v, dt));
    if (B.up) B.angle -= (B.sens*PI/180.0);
    else if (B.down) B.angle += (B.sens*PI/180.0);
    // Collision Check
    if (B.pos.y >= 900) B.health = 0;
  }
  else init(); // Restart
  
  // Bomb Update
  if (B.cooldown) { // bomb dropped
    b.pos.add(PVector.mult(b.vel, dt));
    b.vel.y += (acceleration * dt);
    // Collision Check
    if (b.pos.y >= 900) B.cooldown = false;
  }
  
  //Fort update
  if(fort.right){
    fort.angle+=fort.sens*PI/180;
  }
  if(fort.left){
    fort.angle-=fort.sens*PI/180;
  }
  fort.cooldown-=dt;
  if(fort.cooldown<0){
    fort.cooldown=0;
  }
  
  //Fort bullet update
  for(int i=fort.bullet_list.size()-1;i>=0;i--){
     Bullet bullet=fort.bullet_list.get(i);
     bullet.pos.x+=bullet_v*dt*sin(bullet.angle*PI/180.0);
     bullet.pos.y-=bullet_v*dt*cos(bullet.angle*PI/180.0);
     if(bullet.pos.x<0||bullet.pos.x>1600||bullet.pos.y<0){
       fort.bullet_list.remove(i);
       continue;
     }
     //hit Check
      if(dis(bullet.pos,B.pos)<30.0){
        B.health--;
        fort.bullet_list.remove(i);
        continue;
      }
  }
  
}



void drawScene(){
  background(255,255,255);
  //bomber and bomb
  fill(255, 0, 0);
  pushMatrix();
  translate(B.pos.x, B.pos.y);
  rotate(B.angle*PI/180.0);
  //triangle(-15, 0, -15, 10, 15, 10); // temp triangle representation of bomber
  scale(0.1);
  image(bomberimg, 0, 0);
  popMatrix();
  if (B.cooldown) {
    fill(0, 0, 0);
    circle(b.pos.x, b.pos.y, 5);
  }
  
  
   //fort and bullet
   
   
   
   pushMatrix();
   translate(fort.pos.x,fort.pos.y);
   rotate((fort.angle-90)*PI/180.0);
   scale(0.5);
   
   image(gun, 50, -40);
   popMatrix();
   
   fill(0, 0, 100);
   circle(fort.pos.x,fort.pos.y,120);
   
   for(int i=fort.bullet_list.size()-1;i>=0;i--){
     Bullet bullet=fort.bullet_list.get(i);
     fill(0, 0, 0);
     circle(bullet.pos.x, bullet.pos.y, 5);
   }
  
}


void draw() {
  //Compute the physics update
  update(0.15); 
  //Draw the scene
  drawScene();
  
  surface.setTitle(projectTitle);
}



// bomber control
void keyPressed()
{
  // Bomber
  if (keyCode == 'W') B.up = true; //<>//
  else if (keyCode == 'S') B.down = true;
  // Bomb
  if (keyCode ==   ' ' && B.cooldown == false){ // drop bomb
    B.cooldown = true;
    b = new Bomb(B);
  }
  
  if (keyCode == ESC  ) exit();
  
  if (keyCode == RIGHT  ) fort.right=true;
  
  if (keyCode == LEFT  ) fort.left=true;
  
  if(keyCode == ENTER&&fort.cooldown<=0){
    
    fort.bullet_list.add(new Bullet(fort.pos.x,fort.pos.y,fort.angle));
    fort.cooldown+=30;
  }
  
  
}

void keyReleased(){
  if (keyCode == 'W') B.up = false;
  else if (keyCode == 'S') B.down = false;
  
    
  if (keyCode == RIGHT  ) fort.right=false;
  
  if (keyCode == LEFT  ) fort.left=false;
}


class Fort{
  int health;
  
  float angle; // angle of gun
  PVector pos = new PVector(); // position
  float sens; // sensitivity
  boolean left;
  boolean right;
  int cooldown; // cooldown time for gun
  ArrayList<Bullet> bullet_list;
  
  public Fort(PVector p){
    health = 5;
    
    angle = 0;//up
    pos.x = p.x;
    pos.y = p.y;
    left = false;
    right = false;
    sens = 40;
    cooldown = 0;
    bullet_list=new ArrayList<Bullet>();
  }
  
}

class Bullet{
   PVector pos = new PVector();
   float angle;
   
   public Bullet(float x,float y,float angle1){
     pos.x=x;
     pos.y=y;
     angle=angle1;
     pos.x+=170*sin(angle*PI/180.0);
     pos.y-=170*cos(angle*PI/180.0);
   }
   
}

//distance
float dis(PVector p1, PVector p2){
  return sqrt((p1.x-p2.x)*(p1.x-p2.x)+(p1.y-p2.y)*(p1.y-p2.y));
}
