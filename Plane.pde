// This is the code for bomber control, written by Yuxuan Huang and Jiajun Tang
// for the final project of CSCI 5611

import java.lang.Math;

String projectTitle = "Bomber";
PImage sky, bomberimg, gun, tank, truck,tanktbody,tankturrent;
Bomber B;
Bomb b;
Fort fort;
Float bullet_v=50.0; //bullet velocity
Float bomb_r=10.0;//bomb_radius
int bomber_direction; //1:fly to right, -1:fly to left
ArrayList <Car>cars;
Boolean cheat=false;

void setup() {
  size(1600, 900, P2D);
  noStroke();
  sky = loadImage("Sky.jpg");
  bomberimg = loadImage("AVG.png");
  gun = loadImage("gun.png");
  tank = loadImage("tank.png");
  truck = loadImage("truck.png");
  tanktbody=loadImage("tanktbody.png");
  tankturrent=loadImage("tankturrent.png");
  background(sky);
  init();
}

void init() {
  B = new Bomber();
  b = new Bomb(B);
  fort = new Fort(new PVector(780,920));
  cars=new ArrayList<Car>();
  
  //adding cars, caution: add from the car ont the lest to the car on the right
  cars.add(new Car(1,900,870,-5));
  cars.add(new Car(1,1040,870,-5));
  cars.add(new Car(2,1230,870,-5));
  cars.add(new Car(2,1370,870,-5));
  cars.add(new Car(2,1510,870,-5));
  cars.add(new Car(1,1670,870,-5));
  bomber_direction = 1;
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
    sens = 2.5;
    cooldown = false;
  }
  
  //make sure angle -180~+180
  public void angle_check(){
    if(angle<-180){
      angle+=360;
    }
    if(angle>180){
      angle-=360;
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
  if (B.up) {
   
    B.angle -= bomber_direction*B.sens;
    B.angle_check();
    
  }else if (B.down) {
    
    B.angle += bomber_direction*B.sens;
    B.angle_check();
    
  }
  
  B.pos.y += (5-B.health)*3/5.0;
    
  if (B.pos.y >= 880) init();   // Collision Check, Plane Crash & restart

  if (B.pos.x < -30 || B.pos.x > 1630) {//out of boder and turn back
    B.angle = (180-B.angle);
    B.angle_check();
    bomber_direction*=-1;  
  }
  if(B.pos.y<-30){
    B.angle=-B.angle;
    B.angle_check();
  }
  
  
  
  // Bomb Update
  if (B.cooldown) { // bomb dropped
    b.pos.add(PVector.mult(b.vel, dt));
    b.vel.y += (acceleration * dt);

    if (b.pos.y >= 880) B.cooldown = false;// Collision Check
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
     
      if(dis(bullet.pos,B.pos)<30.0){//hit Check
        B.health--;
        fort.bullet_list.remove(i);
        continue;
      }
  }
  
  

  //Cars update
  for(int i=0;i<cars.size();i++){
    Car car=cars.get(i);
    
    if(cheat||B.cooldown&&dis(b.pos,car.pos)<50){//hit check
      if(cheat){
        cheat=false;
      }
      car.alive=false;

      println("car is hitted");//hit
      car.t_up=true;
      car.t_vel.set(b.vel.x*0.3,b.vel.y*-1*0.2);
      car.t_pos.set(car.pos.x,car.pos.y-7.0);
      
    }
    
    if(car.alive){
      float safe_distance=108;
      if(car.type==2)safe_distance+=12;
      if(i>=1&&cars.get(i-1).type==2)safe_distance+=12;
      if(i==0||i>=1&&car.pos.x-cars.get(i-1).pos.x>safe_distance){
        
      car.pos.set(car.pos.x+car.speed*dt,car.pos.y);
      }

    }
    
  }
  
  //turrent update
  for(Car car:cars){
    if(!car.t_up){continue;}
    car.t_vel.y+=5*dt;
    car.t_pos.x+=car.t_vel.x;
    car.t_pos.y+=car.t_vel.y;
    if(car.t_pos.y>870){
      car.t_up=false;
      car.t_pos.y=870;
    }
    
  }
  
}



void drawScene(){
  
  // sky
  background(sky);
  
  // bomber
  fill(255, 0, 0);
  pushMatrix();
  translate(B.pos.x, B.pos.y);
  rotate(B.angle*PI/180.0);
  scale(0.15,0.15*bomber_direction);
  imageMode(CENTER);
  image(bomberimg, 0, 0);
  popMatrix();
  
  //bomb
  if (B.cooldown) {
    fill(0, 0, 0);
    circle(b.pos.x, b.pos.y, bomb_r);
  }
  
  
   // fort
   pushMatrix();
   translate(fort.pos.x,fort.pos.y);
   rotate((fort.angle-90)*PI/180.0);
   scale(0.5);
   imageMode(CORNER);
   image(gun, 50, -40);
   popMatrix();
   fill(0, 0, 100);
   circle(fort.pos.x,fort.pos.y,120);
   
   //bullet
   for(int i=fort.bullet_list.size()-1;i>=0;i--){
     Bullet bullet=fort.bullet_list.get(i);
     fill(0, 0, 0);
     circle(bullet.pos.x, bullet.pos.y, bomb_r);
   }
  
  // cars
  for(Car car:cars){
    
    imageMode(CENTER);
     
    if(car.type==1){
      
      if(car.alive){
        image(tank,car.pos.x, car.pos.y,250.0*0.4,88.0*0.4);
      }else{
        image(tanktbody,car.pos.x, car.pos.y+8.0,250.0*0.4,56.0*0.4);
        image(tankturrent,car.t_pos.x, car.t_pos.y,250.0*0.4,33.0*0.4);
      }
    }else if(car.type==2){
      
      image(truck,car.pos.x, car.pos.y,150.0*0.83,59.0*0.83);
    }

  
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
  if (B.health > 0){
    if (keyCode == 'W') B.up = true;
    else if (keyCode == 'S') B.down = true; //<>//
  } //<>//
  // Bomb
  if (keyCode ==   ' ' && B.cooldown == false){ // drop bomb
    B.cooldown = true;
    b = new Bomb(B);
  }
  
  if (keyCode == ESC  ) exit();
  
  if (keyCode == 'C'  ) cheat=true;
  
  if (keyCode == 'R'  ) init();
  
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

class Car{
  PVector pos;//position
  PVector t_pos;//turrent position
  float t_angle;//turrent angle
  PVector t_vel;//turrent velocity
  boolean t_up;//whether turrent is floating
  float speed;
  int type;//1 tank, 2 truck
  boolean alive;

  public Car(int type,float posx,float posy,float speed){
    this.type=type;
    pos=new PVector(posx,posy);
    this.speed=speed;
    alive=true;
    t_pos=new PVector(posx,posy);
    t_angle=0.0;
    t_vel=new PVector(0,0);
  }
  
  
}

//distance
float dis(PVector p1, PVector p2){
  return sqrt((p1.x-p2.x)*(p1.x-p2.x)+(p1.y-p2.y)*(p1.y-p2.y));
}

//length
float len(PVector p1){
  return sqrt(p1.x*p1.x+p1.y*p1.y);
}
