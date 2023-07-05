/*

  a_ball_bounce_on_parabola_multi.pde
  
  * シミュレーションモデル  
    - 1つの質点が重力を受けて落下する。
    - 下方には下の放物線がある。
        y = x^2 / 2
    - 質点は放物線に衝突すると反射する。
  
  * 変数の定義
    - 質点の位置を (x,y) とし、速度を(vx,vy) とする。
    - 一般化座標(x,y,vx,vy)をGeneralCoordsクラスにまとめた。
  
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
        ball = new GeneralCoords( 質点のx座標, 速度のx成分 vx,
                                  質点のy座標, 速度のy成分 vy )
    - キーボードのuキーで計算（表示）の加速。
    - キーボードのdキーで計算（表示）の減速。
    - キーボードのsキーで計算（表示）の一時停止(stop)と再スタート(start)。
    - マウスクリックもstart/stopのトグル。 
    
  * 開発履歴
    - Akira Kageyama (kage@port.kobe-u.ac.jp)
    - July 05, 2023
  
*/


final int VERTICAL_MARGIN = 75;
final int HORIZONTAL_MARGIN = 5;


float time = 0.0;
int step = 0;
float dt = 0.001;

boolean running_state_toggle = true;

float x_coord_min = -2.0;
float x_coord_max =  2.0;
float y_coord_min = -2.0;
float y_coord_max =  2.0; 

int speed = 10;

GeneralCoords ball;
GeneralCoords ball_prev;

final float PARTICLE_MASS = 1.0;
final float GRAVITY_ACCELERATION = 9.8;


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


    void draw_ball_on_xyplane( float x, float y ) {
      pushMatrix();
          translate_origin();
          stroke(50,100,255); 
          point(mapx(x),mapy(y));
      popMatrix();
    }

    void draw_parabola() {
      pushMatrix();
        translate_origin();
        
        int nx = 500;
        float dx = (x_coord_max-x_coord_min)/nx;
        float x, y;
    
        float x_prev = x_coord_min;
        float y_prev = parabola( x_prev );
    
        for (int i=1; i<=nx; i++) { // starts from i=1.
            x = x_coord_min + dx*i;
            y = parabola( x );
           stroke(100,100,100);
            line(mapx(x_prev),mapy(y_prev),mapx(x),mapy(y));
            x_prev = x;
            y_prev = y;
        }
      popMatrix();
    }
    
    
    void draw_the_ball(float x, float y) {
      pushMatrix();
        translate_origin();
        stroke(50); 
        fill(255,210,150);
    
        ellipse( mapx(x), mapy(y), 10, 10 );
      popMatrix();
    }
          
    
    void draw_poincare_x1_v1( float x1, float v1 ) 
    {
      float factor = 0.25; // trials and errors.
      pushMatrix();
        translate_origin();
        stroke( 0, 150, 0 ); 
        point( mapx(x1), factor*mapy(v1) );
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
  float x;
  float vx;
  float y;
  float vy;
  
  GeneralCoords( float x, float vx, float y, float vy ) {
    this.x  = x;
    this.vx = vx;
    this.y  = y;
    this.vy = vy;
  }
  
  GeneralCoords() {
    x  = 0.0;
    vx = 0.0;
    y  = 0.0;
    vy = 0.0;
  }
  
  GeneralCoords( GeneralCoords copy ) {
    x  = copy.x;
    vx = copy.vx;
    y  = copy.y;
    vy = copy.vy;
  }
}



