# 講義「システム情報学概論」サンプルコード


使用言語：[p5.js](https://p5js.org) および [Processing](https://processing.org)

* 2つのサンプルコード
	*  `two_balls_on_parabolas_multi`
		* 2つの質点（質量同じ）がそれぞれ別の放物線の上を摩擦なしで滑る。
	* `a_ball_bounce_on_parabola_multi`
		* 1つの質点が重力中を自由落下し、下方の放物線で跳ね返る。

* プログラムの基本構造はどちらも同じ。
    - 運動方程式を`equation_of_motion()`関数で解く。
       -  系の自由度は2である。
       -  4成分の一般化座標 (`GeneralCoords`) を使う。
    - 数値積分には古典的な4次ルンゲ・クッタ法を使う。
    - 座標や物理量は`float`（単精度）浮動小数点数として計算している。
    - 精度確認のため全エネルギーを計算・表示する。
  
  * 可視化
    - Processingのウィンドウ画面を3つの領域に分割して使う。
``` 
        +------------+------------+------------+
        |            |            |            |
        |     x-y    |    x1-x2   |   x1-v1    |
        |     plot   |     plot   |  Poincare  |
        |(real space)|(Every time |    map     |
        |            |      steps)| (For v2=0) |
        |            |            |            |
        +------------+------------+------------+
```
       
  * 使用法
    - 初期条件の設定は setup()関数の以下の部分で変更する。
    - キーボードの`u`キーで計算（表示）の加速。
    - キーボードの`d`キーで計算（表示）の減速。
    - キーボードの`s`キーで計算（表示）の一時停止(stop)と再スタート(start)。
    - マウスクリックもstart/stopのトグル。 
    
  * 開発履歴
    - Akira Kageyama (kage@port.kobe-u.ac.jp)
    - July 06, 2023
    - Revise June 29, 2024
