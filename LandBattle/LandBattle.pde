// This is the code for a multiplayer war game
// written by Yuxuan Huang and Jiajun Tang
// for the final project of CSCI 5611

import java.lang.Math;

String projectTitle = "Field Battle";
PImage sky, bomberimg, gun, gunbase, tank, truck, tanktbody, tankturrent;
Bomber B;
Bomb b;
Fort fort;
Float bullet_v=100.0; //bullet velocity
Float bomb_r=10.0;//bomb_radius
int bomber_direction; //1:fly to right, -1:fly to left
ArrayList <Car>cars;
Boolean cheat=false;
PVector explosion_area;
float countdown; // countdown before game ends

void setup() {
  size(1600, 900, P2D);
  noStroke();
  sky = loadImage("../Images/Sky.jpg");
  bomberimg = loadImage("../Images/AVG.png");
  gun = loadImage("../Images/gunbarrel.png");
  gunbase = loadImage("../Images/gunbase.png");
  tank = loadImage("../Images/tank.png");
  truck = loadImage("../Images/truck.png");
  tanktbody=loadImage("../Images/tanktbody.png");
  tankturrent=loadImage("../Images/tankturrent.png");
  background(sky);
  init();
}

void init() {
  B = new Bomber();
  b = new Bomb(B);
  fort = new Fort(new PVector(800,880));
  pln_smk = new ptc_sys(0, 5, B.pos, new PVector(5,5), B.vel, 30);
  spark = new ptc_sys(0, 5, B.pos, new PVector(5,5), B.vel, 30);
  expl_m = new ptc_sys(0, 5, B.pos, new PVector(5,5), B.vel, 30);
  expl_h = new ptc_sys(0, 5, B.pos, new PVector(5,5), B.vel, 30);
  fort_smk = new ptc_sys(0, 20, fort.pos, new PVector(10,5), new PVector(0, -5), 60);
  car_flm = new ArrayList<ptc_sys>();
  car_smk = new ArrayList<ptc_sys>();
  cars=new ArrayList<Car>();
  explosion_area=new PVector(0,0);
  
  //adding cars, caution: add from the car ont the lest to the car on the right
  cars.add(new Car(1,900,870,-5));
  cars.add(new Car(1,1040,870,-5));
  cars.add(new Car(2,1230,870,-5));
  cars.add(new Car(2,1370,870,-5));
  cars.add(new Car(2,1510,870,-5));
  cars.add(new Car(1,1670,870,-5));
  bomber_direction = 1;
  countdown = 12;
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
  //ArrayList<PVector> COL; // color
  ArrayList<Float> LIFE; // remaining life
  float gen_rate;
  float lifespan;
  PVector src_pos; // source initial position
  PVector src_dim; // source dimension
  PVector ini_vel; // initial velocity
  float ptb_angle; // ini_vel perturbation angle
  
  ptc_sys(float gr, float ls, PVector pos, PVector dim, PVector vel, float ptb){
    gen_rate = gr;
    lifespan = ls;
    src_pos = pos.copy();
    src_dim = dim.copy();
    ini_vel = vel.copy();
    ptb_angle = ptb;
    
    POS = new ArrayList<PVector>();
    VEL = new ArrayList<PVector>();
    //COL = new ArrayList<PVector>();
    LIFE = new ArrayList<Float>();
  }
  
  public void Update(float dt, boolean track, boolean expl, boolean smk){ // update particle system
    if (track){
      src_pos = B.pos;
      ini_vel = PVector.mult(B.vel, -0.5);
    }
    if (!expl) spawnParticles(dt); // spawn new particles in this timestep
    DelParticles();
    for (int i = 0; i < POS.size(); i++) {
      // Update positions
      POS.get(i).x += VEL.get(i).x * dt;
      POS.get(i).y += VEL.get(i).y * dt;
      // Update velocity
      //if (expl) VEL.get(i).y += 10;
      //else 
      if (!smk) VEL.get(i).y -= 0.6;
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
    //PVector c = new PVector(255, 255, 255);
    float life = GenLife(lifespan);
    POS.add(p);
    VEL.add(v);
    //COL.add(c);
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
      //COL.remove(tmp);
      LIFE.remove(tmp);
    }
  }
  
  void SetGenRate(float x){
    gen_rate = x;
  }
}

// ==============================================================================