void setup() 
{
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
    window[1].label_x_axis("x");
    window[1].label_y_axis("y");
    window[2].draw_axes_x1_x2();
    window[2].label_x_axis("x");
    window[2].label_y_axis("vx"); //<>//

 
    header.title("  A ball on parabolas",LEFT);
    header.title("  Path plot of (x,y)", CENTER);
    header.title("Poincare map of (x,vx) on vy=0  ", RIGHT);


    // 自由落下。カオス的
    ball = new GeneralCoords( x_coord_max*0.2, 0.0,  // x & vx
                              x_coord_max*0.7, 0.0 ); // y & vy
//                              
//    // 自由落下。
//    ball = new GeneralCoords( x_coord_max*0.01, 0.0,  // x & vx
//                              x_coord_max*0.7, 0.0 ); // y & vy
//
//    // 自由落下2。カオス的
//    ball = new GeneralCoords( x_coord_max*0.6, 0.0,  // x & vx
//                              x_coord_max*0.7, 0.0 ); // y & vy
//
//    // y軸上の自由落下。誤差の拡大
//     ball = new GeneralCoords( x_coord_max*0.0, 0.0,  // x & vx
//                               x_coord_max*0.7, 0.0 ); // y & vy
//
//    // 自由落下3。カオス的
//    ball = new GeneralCoords( x_coord_max*0.1, 0.0,  // x & vx
//                              x_coord_max*0.7, 0.0 ); // y & vy
//
//    // 水平方向打ち出し。往復運動
//    ball = new GeneralCoords( x_coord_max*0.0, 3.1,  // x & vx
//                              x_coord_max*0.5, 0.0 ); // y & vy
//    // カオス的。二重包路線
//    ball = new GeneralCoords( x_coord_max*0.2, -2.2,  // x & vx
//                              x_coord_max*0.7, -1.1); // y & vy


    ball_prev = new GeneralCoords();                             
}


float total_energy() {
    float vx = ball.vx;
    float vxsq = vx*vx;
    float y  = ball.y;
    float vy = ball.vy;
    float vysq = vy*vy;


    float kinetic_e = 0.5*PARTICLE_MASS*( vxsq + vysq );
    float potential = GRAVITY_ACCELERATION * y;

    return(kinetic_e + potential);
}


void rungekutta_advance(GeneralCoords b, 
                        GeneralCoords b1, 
                        GeneralCoords db, 
                        float factor) {
    b.x  = b1.x  + factor*db.x;
    b.vx = b1.vx + factor*db.vx;
    b.y  = b1.y  + factor*db.y;
    b.vy = b1.vy + factor*db.vy;    
}


void equation_of_motion(GeneralCoords b, 
                        GeneralCoords db, 
                        float dt) 
{
  // 
  //     dx/dt = vx    
  //     dy/dt = vy    
  //    dvx/dt = 0     
  //    dvy/dt = -g    
  // 

    db.x  = ( b.vx ) * dt;
    db.vx = 0.0;
    db.y  = ( b.vy ) * dt;
    db.vy = ( -GRAVITY_ACCELERATION ) * dt;
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

  ball_prev.x  = ball.x;
  ball_prev.vx = ball.vx;
  ball_prev.y  = ball.y;
  ball_prev.vy = ball.vy;
  
  //step 1
  equation_of_motion(ball_prev, db01, dt);
  rungekutta_advance(work, ball_prev, db01, 0.5);

  //step 2
  equation_of_motion(work, db02, dt);
  rungekutta_advance(work, ball_prev, db02, 0.5);

  //step 3
  equation_of_motion(work, db03, dt);
  rungekutta_advance(work, ball_prev, db03, 1.0);

  //step 4
  equation_of_motion(work, db04, dt);
  
  

  //the result
  ball.x  = ball_prev.x + (  
                        ONE_SIXTH*db01.x
                      + ONE_THIRD*db02.x
                      + ONE_THIRD*db03.x
                      + ONE_SIXTH*db04.x 
                      );
  ball.vx = ball_prev.vx + (  
                        ONE_SIXTH*db01.vx
                      + ONE_THIRD*db02.vx
                      + ONE_THIRD*db03.vx
                      + ONE_SIXTH*db04.vx 
                      ); 
  ball.y  = ball_prev.y + (  
                        ONE_SIXTH*db01.y
                      + ONE_THIRD*db02.y
                      + ONE_THIRD*db03.y
                      + ONE_SIXTH*db04.y 
                      );
  ball.vy = ball_prev.vy + (  
                        ONE_SIXTH*db01.vy
                      + ONE_THIRD*db02.vy
                      + ONE_THIRD*db03.vy
                      + ONE_SIXTH*db04.vy 
                      ); 

}




