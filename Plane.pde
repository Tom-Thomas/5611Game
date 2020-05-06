// This is the code for bomber control, written by Yuxuan Huang and Jiajun Tang
// for the final project of CSCI 5611

import java.lang.Math;

String projectTitle = "Bomber";
PImage sky, bomberimg, gun, tank, truck;
Bomber B;
Bomb b;
Fort fort;
Float bullet_v=50.0; //bullet velocity
int bomber_direction=1; //1:fly to right, -1:fly to lest

void setup() {
  size(1600, 900, P2D);
  noStroke();
  sky = loadImage("Sky.jpg");
  bomberimg = loadImage("AVG.png");
  gun = loadImage("gun.png");
  tank = loadImage("tank.png");
  truck = loadImage("truck.png");
  background(sky);
  init();
}

void init() {
  B = new Bomber();
  b = new Bomb(B);
  fort = new Fort(new PVector(780,920));
}

class Bomber{
  int health;
  float vel_mtp; // velocity multiplier
  PVector vel;
  float angle; // angle of elevation
  PVector pos = new PVector(); // position
  float sens; // sensitivity
  boolean up;
  boolean down;
  boolean cooldown; // cooldown time for bomb
  
  public Bomber(){
    health = 5;
    vel_mtp = 30;
    angle = 0;
    vel = new PVector(cos(angle*PI/180.0), sin(angle*PI/180.0)).mult(vel_mtp);
    pos.x = 0;
    pos.y = 450;
    up = false;
    down = false;
    sens = 80;
    cooldown = false;
  }
  
  //to make use the wings donot upside down
  public void angle_check(){
    if(angle<-180){
      angle+=360;
    }
    if(angle>180){
      angle-=360;
    }
    if(angle<-90||angle>90){
      bomber_direction=-1;
    }else{
      bomber_direction=1;
    }
  }
}

class Bomb{
  PVector pos = new PVector();
  PVector vel = new PVector();
  Bomb(Bomber B){
    pos = new PVector(B.pos.x, B.pos.y);
    vel = B.vel.copy();
    pos.add(vel);
  }
}

// class particle system
class ptc_sys{
  ArrayList<PVector> POS; // position
  ArrayList<PVector> VEL; // velocity
  ArrayList<PVector> COL; // color
  ArrayList<Float> LIFE; // remaining life
  float gen_rate;
  float lifespan;
  PVector srs_pos;
  
  ptc_sys(float gr, float ls, PVector pos, PVector dim, PVector vel){
    gen_rate = gr;
    lifespan = ls;
    POS = new ArrayList<PVector>();
    VEL = new ArrayList<PVector>();
    COL = new ArrayList<PVector>();
    LIFE = new ArrayList<Float>();
  }
  
  PVector GenPos(PVector pos, PVector dim){ // generate initial positionposition
    float x, y;
    x = pos.x + 2*dim.x*((float)Math.random()-0.5);
    y = pos.y + 2*dim.y*((float)Math.random()-0.5);
    PVector ini_pos = new PVector(x, y);
    return ini_pos;
  }
  
  PVector GenVel(PVector ref_vel){ // generate initial velocity
    PVector ini_vel = ref_vel.copy();
    ini_vel.x += ((float)Math.random() - 0.5);
    ini_vel.y += ((float)Math.random() - 0.5);
    return ini_vel;
  }
  
  float GenLife(float std) { // generate initial lifespan
    float life = std + (float)Math.random() * 0.5;
    return life;
  }
  
  void DelParticles() { // delete particles
    ArrayList<Integer> DelList = new ArrayList<Integer>();
    for (int i = 0; i < LIFE.size(); i++) {
      if (LIFE.get(i) < 0) {
        DelList.add(i);
      }
    }
    for (int i = DelList.size() - 1; i >= 0; i--) {
      int tmp = DelList.get(i);
      POS.remove(tmp);
      VEL.remove(tmp);
      COL.remove(tmp);
      LIFE.remove(tmp);
    }
  }
}


//Animation Principle: Separate Physical Update 
void update(float dt){
  float acceleration = 10;
  
  
  // Bomber Flight Update
  if (B.health != 0){ // Plane not destroyed
    B.vel.set(cos(B.angle*PI/180.0), sin(B.angle*PI/180.0));
    B.vel.mult(B.vel_mtp);
  }
  else{
    B.vel.y += (acceleration / 2.0 * dt);
  }
  B.pos.add(PVector.mult(B.vel, dt));
  if (B.up&&abs(B.angle+90)>40) {
    B.angle -= bomber_direction*(B.sens*PI/180.0);
    B.angle_check();
  }else if (B.down&&abs(B.angle-90)>20) {
    B.angle += bomber_direction*(B.sens*PI/180.0);
    B.angle_check();
  }
  
  B.pos.y += (5-B.health)*3/5.0;
    
  // Collision Check
  if (B.pos.y >= 880) init(); // Plane Crash & restart
  if (B.pos.x <= -150 || B.pos.x >= 1750 || B.pos.y <= -150) {//turn back
    B.angle += 180;
    B.angle_check();
  }
  
  // Bomb Update
  if (B.cooldown) { // bomb dropped
    b.pos.add(PVector.mult(b.vel, dt));
    b.vel.y += (acceleration * dt);
    // Collision Check
    if (b.pos.y >= 880) B.cooldown = false;
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
  
  // sky
  background(sky);
  
  // bomber and bomb
  fill(255, 0, 0);
  pushMatrix();
  translate(B.pos.x, B.pos.y);
  rotate(B.angle*PI/180.0);
  scale(0.15,0.15*bomber_direction);
  imageMode(CENTER);
  image(bomberimg, 0, 0);
  popMatrix();
  if (B.cooldown) {
    fill(0, 0, 0);
    circle(b.pos.x, b.pos.y, 5);
  }
  
  
   // fort and bullet

   pushMatrix();
   translate(fort.pos.x,fort.pos.y);
   rotate((fort.angle-90)*PI/180.0);
   scale(0.5);
   
   imageMode(CORNER);
   image(gun, 50, -40);
   popMatrix();
   
   fill(0, 0, 100);
   circle(fort.pos.x,fort.pos.y,120);
   
   for(int i=fort.bullet_list.size()-1;i>=0;i--){
     Bullet bullet=fort.bullet_list.get(i);
     fill(0, 0, 0);
     circle(bullet.pos.x, bullet.pos.y, 5);
   }
  
  // tank
  imageMode(CENTER);
  pushMatrix();
  translate(1000, 870);
  scale(0.3);
  image(tank,0,0);
  popMatrix();
  pushMatrix();
  translate(1300, 870);
  scale(0.55);
  image(truck,0,0);
  popMatrix();
  
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
  if (B.health > 0){
    if (keyCode == 'W') B.up = true;
    else if (keyCode == 'S') B.down = true;
  } //<>//
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