ptc_sys pln_smk; // plane smoke
ptc_sys spark; // spark when the plane is hit
ptc_sys fort_smk; // fort smoke
ptc_sys expl_m; // explosion missed
ptc_sys expl_h; // explosion hit

ArrayList<ptc_sys> car_flm; // car flame
ArrayList<ptc_sys> car_smk; // car smoke



// ============================== Update ==================================== 
void update(float dt){
  float acceleration = 10;
  
  if (B.health < 0 || (fort.health <= 0)) countdown-=dt;
  if (countdown <= 0) {
    countdown = 12;
    init();
  }
    
  
  // Bomber Flight Update
  if (B.health > 0){ // Plane not destroyed
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
    
  if (B.pos.y >= 880 && B.health >= 0) {   // Collision Check, Plane Crash & explode
      expl_h = new ptc_sys(500, 8, new PVector(B.pos.x,880), new PVector(10,2) // spawn explosion
        , new PVector(0, -5), 80);
      expl_h.spawnParticles(dt);
      B.health = -100;
  };

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

    if (b.pos.y >= 880) {// ground Collision Check
      B.cooldown = false;
      //b.pos.set(0,0);
      expl_m = new ptc_sys(1000, 8, new PVector(b.pos.x,880), new PVector(10,2) // spawn explosion
        , new PVector(0, -5), 80);
      expl_m.spawnParticles(dt);
    }
  }
  
  
  //Smoke Update
  if (B.health < 5){ // Plane emit smoke
    if (B.health >= 0)
    {
      pln_smk.SetGenRate(10*(5-B.health)+10);
      pln_smk.Update(dt, true, false, true);      
    }
    else pln_smk.Update(dt, false, true, false);
  }
  spark.Update(dt, false, true, false); // spark when plane is hit
  expl_h.Update(dt, false, true, false); // explosion when hit
  expl_m.Update(dt, false, true, false); // explosion when miss
  if (fort.health < 5){ // Fort emit smoke
    fort_smk.SetGenRate(40);
    fort_smk.Update(dt, false, false, true);
  }
  for (ptc_sys flm:car_flm){ // car flame
    flm.Update(dt, false, false, false);
  }
  for (ptc_sys smk:car_smk){ // car smoke
    smk.Update(dt, false, false, true);
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
  if(fort.health>0&&B.cooldown&&b.pos.y>850&&dis(b.pos,fort.pos)<40.0){//bomb hit fort 
    fort.health--;
    B.cooldown = false;
    explosion_area.set(b.pos.x,b.pos.y);
    //b.pos.set(0,0);
    
    expl_h = new ptc_sys(500, 8, new PVector(b.pos.x,880), new PVector(10,2) // spawn explosion
        , new PVector(0, -5), 80);
    expl_h.spawnParticles(dt);
    
    //println("bomb hit fort "+b.vel.x*0.15+" "+b.vel.y*(-1)*0.2);
    if(fort.health<=0){
    //fort dead
    fort.g_up=true;
    fort.g_vel.set(b.vel.x*0.15,b.vel.y*(-1)*0.2);
    fort.g_pos.set(fort.pos.x,fort.pos.y-20.0);
    fort.g_ang_ver=7.0;
    if(fort.g_vel.x<0){
       fort.g_ang_ver=-7.0;
     }
  }

  }
  
  
  
  
  //Fort's bullet update
  for(int i=fort.bullet_list.size()-1;i>=0;i--){
     Bullet bullet=fort.bullet_list.get(i);
     bullet.pos.x+=bullet_v*dt*sin(bullet.angle*PI/180.0);
     bullet.pos.y-=bullet_v*dt*cos(bullet.angle*PI/180.0);
     if(bullet.pos.x<0||bullet.pos.x>1600||bullet.pos.y<0){
       fort.bullet_list.remove(i);
       continue;
     }
     
      if(dis(bullet.pos,B.pos)<30.0){//bullet hit bomber 
        B.health--;
        spark = new ptc_sys(500, 2, bullet.pos, new PVector(2,2) // spawn spark
        , new PVector(0, -5), 180);
        spark.spawnParticles(dt);
        fort.bullet_list.remove(i);
        continue;
      }
      
      
  }
  
  

  //Cars update
  for(int i=0;i<cars.size();i++){
    Car car=cars.get(i);
    
    boolean in_explosion_area=false;
    if(explosion_area.y>850&&dis(explosion_area,car.pos)<(car.type==1?50:60)){
      in_explosion_area=true;
    }
    if(car.alive&&(in_explosion_area|| b.pos.y>850&&(B.cooldown&&dis(b.pos,car.pos)<(car.type==1?50:60)))){//bomb hit car
      car.alive=false;
      println("car is hitted"+b.vel.x*0.15+"  "+b.vel.y*(-1)*0.2);//hit turrent
      B.cooldown = false;
      //b.pos.set(0,0);
      
      expl_h = new ptc_sys(500, 8, new PVector(b.pos.x,880), new PVector(10,2) // spawn explosion
        , new PVector(0, -5), 80);
      expl_h.spawnParticles(dt);
      
      if(explosion_area.y>850){
        in_explosion_area=false;
        explosion_area.set(0,0);
      }
      PVector flm_pos = car.pos.copy();
      if (car.type == 1){ // tank
        flm_pos.y = 870;
        flm_pos.x += 10;
        car_flm.add(new ptc_sys(50, 5, flm_pos, new PVector(20, 1),new PVector(0, -1),60));
        flm_pos.y -= 20;
        car_smk.add(new ptc_sys(30, 10, flm_pos, new PVector(20, 5),new PVector(0, -5),60));
        
        car.t_up=true;
        car.t_vel.set(b.vel.x*0.15,b.vel.y*(-1)*0.2);
        car.t_pos.set(car.pos.x,car.pos.y-10.0);
        car.t_ang_ver=7.0;
        if(car.t_vel.x<0){
          car.t_ang_ver=-7.0;
        }
      }
      else{//truck
        flm_pos.y = 850;
        car_flm.add(new ptc_sys(50, 5, flm_pos, new PVector(30, 2),new PVector(0, -1),60));   
        flm_pos.y -= 20;
        car_smk.add(new ptc_sys(30, 10, flm_pos, new PVector(30, 5),new PVector(0, -5),60));
        
        //truck swing
        car.t_ang_ver=2;
      }

      
      
      //test
      /*
      if(abs(car.t_vel.x)<2){
        car.t_vel.x=-2;
      }
      if(car.t_vel.y>-12){
        car.t_vel.y=-12;
      }
      */
      
      
      
    }//end hit check
    
    if(car.alive){
      float safe_distance=108;
      if(car.type==2)safe_distance+=12;
      if(i>=1&&cars.get(i-1).type==2)safe_distance+=12;
      if(i==0||i>=1&&car.pos.x-cars.get(i-1).pos.x>safe_distance){
        
      car.pos.set(car.pos.x+car.speed*dt,car.pos.y);
      }
    }
    
    if(!car.alive&&car.type==2){//truck swing
      if(abs(car.t_angle)>1.9){//trun back
        car.t_ang_ver=car.t_ang_ver*(-0.5);
        if(car.t_angle>0) car.t_angle=2;
        else car.t_angle=-2;
      }
      if(abs(car.t_ang_ver)>0.2||abs(car.t_angle)>0.2){//swing
        car.t_angle=car.t_angle+car.t_ang_ver;
      }
      
    }
    
    //turrent update
    if(car.t_up){ 
      
      PVector p1=new PVector(car.t_pos.x-(car.t_center+1)*50*cos(car.t_angle*PI/180), car.t_pos.y-(car.t_center+1)*50*sin(car.t_angle*PI/180));//left end of the rod
      PVector p2=new PVector(car.t_pos.x+(0.72-car.t_center)*50*cos(car.t_angle*PI/180), car.t_pos.y+(0.72-car.t_center)*50*sin(car.t_angle*PI/180));//right end of the rod
      
      car.t_angle+=car.t_ang_ver;
           
      if(!car.t_flip){
        car.t_vel.y+=4*dt;
        car.t_pos.x+=car.t_vel.x;//missing dt here
        car.t_pos.y+=car.t_vel.y;//missing dt here
        
        if(p1.y>880&&p2.y<880){//left end hit ground
          car.t_flip=true;
          car.t_center=-1;
          car.t_vel.set(0,0);
          car.t_pos.set(p1.x,p1.y);
          car.t_ang_ver*=0.72/1.72;
        }else if(p2.y>880&&p1.y<880){//right end hit ground
          car.t_flip=true;
          car.t_center=0.72;
          car.t_vel.set(0,0);
          car.t_pos.set(p2.x,p2.y);
          car.t_ang_ver*=1.0/1.72;
        }
      }
      
      if(car.t_flip){
        if(abs(p1.y-p2.y)<2&&abs(car.t_ang_ver)<0.2){
          car.t_flip=false;
          car.t_up=false;
          car.t_ang_ver=0;
        }
        //gravity cause angel verlocity acceleration 
        float left_height=p1.x<p2.x?p1.y:p2.y;
        float right_height=p1.x>p2.x?p1.y:p2.y;
        if(abs(left_height-right_height)>2){//swing
          car.t_ang_ver+=left_height>right_height?0.05:-0.05;
        }
        
        if(car.t_center<0&&p2.y>880){//while left end is on the ground,right end hit ground
          if(p1.x<p2.x&&car.t_ang_ver>0||p1.x>p2.x&&car.t_ang_ver<0){//make sure p2 is going down
            car.t_center=0.72; 
            car.t_pos.set(p2.x,p2.y);
            car.t_ang_ver*=0.5;
          }
        }else if(car.t_center>0&&p1.y>880){//while right end is on the ground,,left end hit ground
           if(p1.x>p2.x&&car.t_ang_ver>0||p1.x<p2.x&&car.t_ang_ver<0){//make sure p1 is going down
            car.t_center=-1;
            car.t_pos.set(p1.x,p1.y);
            car.t_ang_ver*=0.05;
           }
        }
      }//end flip
    }//end turrent update
    
    //fort's gun update
      if(fort.g_up){ 
      
      PVector p1=new PVector(fort.g_pos.x-(fort.g_center-(-1.5))*50*cos((fort.angle+90)*PI/180), fort.g_pos.y-(fort.g_center-(-1.5))*50*sin((fort.angle+90)*PI/180));//left end of the rod
      PVector p2=new PVector(fort.g_pos.x+(0.5-fort.g_center)*50*cos((fort.angle+90)*PI/180), fort.g_pos.y+(0.5-fort.g_center)*50*sin((fort.angle+90)*PI/180));//right end of the rod
      
      float local_dt=0.20;
      fort.angle+=fort.g_ang_ver*local_dt;//missing dt here
           
      if(!fort.g_flip){
        fort.g_vel.y+=4*dt*local_dt;//having dt here
        fort.g_pos.x+=fort.g_vel.x*local_dt;//missing dt here
        fort.g_pos.y+=fort.g_vel.y*local_dt;//missing dt here
        
        if(fort.g_vel.y>0&&p1.y>880&&p2.y<880){//left end hit ground
          fort.g_flip=true;
          fort.g_center=-1.5;
          fort.g_vel.set(0,0);
          fort.g_pos.set(p1.x,p1.y);
          fort.g_ang_ver*=0.5/2.0;
        }else if(fort.g_vel.y>0&&p2.y>880&&p1.y<880){//right end hit ground
          fort.g_flip=true;
          fort.g_center=0.5;
          fort.g_vel.set(0,0);
          fort.g_pos.set(p2.x,p2.y);
          fort.g_ang_ver*=1.5/2.0;
        }
      }
      
      if(fort.g_flip){
        if(abs(p1.y-p2.y)<2&&abs(fort.g_ang_ver)<0.2){
          fort.g_flip=false;
          fort.g_up=false;
          fort.g_ang_ver=0;
        }
        //gravity cause angel verlocity acceleration 
        float left_height=p1.x<p2.x?p1.y:p2.y;
        float right_height=p1.x>p2.x?p1.y:p2.y;
        if(abs(left_height-right_height)>2){//swing
          fort.g_ang_ver+=left_height>right_height?0.05:-0.05;
        }
        
        if(fort.g_center<0&&p2.y>880){//while left end is on the ground,right end hit ground
          if(p1.x<p2.x&&fort.g_ang_ver>0||p1.x>p2.x&&fort.g_ang_ver<0){//make sure p2 is going down
            fort.g_center=0.5; 
            fort.g_pos.set(p2.x,p2.y);
            fort.g_ang_ver*=0.5;
          }
        }else if(fort.g_center>0&&p1.y>880){//while right end is on the ground,,left end hit ground
           if(p1.x>p2.x&&fort.g_ang_ver>0||p1.x<p2.x&&fort.g_ang_ver<0){//make sure p1 is going down
            fort.g_center=-1.5;
            fort.g_pos.set(p1.x,p1.y);
            fort.g_ang_ver*=0.5;
           }
        }
      }
    }//end fort's gun update
    
    
      
  }
  
  

  
}

// =========================== Draw Scene ========================

void drawScene(){
  
  println(round(frameRate));
  
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
    noStroke();
    fill(0, 0, 0);
    circle(b.pos.x, b.pos.y, bomb_r);
  }
  
  
  // plane smoke and spark
  for (int i = 0; i < pln_smk.POS.size(); i++) {
    float lf = pln_smk.LIFE.get(i);
    float clr = 50*B.health;
    strokeWeight(15 - 2*lf);
    stroke(clr,clr,clr,lf*50);
    point(pln_smk.POS.get(i).x, pln_smk.POS.get(i).y);
  }
  for (int i = 0; i < spark.POS.size(); i++) {
    strokeWeight(2);
    stroke(255,125*spark.LIFE.get(i),0, 80);
    point(spark.POS.get(i).x, spark.POS.get(i).y);
  }

  // car flame and smoke
  for (ptc_sys smk:car_smk){
    for (int i = 0; i < smk.POS.size(); i++) {
      //strokeWeight(7 - smk.LIFE.get(i));
      strokeWeight(20 - 0.5*smk.LIFE.get(i));
      stroke(0,0,0,(smk.LIFE.get(i))*10);
      point(smk.POS.get(i).x, smk.POS.get(i).y);
    }
  }
  for (ptc_sys flm:car_flm){
    for (int i = 0; i < flm.POS.size(); i++) {
      strokeWeight(10 - flm.LIFE.get(i));
      stroke(255,(flm.LIFE.get(i))*50,0,(flm.LIFE.get(i))*50);
      point(flm.POS.get(i).x, flm.POS.get(i).y);
    }
  }
  noStroke();
   
   //bullet
   for(int i=fort.bullet_list.size()-1;i>=0;i--){
     Bullet bullet=fort.bullet_list.get(i);
     fill(0, 0, 0);
     circle(bullet.pos.x, bullet.pos.y, bomb_r);
   }
  
  // cars
  for(Car car:cars){
    
    imageMode(CENTER);
     
    if(car.type==1){//tank
      
      if(car.alive){
        image(tank,car.pos.x, car.pos.y,250.0*0.4,88.0*0.4);
      }else{
        image(tanktbody,car.pos.x, car.pos.y+8.0,250.0*0.4,56.0*0.4);
        
        //turrent
        pushMatrix();
        translate(car.t_pos.x-car.t_center*50*cos(car.t_angle*PI/180), car.t_pos.y-car.t_center*50*sin(car.t_angle*PI/180));
        rotate((car.t_angle)*PI/180.0);
        imageMode(CENTER);
        image(tankturrent,0, 0,250.0*0.4,33.0*0.4);
        popMatrix();
        
        //test ends
        /*
        fill(255, 0, 0);
        circle(car.t_pos.x-(car.t_center+1)*50*cos(car.t_angle*PI/180), car.t_pos.y-(car.t_center+1)*50*sin(car.t_angle*PI/180),5);
        fill(0, 255, 255);
        circle(car.t_pos.x+(0.72-car.t_center)*50*cos(car.t_angle*PI/180), car.t_pos.y+(0.72-car.t_center)*50*sin(car.t_angle*PI/180),5);
        */
        
        
      }
    }else if(car.type==2){//truck
      pushMatrix();
      translate(car.pos.x,car.pos.y);
      rotate((car.t_angle)*PI/180.0);
      imageMode(CENTER);
      image(truck,0, 0,150.0*0.83,59.0*0.83);
      popMatrix();
    }
  }

   // fort
   if(fort.health>0){
     pushMatrix();
     translate(fort.pos.x,fort.pos.y -20);
     rotate((fort.angle-90)*PI/180.0);
     scale(0.6);
     image(gun, 0, 0);
     popMatrix();
   }else{
     //gun in the air
        pushMatrix();
        translate(fort.g_pos.x-fort.g_center*50*cos((fort.angle+90)*PI/180), fort.g_pos.y-fort.g_center*50*sin((fort.angle+90)*PI/180));
        rotate((fort.angle-90)*PI/180.0);
        imageMode(CENTER);
        scale(0.6);
        image(gun,0, 0);
        popMatrix();
        
        //test ends
        
        fill(255, 0, 0);
        circle(fort.g_pos.x-(fort.g_center-(-1.5))*50*cos((fort.angle+90)*PI/180), fort.g_pos.y-(fort.g_center-(-1.5))*50*sin((fort.angle+90)*PI/180),5);
        fill(0, 255, 255);
        circle(fort.g_pos.x+(0.5-fort.g_center)*50*cos((fort.angle+90)*PI/180), fort.g_pos.y+(0.5-fort.g_center)*50*sin((fort.angle+90)*PI/180),5);
        
   } 
   
   fill(0, 0, 100);
   imageMode(CENTER);
   pushMatrix();
   translate(fort.pos.x, fort.pos.y);
   scale(0.4);
   image(gunbase, 0, 0);
   popMatrix();

    // fort smoke
    for (int i = 0; i < fort_smk.POS.size(); i++) {
      float lf = fort_smk.LIFE.get(i);
      float clr = 50*fort.health;
      strokeWeight(20 - lf);
      stroke(clr,clr,clr,20);
      //stroke(200,200,200,80);
      point(fort_smk.POS.get(i).x, fort_smk.POS.get(i).y);
    }
   
   //test
   if(cheat){
   stroke(255,0,0);
   noFill();
   circle(fort.pos.x,fort.pos.y,80);
   circle(B.pos.x,B.pos.y,60);
   for(Car car:cars){
     circle(car.pos.x,car.pos.y,(car.type==1?100:120));
   }
   stroke(255,0,0);
   line(0,850,1600,850);
   }

  for (int i = 0; i < expl_h.POS.size(); i++) { // explosion
    strokeWeight(10);
    stroke(255,30*expl_h.LIFE.get(i),0, expl_h.LIFE.get(i)*20);
    point(expl_h.POS.get(i).x, expl_h.POS.get(i).y);
  }
  for (int i = 0; i < expl_m.POS.size(); i++) { // explosion
    strokeWeight(10);
    stroke(100,100,100, expl_m.LIFE.get(i)*20);
    point(expl_m.POS.get(i).x, expl_m.POS.get(i).y);
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
    else if (keyCode == 'S') B.down = true;
  } //<>//
  // Bomb
  if (keyCode ==   ' ' && B.cooldown == false){ // drop bomb
    B.cooldown = true;
    b = new Bomb(B);
  }
  
  if (keyCode == ESC  ) exit();
  
  if (keyCode == 'C'  ) {
    cheat=(cheat==false);
    fort.health=0;
    fort.g_up=true;
    fort.g_vel.set(-4.5,-18.9);
    fort.g_pos.set(fort.pos.x,fort.pos.y-20.0);
    fort.g_ang_ver=7.0;
    if(fort.g_vel.x<0){
       fort.g_ang_ver=-7.0;
     }
  }
  
  if (keyCode == 'R'  ) init();
  
  if(fort.health>0){
    if (keyCode == RIGHT  ) fort.right=true;
    else if (keyCode == LEFT  ) fort.left=true;
    
    if(keyCode == ENTER && fort.cooldown<=0){
      fort.bullet_list.add(new Bullet(fort.pos.x,fort.pos.y,fort.angle));
      fort.cooldown+=30;
    }
  }

  

  
  
}

void keyReleased(){
  if (keyCode == 'W') B.up = false;
  else if (keyCode == 'S') B.down = false;
  
    
  if (keyCode == RIGHT  ) fort.right=false;
  
  else if (keyCode == LEFT  ) fort.left=false;
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
  
  PVector g_pos;//gun position
  PVector g_vel;//gun velocity
  boolean g_up=false;//whether gun is moving
  boolean g_flip=false;//whether gun is flipping on the ground
  float g_ang_ver;//gun angle velocity
  float g_center;//rotate center -1~+0.72
  
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
    g_pos=p.copy();
    g_vel=new PVector(0,0);
    g_ang_ver=0;
    g_center=0;
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
  boolean t_up=false;//whether turrent is moving
  boolean t_flip=false;//whether turrent is flipping on the ground
  float t_ang_ver;//turrent angle velocity
  float t_center;//rotate center -1~+0.72
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
    t_ang_ver=0.0;
    t_center=0;
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
