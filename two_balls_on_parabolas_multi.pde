/*

  two_balls_on_parabolas_multi.pde
  
  * シミュレーションモデル  
    - 2つの質点（質量同じ）がそれぞれ別の放物線の上を摩擦なしで滑る。
    - 2つの放物線の方程式は以下の通り：
       放物線1：y = +x^2 + 1
       放物線2：y = -x^2 - 1
    - 2つの質点（質点1と質点2）は線形バネで連結されている。
    - バネの自然長と質量はゼロとする。
    - 重力の影響は無視する。  
  
  * 変数の定義
    - この系の自由度は2である。
    - 質点1のx座標をx1,x1の時間微分（=速度のx成分）をv1とする
    - 質点2も同様。
    - 一般化座標(x1,x2,v1,v2)をGeneralCoordsクラスにまとめた。
  
  * この系のラグランジアンは
           L(x1,x2,v1,v2) = (m/2)*(v1^2+4*x1^2*v1^2)
                          + (m/2)*(v2^2+4*x2^2*v2^2)
                          - (k/2)*s^2,
    ここで以下は作業用の変数：
            s = sqrt(dx^2+dy^2), dx=x1-x2, dy=x1^2+x2^2+2.

  * シミュレーション手法
    - ラグランジュの運動方程式をequation_of_motion()関数で解く。
    - 数値積分には古典的な4次ルンゲ・クッタ法を使う。
    - 座標や物理量はfloat（単精度）浮動小数点数として計算している。
    - 精度確認のため全エネルギーを計算・表示する。
  
  * 可視化
    - Processingの線分と円の表示機能を使用。
    - Processingではy軸（+y）の向きが画面の下方向なのでmap関数で反転し、
      y軸+yが画面の上方向になるようにしている。
    - Processingのウィンドウ画面を3つの領域に分割して使う。
    - 細かく言えばこの3つの領域の周囲にヘッダとフッタ領域も確保している。
        +------------+------------+------------+
        |            |            |            |
        |     x-y    |    x1-x2   |   x1-v1    |
        |     plot   |     plot   |  Poincare  |
        |(real space)|(Every time |    map     |
        |            |      steps)| (For v2=0) |
        |            |            |            |
        +------------+------------+------------+
       
  * 使用法
    - 初期条件の設定は setup()関数の以下の部分で変更する。
        balls = new GeneralCoords( 質点1のx座標, その時間微分,
                                   質点2のx座標, その時間微分 )
    - キーボードのuキーで計算（表示）の加速。
    - キーボードのdキーで計算（表示）の減速。
    - キーボードのsキーで計算（表示）の一時停止(stop)と再スタート(start)。
    - マウスクリックもstart/stopのトグル。 
    
  * 開発履歴
    - Akira Kageyama (kage@port.kobe-u.ac.jp)
    - June 29, 2023
  
*/


final int VERTICAL_MARGIN = 50;
final int HORIZONTAL_MARGIN = 5;


float time = 0.0;
int step = 0;
float dt = 0.001;

boolean running_state_toggle = true;

float x_coord_min = -3.0;
float x_coord_max =  3.0;

int speed = 10;

GeneralCoords balls;
GeneralCoords balls_prev;

final float SPRING_K  = 1.0;
final float PARTICLE_MASS = 1.0;
final float OMEGA_SQ = SPRING_K/PARTICLE_MASS;



class Window {
    int xmin;
    int xmax;
    int ymin;
    int ymax;
   
    Window(int xmin,int ymin,int xmax,int ymax) {
        this.xmin = xmin;
        this.ymin = ymin;
        this.xmax = xmax;
        this.ymax = ymax;
    }
   
    void background(int gray) {
        noStroke();
        fill(gray);
        rect(xmin,ymin,(xmax-xmin),(ymax-ymin));
    }
   
    void frame(int gray) {
        stroke(gray);
        noFill();
        rect(xmin,ymin,(xmax-xmin),(ymax-xmin));
    }
    
    void translate_origin() {
        translate((xmax+xmin)/2,(ymax+ymin)/2); //<>//
    }
    
