// This is the code for a multiplayer war game
// written by Yuxuan Huang and Jiajun Tang
// for the final project of CSCI 5611

import java.lang.Math;

String projectTitle = "Bomber";
PImage sky, bomberimg, gun, gunbase, tank, truck, tanktbody, tankturrent;
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
  gun = loadImage("gunbarrel.png");
  gunbase = loadImage("gunbase.png");
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
  pln_smk = new ptc_sys(20, 5, B.pos, new PVector(5,5), B.vel, 30); 
  fort = new Fort(new PVector(800,880));
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
    //pos.add(vel);
  }
}

// ================= class particle system ==========================
class ptc_sys{
  public ArrayList<PVector> POS; // position
  ArrayList<PVector> VEL; // velocity
  ArrayList<PVector> COL; // color
  ArrayList<Float> LIFE; // remaining life
  float gen_rate;
  float lifespan;
  PVector src_pos; // source initial position
  PVector src_dim; // source dimension
  PVector ini_vel; // initial velocity
  float ptb_angle; // ini_vel perturbation angle
  
  ptc_sys(float gr, float ls, PVector pos, PVector dim, PVector vel, float ptb){
    gen_rate = gr; //<>//
    lifespan = ls;
    src_pos = pos.copy();
    src_dim = dim.copy();
    ini_vel = vel.copy();
    ptb_angle = ptb;
    
    POS = new ArrayList<PVector>();
    VEL = new ArrayList<PVector>();
    COL = new ArrayList<PVector>();
    LIFE = new ArrayList<Float>();
  }
  
  public void Update(float dt){ // update particle system
    src_pos = B.pos;
    ini_vel = PVector.mult(B.vel, -0.5);
    spawnParticles(dt); // spawn new particles in this timestep
    DelParticles();
    for (int i = 0; i < POS.size(); i++) {
      // Update positions
      POS.get(i).x += VEL.get(i).x * dt;
      POS.get(i).y += VEL.get(i).y * dt;
      // Update velocity
      VEL.get(i).y -= 0.6;
      //COL.get(i).y = ((1 - LIFE.get(i) / lifespan) * 255);
      //println(LIFE.get(i));
      LIFE.set(i, LIFE.get(i) - dt);
    }
  }
  
  // Generate particles for a timestep
  void spawnParticles(float dt) {
    // calculate the num of particles to gen in a timestep
    float numParticles = dt * gen_rate;
    float fracPart = numParticles - int(numParticles);
    numParticles = int(numParticles);
    if (Math.random() < fracPart) {
      numParticles += 1;
    }
    for (int i = 0; i < numParticles; i++){
      //generate particles
      ParticleGen();
    }
  }
  
  // Generate a single particle
  void ParticleGen() {
    PVector p = GenPos(src_pos, src_dim);
    PVector v = GenVel(ini_vel, ptb_angle);
    PVector c = new PVector(255, 255, 255);
    float life = GenLife(lifespan);
    POS.add(p);
    VEL.add(v);
    COL.add(c);
    LIFE.add(life);
  }
  
  PVector GenPos(PVector pos, PVector dim){ // generate initial positionposition
    float x, y;
    x = pos.x + 2*dim.x*((float)Math.random()-0.5);
    y = pos.y + 2*dim.y*((float)Math.random()-0.5);
    PVector ini_pos = new PVector(x, y);
    return ini_pos;
  }
  
  PVector GenVel(PVector ref_vel, float ptb){ // generate initial velocity
    PVector ini_vel = ref_vel.copy();
    float rand1 = (float)Math.random() + 0.5;
    float rand2 = ((float)Math.random() - 0.5) * 2 * ptb;
    ini_vel.mult(rand1);
    ini_vel.rotate(rand2 * PI / 180);
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
  
  void SetGenRate(float x){
    gen_rate = x;
  }
}

// ==============================================================================

ptc_sys pln_smk;// plane smoke

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

  if (B.pos.x < -30 || B.pos.x > 1630) {//out of border and turn back
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
  
  
  // Plane Smoke Update
  if (B.health < 5){ // Plane emit smoke
    pln_smk.SetGenRate(20*(5-B.health));
    pln_smk.Update(dt);
  }
  
  
  
  //Fort update
  if(fort.right && fort.angle < 90){
    fort.angle+=fort.sens*PI/180;
  }
  if(fort.left && fort.angle > -90){
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

      println("car is hitted");//hit turrent
      car.t_up=true;
      car.t_vel.set(b.vel.x*0.15,b.vel.y*-1*0.1);
      car.t_pos.set(car.pos.x,car.pos.y-10.0);
      
    }
    
    if(car.alive){
      float safe_distance=108;
      if(car.type==2)safe_distance+=12;
      if(i>=1&&cars.get(i-1).type==2)safe_distance+=12;
      if(i==0||i>=1&&car.pos.x-cars.get(i-1).pos.x>safe_distance){
        
      car.pos.set(car.pos.x+car.speed*dt,car.pos.y);
      }

    }
    
    //turrent update
    if(car.t_up){
      car.t_vel.y+=4*dt;
      car.t_pos.x+=car.t_vel.x;
      car.t_pos.y+=car.t_vel.y;
      if(car.t_vel.x>0){
        car.t_angle+=7;
      }else{
        car.t_angle-=7;
      }
      if(car.t_pos.y>870){
        car.t_up=false;
        car.t_pos.y=870;
      }
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
  
  
  // plane smoke
  for (int i = 0; i < pln_smk.POS.size(); i++) {
    strokeWeight(5 - pln_smk.LIFE.get(i));
    stroke(0,0,0,(pln_smk.LIFE.get(i))*50);
    point(pln_smk.POS.get(i).x, pln_smk.POS.get(i).y);
  }
   
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
        
        pushMatrix();
        translate(car.t_pos.x, car.t_pos.y);
        rotate((car.t_angle)*PI/180.0);
        imageMode(CENTER);
        image(tankturrent,0, 0,250.0*0.4,33.0*0.4);
        popMatrix();
        
        
      }
    }else if(car.type==2){
      
      image(truck,car.pos.x, car.pos.y,150.0*0.83,59.0*0.83);
    }
  }

   // fort
   pushMatrix();
   translate(fort.pos.x,fort.pos.y -20);
   rotate((fort.angle-90)*PI/180.0);
   scale(0.6);
   image(gun, 0, 0);
   popMatrix();
   fill(0, 0, 100);
   imageMode(CENTER);
   pushMatrix();
   translate(fort.pos.x, fort.pos.y);
   scale(0.4);
   image(gunbase, 0, 0);
   popMatrix();
  
}


void draw() {
  //Compute the physics update
  update(0.15); 
  //Draw the scene //<>//
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
  
  if (keyCode == 'C'  ) cheat=true;
  
  if (keyCode == 'R'  ) init();
  
  if (keyCode == RIGHT  ) fort.right=true;
  
  if (keyCode == LEFT  ) fort.left=true;
  
  if(keyCode == ENTER && fort.cooldown<=0){
    
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
     pos.x += 80*sin(angle*PI/180.0);
     pos.y -= (80*cos(angle*PI/180.0)+20);
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
