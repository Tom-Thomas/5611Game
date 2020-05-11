// Multiplayer War Game Naval version
// Written by Yuxuan Huang and Jiajun Tang
// for CSCI 5611 Final Project
import java.lang.Math;
import ddf.minim.*;

String projectTitle = "Naval battle";

PImage sky, bomberimg, ship1, tpt, bullet_img;
Bomber B;
Bomb b;
Ship S;
Float bomb_r=10.0;//bomb_radius
int bomber_direction; //1:fly to right, -1:fly to left
float countdown; // countdown before game ends
Minim minim=new Minim(this);
AudioPlayer player;

Float bullet_v=100.0; //bullet velocity

float g = 10;

int n = 100;
float dx = 0.1;
float[] h = new float[n];
float[] uh = new float[n];

float totlen = n*dx;
float[] hm = new float[n];
float[] uhm = new float[n];

// Create Window
void setup() {
  size(1600, 900, P2D);
  player = minim.loadFile("../Sound/bomb.wav");
  noStroke();
  sky = loadImage("../Images/sky_bkg.jpg");
  bomberimg = loadImage("../Images/AVG.png");
  ship1 = loadImage("../Images/Battleship.png");
  tpt=loadImage("../Images/tpt1.png");
  bullet_img=loadImage("../Images/bullet.png");
  init();
}

// Initialization
void init(){
  B = new Bomber();
  b = new Bomb(B);
  S = new Ship(800, 845);
  bomber_direction = 1;
  pln_smk = new ptc_sys(0, 5, B.pos, new PVector(5,5), B.vel, 30);
  spark = new ptc_sys(0, 5, B.pos, new PVector(5,5), B.vel, 30);
  expl_m = new ptc_sys(0, 5, B.pos, new PVector(5,5), B.vel, 30);
  expl_h = new ptc_sys(0, 5, B.pos, new PVector(5,5), B.vel, 30);  
  ship_smk = new ptc_sys(0, 10, new PVector(S.pos.x, 835) , new PVector(50,2), new PVector(0, -5), 60);
  for (int i = 0; i < n; i++){ // initialize sea
    h[i] = 1;
    uh[i] = 0;
    hm[i] = 0;
    uhm[i] = 0;
  }
  countdown = 20;
}


// Shallow water update
void waveEquation(float dt){
  // halfstep
  for(int i = 0; i < n-1; i++){
    hm[i] = (h[i] + h[i+1])/2.0 - (dt/2.0)*(uh[i+1]-uh[i])/dx;
    uhm[i] = (uh[i] + uh[i+1])/2.0 - (dt/2.0)*
    ((uh[i+1]*uh[i+1])/h[i+1] + 0.5*g*(h[i+1]*h[i+1]) -
    (uh[i]*uh[i])/h[i] - 0.5*g*(h[i]*h[i]))/dx;
  }
  // fullstep
  float damp = 0.1;
  for(int i = 0; i < n-2; i++){
    h[i+1] -= dt*(uhm[i+1]-uhm[i])/dx;
    uh[i+1] -= dt*(damp*uh[i+1] + 
    (uhm[i+1]*uhm[i+1])/hm[i+1] + 0.5*g*(hm[i+1]*hm[i+1]) - 
    (uhm[i]*uhm[i])/hm[i] - 0.5*g*(hm[i]*hm[i]))/dx;
  }
  // boundary conditions (Free)
  h[0] = h[1];
  h[h.length-1] = h[h.length-2];
  uh[0] = uh[1];
  uh[uh.length-1] = -uh[uh.length-2];
}


// ===================== General Update Function ====================