      // 
      // |<---------width--------->|
      // .                         .
      // .                         .
      // +-------------------------+ ... ---
      // |    |      VM       |    |     /|\
      // |----+---------------+----|      |
      // |    |               |    |      |
      // |    | VM=Vertical   |    |      |
      // | HM |      Margin   | HM |    height
      // |    | HM=Horizontal |    |      |
      // |    |        Margin |    |      |
      // |----+---------------+----|      |
      // |    |      VM       |    |     \|/
      // +-------------------------+ ... ---
      // (x,y) = physical unit coords. 
      // (map(x),map(y)) = pixel coords.
    
    float mapx(float x) {
        float scale = (this.xmax - this.xmin)/(x_coord_max-x_coord_min);
        return x*scale;
    }
    
    
    float mapy(float y) {
        float y_coord_max = parabola_func_upper(x_coord_max);
        float y_coord_min = -y_coord_max;
        float scale = (this.ymax-this.ymin)/(y_coord_max-y_coord_min);
        return -scale*y;  // reverse up/down direction.
    }

    
    void draw_axes_x1_x2() {
      pushMatrix();
        translate_origin();
        stroke(100,100,100);
        line(mapx(x_coord_min),0,mapx(x_coord_max),0);
        line(0,mapx(x_coord_min),0,mapx(x_coord_max));
      popMatrix();
    }


    void draw_balls_on_xyplane(float x1,float x2) {
      pushMatrix();
          translate_origin();
          stroke(50,100,255); 
          point(mapx(x1),-mapx(x2));
      popMatrix();
    }

    void draw_parabolas() {
      pushMatrix();
        translate_origin();
        
        int nx = 500;
        float dx = (x_coord_max-x_coord_min)/nx;
        float x, y;
    
        float x_prev = x_coord_min;
        float y_prev = parabola_func_upper(x_prev);
    
        for (int i=1; i<=nx; i++) { // starts from i=1.
            x = x_coord_min + dx*i;
            y = parabola_func_upper(x);
            if ( i%12 <= 6 ) stroke(100,100,100);
            else             stroke(255,255,255);
            line(mapx(x_prev),mapy(y_prev),mapx(x),mapy(y));
            x_prev = x;
            y_prev = y;
        }
    
        x_prev = x_coord_min;
        y_prev = parabola_func_lower(x_prev);
    
        for (int i=1; i<=nx; i++) { // starts from i=1.
          x = x_coord_min + dx*i;
          y = parabola_func_lower(x);
          if ( i%12 <= 6 ) stroke(100,100,100);
          else             stroke(255,255,255);
          line(mapx(x_prev),mapy(y_prev),mapx(x),mapy(y));
          x_prev = x;
          y_prev = y;
        }
      popMatrix();
    }
    
    
    void draw_balls_on_parabolas(float x1,float x2) {
      pushMatrix();
        translate_origin();
        stroke(50); 
        fill(255,210,150);
    
        float y1 = parabola_func_upper(x1);
        ellipse(mapx(x1),mapy(y1),10,10);
        
        fill(150,230,255);
        float y2 = parabola_func_lower(x2);
        ellipse(mapx(x2),mapy(y2),10,10);
      popMatrix();
    }
     
    
    void draw_poincare_x1_x2(float x1, float x2) {
      pushMatrix();
        translate_origin();
        stroke(255,100,100); 
        point(mapx(x1),-mapx(x2));
      popMatrix();
    }
         
    
    void draw_poincare_x1_v1(float x1, float v1) {
      float factor = 0.8; // trial and errors.
      pushMatrix();
        translate_origin();
        stroke( 0, 150, 0 ); 
        point(factor*mapx(x1),-factor*mapx(v1));
      popMatrix();
    }
        
    
    void draw_spring() {
      pushMatrix();
        translate_origin();
        stroke(0,150,0);
        float x1 = balls.x1;
        float y1 = parabola_func_upper(x1);
        float x2 = balls.x2;
        float y2 = parabola_func_lower(x2);
        line(mapx(x1),mapy(y1),mapx(x2),mapy(y2));
      popMatrix();
    }    

    void label_x_axis(String msg) {
      pushMatrix();
        translate_origin();
        fill(0,0,0);
        textAlign(RIGHT);
        text(msg,mapx(x_coord_max),-6);
      popMatrix();
    }
    
