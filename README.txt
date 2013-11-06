/********************************************************
 * os PID Tuning Front-End 
 * version 1.0.0
 * by Brett Beauregard
 * adapted for stripboard Arduino PID controller shield
 * by Tom Price
 * License: GPLv3
 * November 2013
 *
 * This application is written in processing and is
 * designed to interface with the osPID.  From this 
 * Control Panel you can observe & adjust PID 
 * performance in real time
 *
 * The ControlP5 library (v0.5.4) is required to run this sketch.
 * files and install instructions can be found at
 * http://www.sojamo.de/libraries/controlP5/
 * 
 ********************************************************/

The graphical user interface allows every feature of the
Arduino PID controller shield to be governed remotely via 
the serial interface. A powerful additional feature is the 
ability to set multi-stage temperature profiles for 
applications where the set point changes over time.

The software and its use is documented
http://smokedprojects.blogspot.com/2013/11/stripboard-pid-arduino-shield-software.html
