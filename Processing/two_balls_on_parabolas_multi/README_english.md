# Two particles constrained on parabolas

* File Name: two_balls_on_parabolas_multi.pde

* Language Used: [Processing](https://processing.org)

* Simulation Model  
    - Two particles (with the same mass) slide without friction on separate parabolas.
    - The equations of the two parabolas are as follows:
       Parabola 1:
      ```
         y = +x^2 + 1
      ```      
      
       Parabola 2:
      ```
        y = -x^2 - 1
      ```
    - The two particles (Particle 1 and Particle 2) are connected by a linear spring.
    - The natural length and mass of the spring are considered zero.
    - The effect of gravity is ignored.  
  
* Definition of Variables
    - The system has 2 degrees of freedom.
    - The `x` coordinate of Particle 1 is `x1`, and the time derivative of `x1` (velocity component of `x`) is `v1`.
    - The same applies to Particle 2.
    - Generalized coordinates `(x1,x2,v1,v2)` are grouped into the `GeneralCoords` class.
  
* The Lagrangian of this system is

```
       L(x1,x2,v1,v2) = (m/2)*(v1^2+4*x1^2*v1^2)
                      + (m/2)*(v2^2+4*x2^2*v2^2)
                      - (k/2)*s^2,
where the following are working variables:
        s = sqrt(dx^2+dy^2), dx=x1-x2, dy=x1^2+x2^2+2.
```


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
        `balls = new GeneralCoords( x-coordinate of Particle 1, its time derivative,
                                   x-coordinate of Particle 2, its time derivative )`
    - Press the `u` key on the keyboard to accelerate the calculation (display).
    - Press the `d` key on the keyboard to decelerate the calculation (display).
    - Press the `s` key on the keyboard to pause (stop) and restart (start) the calculation (display).
    - Mouse click also toggles start/stop. 
    
* Development History
    - Akira Kageyama (kage@port.kobe-u.ac.jp)
    - June 29, 2023
