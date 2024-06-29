# A bouncing particle on parabola floor

File Name: `a_ball_bounce_on_parabola_multi.pde`

Language Used: [Processing](https://processing.org)

* Simulation Model
    - One particle falls under gravity.
    - There is a lower parabola below.
      ```
         y = x^2 / 2
      ```      
    - The particle reflects upon hitting the parabola.
  
* Definition of Variables
    - The position of the particle is (x,y), and the velocity is (vx,vy).
    - Generalized coordinates (x,y,vx,vy) are grouped into the GeneralCoords class.

* Simulation Method
    - Solve Lagrange's equations of motion with the `equation_of_motion()` function.
    - Classical 4th-order Runge-Kutta method is used for numerical integration.
    - Coordinates and physical quantities are calculated as `float` (single precision) floating-point numbers.
    - The total energy is calculated and displayed to check accuracy.
  
* Visualization
    - Uses Processing's line and circle display functions.
    - In Processing, the y-axis (`+y`) direction is downward on the screen, so the `map` function is used to reverse it,
      making the y-axis `+y` direction upward on the screen.
    - The Processing window is divided into three areas.
    - Technically, header and footer areas are also reserved around these three areas.
 
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
       
* Usage
    - Initial conditions can be changed in the `setup()` function as follows:
        `ball = new GeneralCoords( x-coordinate of the particle, x component of velocity vx,
                                  y-coordinate of the particle, y component of velocity vy )`
    - Press the `u` key on the keyboard to accelerate the calculation (display).
    - Press the `d` key on the keyboard to decelerate the calculation (display).
    - Press the `s` key on the keyboard to pause (stop) and restart (start) the calculation (display).
    - Mouse click also toggles start/stop. 
    
* Development History
    - Akira Kageyama (kage@port.kobe-u.ac.jp)
    - July 05, 2023
