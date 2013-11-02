import java.nio.ByteBuffer;
import processing.serial.*;
import controlP5.*;
import java.io.*;
import java.util.*;
import java.util.regex.*;

          
  /* To Do list:
   *
   * print osPID name up top somewhere?
   */

/***********************************************
 * User specification section
 **********************************************/
// set the size of the form
int windowWidth = 900;       
int windowHeight = 600;      

// set the Y-axis Min and Max for both
// the top and bottom trends
float InScaleMin = 0;       
float InScaleMax = 1024;   
float OutScaleMin = 0;    
float OutScaleMax = 100; 

// number of mS into the past you want to display
// how often you want the graph to be reDrawn;
int windowSpan = 300000;     
int refreshRate = 1000;      

// comment out all but one option
//float displayFactor = 1;     //display Time as Milliseconds
//float displayFactor = 1000;  //display Time as Seconds
float displayFactor = 60000; //display Time as Minutes

// if you'd like to output data to 
// a file, specify the path here
String outputFileName = "";  

// set to true for verbose debug option
boolean debug = true;

/***********************************************
 * end user spec
 **********************************************/
 
long nextRefresh;
int arrayLength = windowSpan / refreshRate + 1;
float[] InputData = new float[arrayLength];     // we might not need them this big, but
float[] SetpointData = new float[arrayLength];  // this is worst case
float[] OutputData = new float[arrayLength];

long startTime;

float inputTop = 25;
float inputHeight = (windowHeight - 70) * 2/3;
float outputTop = inputHeight + 50;
float outputHeight = (windowHeight - 70) * 1/3;

float ioLeft = 180, ioWidth = windowWidth - ioLeft - 50;
float ioRight = ioLeft + ioWidth;
float pointWidth = (ioWidth) / float(arrayLength - 1);

int vertCount = 10;
int nPoints = 0;
float Input, Setpoint, Output;

boolean madeContact = false;
boolean portOpen = false;

/*
int baudRateIndex = 0;
int[] baudRates = { 9600, 19200, 38400, 57600, 115200 };
*/

// order of these methods must match 
// the method indices in class PID_ATune
String[] ATmethod = {
  "Ziegler-Nichols PI",
  "Ziegler-Nichols PID",
  "Tyreus-Luyben PI",
  "Tyreus-Luyben PID",
  "Ciancone-Marlin PI",
  "Ciancone-Marlin PID",
  "Pessen Integral PID",
  "Some Overshoot PID",
  "No Overshoot PID",
  "AMIGOf PI",
};
int ATmethodIndex = 0;

Serial myPort = null;

ControlP5 controlP5;
controlP5.Button AMButton, DRButton, 
  ATButton, ConnectButton,
  AlarmEnableButton, AutoResetButton,
  SavePreferencesButton,
  ProfButton, ProfCmd;
controlP5.Textlabel 
  AMCurrent, InLabel, OutLabel, SPLabel, 
  MinLabel, MaxLabel,
  AlarmEnableCurrent, AutoResetCurrent,
  PLabel, ILabel, DLabel, DRCurrent, 
  ATmethodLabel, PowLabel,
  oSLabel, nLabel, ATCurrent, lbLabel, 
  specLabel, calLabel, winLabel,
  profSelLabel, profLabel, powerLabel;
RadioButton 
  portRadioButton, 
/*
  speedRadioButton, 
*/
  sensorRadioButton, profileRadioButton,
  powerRadioButton, ATmethodRadioButton; 
ListBox LBPref;
String[] CommPorts;
String[] prefs;
float[] prefVals;
controlP5.Textfield SPField, InField, OutField, 
  AlarmEnableField, MinField, MaxField, AutoResetField,
  PField, IField, DField, 
  oSField, nField, lbField, 
  calField, winField,
  oSecField;
String pHold = "", iHold = "", dHold = "";
PrintWriter output;
PFont AxisFont, TitleFont, ProfileFont; 

int dashTop, dashLeft = 10, dashW = 160, dashH = 155;
int fieldW = 90, alarmTop = 400, alarmH = 155; 
int tuneTop, tuneLeft = 10, tuneW = 160, tuneH = 155;
int ATTop, ATLeft = 10, ATW = 160, ATH = 155;
int commTop = 30, commLeft = 10, commW = 160, commH = 180; 
int configTop = 30, configLeft = 10, configW = 160, configH = 105;
int profW = 160, profH;
//int RsTop = configTop + 2 * configH + 30, RsLeft = 10, RsW = 160, RsH = 30;

// keeps track of which tab is selected so we know 
// which bounding rectangles to draw
int currentTab = 1;

int dashStatus = 0;
int profStatus = 0;

boolean tripped = false;
boolean alarmOn = false;
boolean alarmAutoReset = false;
float tripLowerLimit= -999.99;
float tripUpperLimit= -999.99;

int sensor = 0;
float calibration = 0.0;

int profileExportNumber = 0;
int storedProfileExportNumber = 0;

int powerOption = 0;

BufferedReader reader;

LinkedList<Msg> msgQueue = new LinkedList<Msg>();