void update(float dt){
  
  if (B.health < 0 || S.health <= 0) countdown-=dt;
  if (countdown <= 0) {
    countdown = 20;
    init();
  }  
  
  // Bomber Update
  if (B.health > 0){ // Plane not destroyed
    B.vel.set(cos(B.angle*PI/180.0), sin(B.angle*PI/180.0));
    B.vel.mult(B.vel_mtp);
  }
  else{
    B.vel.y += (g / 2.0 * dt);
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
    
  if (B.pos.y >= 845 && B.health >= -10) {   // Collision Check, Plane Crash & explode
      expl_h = new ptc_sys(2000, 8, new PVector(B.pos.x,840), new PVector(10,2) // spawn explosion
        , new PVector(0, -5), 80);
      expl_h.spawnParticles(dt);
      
      float dis = B.pos.x - S.pos.x;
      if (dis < -1 * S.hlen || dis > S.hlen){ // not hit ship
        expl_m = new ptc_sys(2000, 8, new PVector(B.pos.x,850), new PVector(10,2) // spawn explosion
        , new PVector(0, -40), 10);
        expl_m.spawnParticles(dt);
        player = minim.loadFile("../Sound/hit.wav");
        player.play();         
      }
      else {
        S.health -= 3;
        player = minim.loadFile("../Sound/hit.wav");
        player.play();        
      }
      if (B.pos.x >= 0 && B.pos.x <= 1600) uh[(int)(n*B.pos.x/1600)] = 3;
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
    b.vel.y += (g * dt);

    if (b.pos.y >= 845) {// ground Collision Check
      B.cooldown = false;     
      //b.pos.set(0,0);
      float dis = b.pos.x - S.pos.x;
      if (dis > -1 * S.hlen && dis < S.hlen){ // hit
        expl_h = new ptc_sys(1000, 8, new PVector(b.pos.x,840), new PVector(10,2) // spawn explosion
          , new PVector(0, -5), 80);
        expl_h.spawnParticles(dt);
        S.health -= 1;
        player = minim.loadFile("../Sound/hit.wav");
        player.play();        
      }
      else{ // miss
        expl_m = new ptc_sys(2000, 8, new PVector(b.pos.x,850), new PVector(10,2) // spawn explosion
          , new PVector(0, -40), 10);
        expl_m.spawnParticles(dt);     
        player = minim.loadFile("../Sound/water.wav");
        player.play();        
      }

      int ind = (int)(n*b.pos.x/1600);
      if (ind >= 0 && ind < 100) uh[ind] = 2;
    }
  }  
  
  //Smoke Update
  if (B.health < 5){ // Plane emit smoke
    if (B.health >= 0)
    {
      pln_smk.SetGenRate(10*(5-B.health)+10);
      pln_smk.Update(dt, true, false, false);      
    }
    else pln_smk.Update(dt, false, true, false);
  }
  spark.Update(dt, false, true, false); // spark when plane is hit
  expl_h.Update(dt, false, true, false); // explosion when hit
  expl_m.Update(dt, false, true, true); // explosion when miss  
  if (S.health < 10){ // Fort emit smoke
    ship_smk.SetGenRate(30);
    ship_smk.Update(dt, false, false, false);
  }
  
  //Ship Update
  if (S.health > 0) {
    S.pos.y = 885-h[25]*70;
    if(S.cooldown <= 0 && B.health > 0){ // Open Fire
      float theta = autoaim();
      //println(theta);
      S.bullet_list.add(new Bullet(S.pos.x, S.pos.y, theta));
      S.cooldown = 15;
      player=minim.loadFile("../Sound/shot.wav");
      player.play();
    }    
  }
  else { // Sink
    S.pos.y += 1;
    ship_smk.SetPos(S.pos);
  }
  S.cooldown -= dt;
  

  
  //Bullet Update
  for(int i=S.bullet_list.size()-1;i>=0;i--){
     Bullet bullet=S.bullet_list.get(i);
     bullet.pos.x+=bullet_v*dt*sin(bullet.angle*PI/180.0);
     bullet.pos.y-=bullet_v*dt*cos(bullet.angle*PI/180.0);
     if(bullet.pos.x<0||bullet.pos.x>1600||bullet.pos.y<0){
       S.bullet_list.remove(i);
       continue;
     }
     PVector bullet_head=new PVector(bullet.pos.x+40*sin(bullet.angle*PI/180.0),bullet.pos.y-40*cos(bullet.angle*PI/180.0));
     PVector bullet_tail=new PVector(bullet.pos.x-40*sin(bullet.angle*PI/180.0),bullet.pos.y+40*cos(bullet.angle*PI/180.0));
     //test
     //fill(0,255,0);
     //circle(bullet_head.x,bullet_head.y,15);
     //circle(bullet_tail.x,bullet_tail.y,15);
     
     if(dis(bullet_head,B.pos)<30.0||dis(bullet_tail,B.pos)<30.0){//bullet hit bomber 
        B.health--;
        PVector tmp = B.pos.copy();
        spark = new ptc_sys(500, 2, tmp, new PVector(2,2) // spawn spark
        , new PVector(0, -5), 180);
        spark.spawnParticles(dt);
        S.bullet_list.remove(i);
        player = minim.loadFile("../Sound/hit.wav");
        player.play(); 
        continue;
      }
      
      
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
  
  public void Update(float dt, boolean track, boolean onetime, boolean grav){ // update particle system
    if (track){
      src_pos = B.pos;
      ini_vel = PVector.mult(B.vel, -0.5);
    }
    if (!onetime) spawnParticles(dt); // spawn new particles in this timestep
    DelParticles();
    for (int i = 0; i < POS.size(); i++) {
      // Update positions
      POS.get(i).x += VEL.get(i).x * dt;
      POS.get(i).y += VEL.get(i).y * dt;
      // Update velocity
      //if (expl) VEL.get(i).y += 10;
      //else 
      if (grav) VEL.get(i).y += 2;
      else VEL.get(i).y -= 0.6;
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
    if (p.y >= 850) return;
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
  
  void SetPos(PVector v){
    src_pos = v.copy();
  }
  
}

// ==============================================================================

ptc_sys pln_smk; // plane smoke
ptc_sys spark; // spark when the plane is hit
ptc_sys ship_smk; // ship smoke
ptc_sys expl_m; // explosion missed
ptc_sys expl_h; // explosion hit


// ========================== Draw Call =============================
void draw() {
  background(sky);
  
  
  waveEquation(.01); // Update sea
  update(0.15);
  
  
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
    pushMatrix();
    translate(b.pos.x, b.pos.y);
    if(b.vel.x>0){
      rotate(45*PI/180.0);
    }else{
      rotate(-135*PI/180.0);
    }
    imageMode(CENTER);
    image(tpt, 0, 0,25,25);
    popMatrix();
  }
  
  // ship
  pushMatrix();
  translate(S.pos.x, S.pos.y);
  //scale(0.15);
  imageMode(CENTER);
  image(ship1, 0, 0);
  popMatrix();
  
   //bullet
   for(int i=S.bullet_list.size()-1;i>=0;i--){
     Bullet bullet=S.bullet_list.get(i);
     //fill(0, 0, 0);
     //circle(bullet.pos.x, bullet.pos.y, bomb_r);
    pushMatrix();
    translate(bullet.pos.x, bullet.pos.y);
    rotate(bullet.angle*PI/180);
    scale(0.8);
    imageMode(CENTER);
    image(bullet_img, 0, 0,50/2,83/2);
    popMatrix();
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
  
  // Explosion
  for (int i = 0; i < expl_h.POS.size(); i++) { // explosion
    strokeWeight(10);
    stroke(255,30*expl_h.LIFE.get(i),0, expl_h.LIFE.get(i)*20);
    point(expl_h.POS.get(i).x, expl_h.POS.get(i).y);
  }
  for (int i = 0; i < expl_m.POS.size(); i++) { // explosion
    strokeWeight(10);
    float tmp = (10-expl_m.LIFE.get(i))*3;
    //stroke(150+tmp, 150+tmp, 255, expl_m.LIFE.get(i)*20);
    stroke(225+tmp, 225+tmp, 255, expl_m.LIFE.get(i)*20);
    point(expl_m.POS.get(i).x, expl_m.POS.get(i).y);
  }
  
  
  // ship smoke
  for (int i = 0; i < ship_smk.POS.size(); i++) {
    float lf = ship_smk.LIFE.get(i);
    float clr = 25*S.health;
    strokeWeight(25 - lf);
    stroke(clr,clr,clr,20);
    //stroke(200,200,200,80);
    point(ship_smk.POS.get(i).x, ship_smk.POS.get(i).y);
  }  
  
  
  // Sea
  noStroke();
  fill(100, 100, 255, 70);
  beginShape(QUADS);
  for (int i = 0; i < n-1; i++){
    vertex(1600.0/(n-1)*i, 900);
    vertex(1600.0/(n-1)*i, 900-h[i]*70); //<>//
    vertex(1600.0/(n-1)*(i+0.5), 900-h[i]*70);
    vertex(1600.0/(n-1)*(i+0.5), 900);
    vertex(1600.0/(n-1)*(i+0.5), 900);
    vertex(1600.0/(n-1)*(i+0.5), 900-h[i]*70);
    vertex(1600.0/(n-1)*(i+1), 900-h[i+1]*70);
    vertex(1600.0/(n-1)*(i+1), 900);   
  }
  endShape();
  String runtimeReport = 
        " FPS: "+ str(round(frameRate)) +"\n";
  surface.setTitle(projectTitle+ "  -  " +runtimeReport);
}

float autoaim(){

  float theta1;
  float theta2;
  
  float tmp1 = S.pos.x - B.pos.x;
  float tmp2 = S.pos.y - B.pos.y;
  if (tmp2 == 0){
    if (tmp1 < 0) return 90;
    else return -90;
  }
  float c1 = tmp1/tmp2;
  float c2 = (c1*B.vel.y - B.vel.x)/bullet_v;
  float a = 1 + c1*c1;
  float b = 2*c2;
  float c = c2*c2 - c1*c1;
  
  float det1 = (-1*b+sqrt(b*b-4*a*c))/(2*a);
  float det2 = (-1*b-sqrt(b*b-4*a*c))/(2*a);
  
  //println("costheta = ",det2);
  theta1 = acos(det1);
  theta2 = acos(det2);
  theta1 = theta1 * 180 / PI;
  theta1 = 180 - theta1;
  theta1 -= 90;
  theta2 = theta2 * 180 / PI;
  theta2 = 180 - theta2;
  theta2 -= 90;
  if ((B.pos.x - S.pos.x)*(theta1) > 0) return theta1;
  return theta2;
}

// ===================== Self-defined Classes =====================
// Bomber Class
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

// Ship
class Ship{
  int health;
  PVector pos = new PVector(); // position
  float hlen; // half length
  float cooldown; // cooldown time for gun
  ArrayList<Bullet> bullet_list;

  
  public Ship(float x, float y){
    health = 10;
    
    pos.x = x;
    pos.y = y;
    hlen = 100;
    cooldown = 8;
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
     //pos.x += 80*sin(angle*PI/180.0);
     //pos.y -= (80*cos(angle*PI/180.0)+20);
   }
   
}

void keyPressed() {
  if (keyCode == ENTER) uh[25] = 2;
  // Bomber
  if (B.health > 0){
    if (keyCode == 'W') B.up = true;
    else if (keyCode == 'S') B.down = true;
  }
  // Bomb
  if (keyCode ==   ' ' && B.cooldown == false){ // drop bomb
    B.cooldown = true;
    b = new Bomb(B);
    player = minim.loadFile("../Sound/bomb.wav");
    player.play();
  }
  
  if (keyCode == ESC) exit();
}

void keyReleased(){
  if (keyCode == 'W') B.up = false;
  else if (keyCode == 'S') B.down = false;
}

//distance
float dis(PVector p1, PVector p2){
  return sqrt((p1.x-p2.x)*(p1.x-p2.x)+(p1.y-p2.y)*(p1.y-p2.y));
}