float interpol_weight( float val1, float val2 )
{
  //
  // We assume val1 and val2 have opposite signs, i.e., val1*val2 < 0.
  // 
  //      |              .
  //  val2|____________.
  //      |          . |
  //      |        .   |
  //    --+-x1---.-----x2------>x
  //      |  | .  \
  //  val1|__.     x=x2-val2*(x1-x2)/(val1-val2) 
  //      |.         (See below.)
  //
  // The equation of the linear function is  
  //       v(x) = (val1-val2)/(x1-x2) * (x-x2) + val2.
  // Solving 
  //       v(x) = 0,
  // We get
  //       x = x2-v2*(x1-x2)/(v1-v2)
  //         = x2+weight*(x1-x2)  
  //         = weight*x1 + (1-weight)*x2
  // where 
  //     weight = val2/(val2-val1)
  //        
  return val2 / (val2 - val1);          
}




float parabola( float x )
{
  return 0.5*(x*x);
}

void draw() 
{
    window[0].background(255);
    window[0].draw_parabola();
 
    if ( running_state_toggle ) {
      for (int icnt=0; icnt<speed; icnt++) {
        runge_kutta4();
        time += dt;
        step += 1;
        
        window[1].draw_ball_on_xyplane( ball.x, ball.y );    
        
        // For Poincare map.  When the ball reaches at the top of the orbit.      
        if ( ball_prev.vy > 0 && ball.vy < 0 ) {
          float weight_before = interpol_weight( ball_prev.vy, ball.vy );
          float weight_after  = 1 - weight_before;
          float xx1 = weight_before*ball_prev.x  + weight_after*ball.x;
          float vv1 = weight_before*ball_prev.vx + weight_after*ball.vx;
          window[2].draw_poincare_x1_v1( xx1, vv1 );             
        }
        
        // for Relection
        if ( ball.y < parabola( ball.x ) ) {
          //         
          //         [I] incoming (input) vector
          //        .
          //       .
          //      .    [R] reflected (output) vector
          //      \   /
          //       \ /
          //   -----*----> [T] tangential_vector
          //         \
          //          \
          //           [I] incoming (input) vector          
          //
          
          float vecIx = ball.vx;
          float vecIy = ball.vy;
          float vecI_amp = sqrt( vecIx * vecIx + vecIy * vecIy );
          float vecIx_normed = vecIx / vecI_amp;
          float vecIy_normed = vecIy / vecI_amp;
          // A tangential vector of parabola y = x^2/2
          // is given by (vecTx,vecTy) = (1,dy/dx) = (1,x)
          float dydx = ball.x; // posx_mid;
          float dydx_sq = dydx * dydx;
          float vecTx_amp = sqrt(1+dydx_sq);
          float vecTx_normed = 1.0  / vecTx_amp;
          float vecTy_normed = dydx / vecTx_amp;
          float z_component_of_vecI_cross_vecT
                  = vecIx_normed * vecTy_normed - vecIy_normed * vecTx_normed;
          if ( z_component_of_vecI_cross_vecT > 0 ) {
            //   
            // [Usual case]
            //   The ball comes from outside (above) the parabola.
            //
            //         vecT
            //   vecI   /
            //  -----> / 
            //        /
            //
            // [Anomalous case]
            //   The ball is inside (below) the parabola. This may
            //   happen when the ball has just being reflected in the
            //   previous time step. In this case the ball should continue
            //   running without reflection.
            //                
            //         vecT
            //          /
            //         / vectI
            //        /   |
            //            | 
            //            |            
            //           
            float dot_product_vecI_normed_and_vecT_normed
                  = vecIx_normed*vecTx_normed + vecIy_normed*vecTy_normed;
            float angle_between_vecI_normed_and_vecT_normed
                  = acos( dot_product_vecI_normed_and_vecT_normed );                
            float angle_for_reflection = 2 * angle_between_vecI_normed_and_vecT_normed;
            float cos_angle = cos( angle_for_reflection );         
            float sin_angle = sin( angle_for_reflection );
            
            float vecRx = cos_angle * vecIx - sin_angle * vecIy; 
            float vecRy = sin_angle * vecIx + cos_angle * vecIy;
            ball.vx = vecRx; 
            ball.vy = vecRy;      
          }
        }
      }
      //if ( step%1000 == 0 ) {
      //  println("step = ", step," time = ", time," energy = ",total_energy());
      //}
    }

    window[0].draw_the_ball( ball.x, ball.y );
    
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
