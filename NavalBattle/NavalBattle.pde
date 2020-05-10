// Multiplayer War Game Naval version
// Written by Yuxuan Huang and Jiajun Tang
// for CSCI 5611 Final Project
import java.lang.Math;

String projectTitle = "Naval battle";

PImage sky, bomberimg;
Bomber B;
Bomb b;
Float bomb_r=10.0;//bomb_radius
int bomber_direction; //1:fly to right, -1:fly to left
float countdown; // countdown before game ends

float g = 10;

int n = 50;
float dx = 0.1;
float[] h = new float[n];
float[] uh = new float[n];

float totlen = n*dx;
float[] hm = new float[n];
float[] uhm = new float[n];

// Create Window
void setup() {
  size(1600, 900, P2D);
  noStroke();
  sky = loadImage("../Images/sky_bkg.jpg");
  bomberimg = loadImage("../Images/AVG.png");
  init();
}

// Initialization
void init(){
  B = new Bomber();
  b = new Bomb(B);
  bomber_direction = 1;
  pln_smk = new ptc_sys(0, 5, B.pos, new PVector(5,5), B.vel, 30);
  spark = new ptc_sys(0, 5, B.pos, new PVector(5,5), B.vel, 30);
  expl_m = new ptc_sys(0, 5, B.pos, new PVector(5,5), B.vel, 30);
  expl_h = new ptc_sys(0, 5, B.pos, new PVector(5,5), B.vel, 30);  
  for (int i = 0; i < n; i++){ // initialize sea
    h[i] = 1;
    uh[i] = 0;
    hm[i] = 0;
    uhm[i] = 0;
  }
  countdown = 12;
}


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
  
  if (B.health < 0) countdown-=dt;
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
    
  if (B.pos.y >= 850 && B.health >= 0) {   // Collision Check, Plane Crash & explode
      expl_h = new ptc_sys(500, 8, new PVector(B.pos.x,850), new PVector(10,2) // spawn explosion
        , new PVector(0, -5), 80);
      expl_h.spawnParticles(dt);
      expl_m = new ptc_sys(2000, 8, new PVector(B.pos.x,850), new PVector(10,2) // spawn explosion
        , new PVector(0, -40), 10);
      expl_m.spawnParticles(dt);
      uh[(int)(n*B.pos.x/1600)] = 3;
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

    if (b.pos.y >= 850) {// ground Collision Check
      B.cooldown = false;
      //b.pos.set(0,0);
      expl_m = new ptc_sys(2000, 8, new PVector(b.pos.x,850), new PVector(10,2) // spawn explosion
        , new PVector(0, -40), 10);
      expl_m.spawnParticles(dt);
      int ind = (int)(n*b.pos.x/1600);
      if (ind >= 0 && ind < 50) uh[ind] = 2;
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
  expl_m.Update(dt, false, true, true); // explosion when miss  
  
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
  noStroke();
  
  // Sea
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
  }
  
  if (keyCode == ESC) exit();
}

void keyReleased(){
  if (keyCode == 'W') B.up = false;
  else if (keyCode == 'S') B.down = false;
}