    void label_y_axis(String msg) {
      pushMatrix();
        translate_origin();
        fill(0,0,0);
        textAlign(CENTER);
        text(msg,mapx(0), -mapx(x_coord_max)-6);
      popMatrix();
    }
}




class Header {

    void erase(int gray) {
      fill(gray);
      rect(0,0,width,VERTICAL_MARGIN);
    }

    void title(String msg, int rlc) {  
        // rlc = RIGHT or LEFT or CENTER
        noStroke();
        pushMatrix();
          fill(0,0,0);
          textAlign(rlc); 
          text(msg,0,textWidth(" "),width,VERTICAL_MARGIN);
        popMatrix();
    }
}



class Footer {

    void erase(int gray) {
      noStroke();
      fill(gray);
      rect(0,height-VERTICAL_MARGIN,width,VERTICAL_MARGIN);
    }

    void title(String msg, int rlc) {  
        // rlc = RIGHT or LEFT or CENTER
        noStroke();
        pushMatrix();
          fill(0,0,0);
          textAlign(rlc);
          text(msg,0,height-VERTICAL_MARGIN+textWidth(" "),
               width,VERTICAL_MARGIN);
        popMatrix();
    }
}


Header header = new Header();
Footer footer = new Footer();


Window[] window;


class GeneralCoords {
  float x1;
  float v1;
  float x2;
  float v2;
  
  GeneralCoords(float x1, float v1, float x2, float v2) {
    this.x1 = x1;
    this.v1 = v1;
    this.x2 = x2;
    this.v2 = v2;
  }
  
  GeneralCoords() {
    x1 = 0.0;
    v1 = 0.0;
    x2 = 0.0;
    v2 = 0.0;
  }
  
  GeneralCoords(GeneralCoords copy) {
    x1 = copy.x1;
    v1 = copy.v1;
    x2 = copy.x2;
    v2 = copy.v2;
  }
}



void setup() {
    size(1200,600);
    background(255);
    frameRate(60);
    // window = new Window[3];
    
    //    0  x0l       x0r x1l     x1r x2l      x2r  width
    //    |   |         | | |       | | |        |   |
    //    |   |         | | |       | | |        |   |
    //    |H_M|---------|H_M|-------|H_M|--------|H_M|
    //    |   |         | | |       | | |        |   |
    //    | "H_M" = HORIZONTAL_MARGIN            |   |
    //    |   |         | | |       | | |        |   |

    int each_window_width = (width-4*HORIZONTAL_MARGIN)/3;    
    int x0l = HORIZONTAL_MARGIN;
    int x0r = x0l + each_window_width;
    int x1l = x0r + HORIZONTAL_MARGIN;
    int x1r = x1l + each_window_width;
    int x2l = x1r + HORIZONTAL_MARGIN;
    int x2r = x2l + each_window_width;
    //
    //   +----                       y=0
    //   |  VERTICAL_MARGIN
    //   +----                       y=y1
    //   |
    //   |
    //   |
    //   |
    //   |
    //   +----                       y=y2
    //   |  VERTICAL_MARGIN
    //   +----                       y=height

    int y1 = VERTICAL_MARGIN;
    int y2 = height - VERTICAL_MARGIN;
    
    window = new Window[3];
    
    window[0] = new Window(x0l,y1,x0r,y2);
    window[1] = new Window(x1l,y1,x1r,y2);
    window[2] = new Window(x2l,y1,x2r,y2);
    
    window[1].draw_axes_x1_x2();
    window[1].label_x_axis("x1");
    window[1].label_y_axis("x2");
    window[2].draw_axes_x1_x2();
    window[2].label_x_axis("x1");
    window[2].label_y_axis("v1"); //<>//

 
    header.title("  Two balls on parabolas\n  Particle 1 (upper) and 2 (lower)",LEFT);
    header.title("  Path plot of (x1,x2)", CENTER);
    header.title("Poincare map of (x1,v1) on v2=0  ", RIGHT);
    
//// 線形（微小）単振動
//      balls = new GeneralCoords( x_coord_max*0.05,0,  // x1 & v1
//                                 x_coord_max*0.05,0); // x2 & v2
//// 線形（微小）振動
//    balls = new GeneralCoords( x_coord_max*0.1,0,  // x1 & v1
//                              -x_coord_max*0.05,0); // x2 & v2
// 非線形単一周期運動
    balls = new GeneralCoords( x_coord_max*0.4,0,  // x1 & v1
                              -x_coord_max*0.4,0); // x2 & v2
//// 比較的単純な非線形運動
//    balls = new GeneralCoords( x_coord_max*0.4,0,  // x1 & v1
//                              -x_coord_max*0.2,0); // x2 & v2
//// 複雑な運動
//    balls = new GeneralCoords( x_coord_max*0.4,0,  // x1 & v1
//                              -x_coord_max*0.1,0); // x2 & v2

    balls_prev = new GeneralCoords();                             
}