void setup()
{
  size(100, 100);
  frameRate(30);

  // read in preferences
  prefs = new String[] 
  {
    "Form Width", 
    "Form Height", 
    "Input Scale Minimum",
    "Input Scale Maximum",
    "Output Scale Minimum",
    "Output Scale Maximum", 
    "Time Span (Min)"        
  };   
  prefVals = new float[] 
  {
    windowWidth, 
    windowHeight, 
    InScaleMin, 
    InScaleMax, 
    OutScaleMin, 
    OutScaleMax, 
    windowSpan / 1000 / 60        
  };
  try
  {
    reader = createReader("prefs.txt");
    if (reader != null)
    {
      for (int i = 0; i < prefVals.length; i++)
        prefVals[i] = float(reader.readLine());
    } 
  }
  catch(FileNotFoundException ex)  
  {    
    println("File not found when loading preferences");   
  }
  catch(IOException ex)  
  {    
    println("IO error when loading preferences");   
  }

  PrefsToVals(); // read pref array into global variables

  ReadProfiles(sketchPath("") + File.separator + "profiles");


  controlP5 = new ControlP5(this);                                  // * Initialize the various

  // initialize UI
  createTabs();
  populateDashTab();
  populateTuneTab();
  populateConfigTab();
  populatePrefTab();
  populateProfileTab();

  AxisFont = loadFont("axis.vlw");
  TitleFont = loadFont("Titles.vlw");
  ProfileFont = loadFont("profilestep.vlw");

  //blank out data fields since we're not connected
  Nullify();
  nextRefresh = millis();
  if (outputFileName != "") 
    output = createWriter(outputFileName);
}

void draw()
{
  ProfileRunTime();

  background(200);
  strokeWeight(1);
  drawButtonArea();
  AdvanceData();
  
  if (alarmAutoReset && (Input >= tripLowerLimit) && (Input <= tripUpperLimit))
  {
    tripped = false;
  }
  if (tripped)
  {
    // FIXME
    // audible alert?
    // flash input field, alarm OFF button, something on graph page?
    if ((int)(millis() & 1024) == 0)
    {
      InField.setColor(ControlP5.RED);
      AlarmEnableButton.setColor(ControlP5.RED);
    }
    else
    {  
      InField.setColor(ControlP5.CP5BLUE);
      AlarmEnableButton.setColor(ControlP5.CP5BLUE);
    }
  }
  
  if ((currentTab == 5) && (curProf > -1))
    DrawProfile(profs[curProf], ioLeft + 4, inputTop, ioWidth - 1, inputHeight);
  else 
    drawGraph();
}

//puts a "---" into all live fields when we're not connected
boolean dashNull = false, tuneNull = false;
void Nullify()
{

  String[] names = 
  {
    //"Set_Value", 
    //"Process_Value", 
    //"Output", 
    "AMCurrent", 
    "SV", 
    "PV", 
    "Out", 
    "AlarmEnableCurrent",
    //"Alarm_Min",
    //"Alarm_Max",
    "Min",
    "Max",
    "AutoResetCurrent",
    //"Kp",
    //"Ki",
    //"Kd",
    "P",
    "I",
    "D",
    "DRCurrent",
    "ATuneCurrent",
    //"Output_Step",
    //"Noise_Band",
    //"Look_Back",
    "oStep",
    "noise",
    "lback",
    //"Calibration",
    //"Window",
    "cal",
    "win"  
  }; 
  for (int i = 0; i < names.length; i++)
    controlP5.controller(names[i]).setValueLabel("---");
  dashNull = true;
  tuneNull = true;
}

//draws bounding rectangles based on the selected tab
void drawButtonArea()
{
  stroke(0);
  fill(120);
  rect(0, 0, ioLeft, windowHeight);
  if (currentTab == 1) // dash
  {
    fill(80);
    rect(commLeft - 5, commTop - 5, commW + 10, commH + 40);   // serial ports
    /*
    rect(commLeft - 5, commTop - 5, commW + 10, commH + 60);   // serial ports / baud rate
    */
    fill(50, 160, 50);
    rect(dashLeft - 5, dashTop - 5, dashW + 10, dashH + 10);   // dashboard
    fill(80);
    rect(dashLeft - 5, alarmTop - 5, dashW + 10, alarmH + 10); // alarm menu items
    fill(160);
    rect(configLeft - 5, configTop + 485, configW + 10, 82);   // status
    fill(80);
    rect(configLeft + 5, configTop + 479, 35, 12);
  }
  else if (currentTab == 2) // tune
  {
    fill(80);
    rect(tuneLeft - 5, tuneTop - 5, tuneW + 10, tuneH + 10);
    rect(tuneLeft - 5, tuneTop + tuneH + 10, tuneW + 10, 140);
    rect(ATLeft - 5, ATTop - 5, ATW + 10, ATH + 10);
  }
  else if (currentTab == 3) // config
  {
    fill(80);
    rect(configLeft - 5, configTop - 5, configW + 10, configH + 10);
    rect(configLeft - 5, configTop + configH + 10, configW + 10, 45);
  }
  else if (currentTab == 5) // profile
  {
    fill(80);
    rect(configLeft - 5, configTop - 5, profW + 10, profH + 30);
    rect(configLeft - 5, configTop + profH + 30, profW + 10, 145);
    rect(configLeft - 5, configTop + profH + 180, profW + 10, 70);
    fill(160);
    rect(configLeft - 5, configTop + 485, profW + 10, 82);
    fill(80);
    rect(configLeft + 5, configTop + 479, 35, 12);    
  }
}