float total_energy() {
    float x1 = balls.x1;
    float v1 = balls.v1;
    float x2 = balls.x2;
    float v2 = balls.v2;

    float v1sq = v1*v1;
    float v2sq = v2*v2;

    float y1 = parabola_func_upper(x1);
    float y2 = parabola_func_lower(x2);
    
    float y1dot = parabola_func_upper_derivative(x1)*v1;
    float y2dot = parabola_func_lower_derivative(x2)*v2;
    float y1dotsq = y1dot*y1dot;
    float y2dotsq = y2dot*y2dot;
    
    float s = sqrt((x1-x2)*(x1-x2)+(y1-y2)*(y1-y2));

    float kinetic_e = 0.5*PARTICLE_MASS*(v1sq+y1dotsq+v2sq+y2dotsq);
    float potential = 0.5*SPRING_K*(s*s);

    return(kinetic_e + potential);
}


void rungekutta_advance(GeneralCoords b, 
                        GeneralCoords b1, 
                        GeneralCoords db, 
                        float factor) {
    b.x1 = b1.x1 + factor*db.x1;
    b.v1 = b1.v1 + factor*db.v1;
    b.x2 = b1.x2 + factor*db.x2;
    b.v2 = b1.v2 + factor*db.v2;    
}


void equation_of_motion(GeneralCoords b, 
                        GeneralCoords db, 
                        float dt) {
  //    Lagrangian
  //       L(x1,x2,v1,v2) = (m/2)*(v1^2+4*x1^2*v1^2)
  //                      + (m/2)*(v2^2+4*x2^2*v2^2)
  //                      - (k/2)*s^2
  //    where
  //        s = sqrt(dx^2+dy^2), dx=x1-x2, dy=x1^2+x2^2+2
  // 
    float x1 = b.x1;
    float v1 = b.v1;
    float x2 = b.x2;
    float v2 = b.v2;

    float dx   = x1 - x2;
    float x1sq = x1*x1;
    float v1sq = v1*v1;
    float x2sq = x2*x2;
    float v2sq = v2*v2;
    float dy   = x1sq + x2sq + 2;
    float f1 = OMEGA_SQ*( dx+2*x1*dy);
    float f2 = OMEGA_SQ*(-dx+2*x2*dy);

    db.x1 = ( v1 ) * dt;
    db.v1 = ( -1.0/(1+4*x1sq)*(4*x1*v1sq + f1) ) * dt;
    db.x2 = ( v2 ) * dt;
    db.v2 = ( -1.0/(1+4*x2sq)*(4*x2*v2sq + f2) ) * dt;
}



void runge_kutta4()
{
  final float ONE_SIXTH = 1.0/6.0;
  final float ONE_THIRD = 1.0/3.0;
  
  GeneralCoords work = new GeneralCoords(); 
  GeneralCoords db01 = new GeneralCoords();
  GeneralCoords db02 = new GeneralCoords();
  GeneralCoords db03 = new GeneralCoords();
  GeneralCoords db04 = new GeneralCoords();

  balls_prev.x1 = balls.x1;
  balls_prev.v1 = balls.v1;
  balls_prev.x2 = balls.x2;
  balls_prev.v2 = balls.v2;
  
  //step 1
  equation_of_motion(balls_prev, db01, dt);
  rungekutta_advance(work, balls_prev, db01, 0.5);

  //step 2
  equation_of_motion(work, db02, dt);
  rungekutta_advance(work, balls_prev, db02, 0.5);

  //step 3
  equation_of_motion(work, db03, dt);
  rungekutta_advance(work, balls_prev, db03, 1.0);

  //step 4
  equation_of_motion(work, db04, dt);
  
  

  //the result
  balls.x1 = balls_prev.x1 + (  
                        ONE_SIXTH*db01.x1
                      + ONE_THIRD*db02.x1
                      + ONE_THIRD*db03.x1
                      + ONE_SIXTH*db04.x1 
                      );
  balls.v1 = balls_prev.v1 + (  
                        ONE_SIXTH*db01.v1
                      + ONE_THIRD*db02.v1
                      + ONE_THIRD*db03.v1
                      + ONE_SIXTH*db04.v1 
                      ); 
  balls.x2 = balls_prev.x2 + (  
                        ONE_SIXTH*db01.x2
                      + ONE_THIRD*db02.x2
                      + ONE_THIRD*db03.x2
                      + ONE_SIXTH*db04.x2 
                      );
  balls.v2 = balls_prev.v2 + (  
                        ONE_SIXTH*db01.v2
                      + ONE_THIRD*db02.v2
                      + ONE_THIRD*db03.v2
                      + ONE_SIXTH*db04.v2 
                      ); 

}


float parabola_func_upper(float x) {
  // When you change this, revise its derivative
  // parabola_func_upper_derivative(), too.
  float y;
  y = x*x+1;
  return(y);
}

float parabola_func_upper_derivative(float x) {
  // When you change this, revise
  // parabola_func_upper(), too.
  float y;
  y = 2*x;
  return(y);
}


float parabola_func_lower(float x) {
  // When you change this, revise its derivative
  // parabola_func_lower_derivative(), too.
  float y;
  y = -x*x-1;
  return y;
}

float parabola_func_lower_derivative(float x) {
  // When you change this, revise
  // parabola_func_upper(), too.
  float y = -2*x;
  return y;
}


void draw(){
    window[0].background(255);
    window[0].draw_parabolas();
 
    if ( running_state_toggle ) {
      for (int icnt=0; icnt<speed; icnt++) {
        runge_kutta4();
        time += dt;
        step += 1;
        
        window[1].draw_balls_on_xyplane(balls.x1,balls.x2);    

        float cross_before = balls_prev.v2; // for Poincare
        float cross_after  = balls.v2;      // cross section.
        if (cross_after * cross_before < 0 ) {
          //   |              .
          // va|____________.
          //   |          . |
          //   |        .   |
          // --+-xb---.-----xa------>x
          //   |  | .  \
          // vb|__.     x=xb-vb*(xa-xb)/(va-vb) 
          //   |.       (See below.)
          //
          // The equation of the linear function is  
          //       v(x) = (va-vb)/(xa-xb) * (x-xb) + vb.
          // Solving 
          //       v(x) = 0,
          // We get
          //       x = xb-vb*(xa-xb)/(va-vb)
          //         = xb+weight*(xa-xb)  [weight=-vb/(va-vb)]
          //         = weight*xa + (1-weight)*xb
          float wa = -cross_before/(cross_after-cross_before);
          float wb = 1 - wa;
          float xx1 = wa*balls.x1 + wb*balls_prev.x1;
          float xx2 = wa*balls.x2 + wb*balls_prev.x2;
          float vv1 = wa*balls.v1 + wb*balls_prev.v1;
//          window[2].draw_poincare_x1_x2(xx1,xx2);
          window[2].draw_poincare_x1_v1(xx1,vv1);
        }        
      }
      //if ( step%1000 == 0 ) {
      //  println("step = ", step," time = ", time," energy = ",total_energy());
      //}
    }

    window[0].draw_spring();
    window[0].draw_balls_on_parabolas(balls.x1,balls.x2);
    
    String str = "Speed = " + nf(speed) + "  (Type u/d to speed up/down)";
    str += "\nenergy = " + nf(total_energy(),4,3);
    str += "\nt = " + nf(time,6,3);
    str += " (step = " + nf(step,9) + ")";
    footer.erase(255);
    footer.title(str, CENTER);
}

void mousePressed() {
  running_state_toggle = !running_state_toggle;
}

void keyReleased() {
  switch (key) {
    case 's':
      running_state_toggle = !running_state_toggle;
      break;
    case 'u':
      speed *= 2;
      break;
    case 'd':
      speed /= 2;
      if ( speed <= 0 ) speed = 1;
      break;
  }
}
