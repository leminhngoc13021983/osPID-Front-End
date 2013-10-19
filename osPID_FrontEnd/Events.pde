  void controlEvent(ControlEvent theControlEvent) 
{
  if (theControlEvent.isTab()) 
  { 
    currentTab = theControlEvent.tab().id();
  }
  else if (theControlEvent.isFrom(speedRadioButton))
  {
    baudRateIndex = (int)theControlEvent.group().value();
  }
  else if (theControlEvent.isGroup() && (theControlEvent.group().name() == "Available Profiles"))
  {
    // a list item was clicked
    curProf = (int)theControlEvent.group().value();
    profSelLabel.setValue(profs[curProf].Name);
  }
  else if (theControlEvent.isFrom(sensorRadioButton))
  //else if (theControlEvent.isGroup() && (theControlEvent.group().name() == "sensorRadioButton"))
  {
    int oldSensor = sensor;
    // update value of sensor
    sensor = (int)theControlEvent.group().value();
    if (oldSensor == sensor)
      return;
      
    // queue command to microcontroller to update value of sensor
    String[] args = {Integer.toString(sensor)};
    Msg m = new Msg(Token.SENSOR, args, true);
    if (!m.queue(msgQueue))
      throw new NullPointerException("Invalid command" + Token.SENSOR.symbol + " " + join(args, " "));
    
    // update calibration value
    calibration = 0.0;
    // nullify calibration text label
    calLabel.setValueLabel("---");
    // queue query to microcontroller to request calibration value
    m = new Msg(Token.CALIBRATION, QUERY, true);
    if (!m.queue(msgQueue))
      throw new NullPointerException("Invalid command: " + Token.PROFILE_SAVE.symbol + "?");
    
    // send messages
    sendAll(msgQueue, myPort);
  }
  else if (theControlEvent.isFrom(profileRadioButton))
  {
    profileExportNumber = (int)theControlEvent.group().value();
  }
  else if (theControlEvent.isFrom(powerRadioButton))
  {
    int oldPowerOption = powerOption;
    // update value of power on option
    powerOption = (int)theControlEvent.group().value();
    if (oldPowerOption == powerOption)
      return;
      
    // queue command to microcontroller to update power on option
    String[] args = {Integer.toString(powerOption)};
    Msg m = new Msg(Token.POWER_ON, args, true);
    if (!m.queue(msgQueue))
      throw new NullPointerException("Invalid command" + Token.SENSOR.symbol + " " + join(args, " "));
    
    // send messages
    sendAll(msgQueue, myPort);
  }
  /*
  // debug
  else if (theControlEvent.isFrom(portRadioButton))
  {
    // do nothing
  }
  else if (theControlEvent.isFrom(speedRadioButton))
  {
    // do nothing
  }
  else
    println("unprocessed control event"); 
  */
}

void sendCmd(Token token, String[] args)
{
  Msg m = new Msg(token, args, true);
  if (!m.queue(msgQueue))
    throw new NullPointerException("Invalid command: " + token.symbol + " " + join(args, " "));
  
  sendAll(msgQueue, myPort);
  
  // debug
  updateDashQueue();
}

void sendCmdFloat(Token token, String theText, int decimals)
{
  String[] args = {""};
  try
  {
    args[0] = nf(Float.valueOf(theText).floatValue(), 0, decimals);
  }
  catch(NumberFormatException ex)
  {
    if (debug)
      println("Input error");
    return; // return false;
  }
  sendCmd(token, args);
}

void sendCmdInteger(Token token, int value)
{
  String[] args = {""};
  try
  {
    args[0] = nf(value, 0, 0);
  }
  catch(NumberFormatException ex)
  {
    if (debug)
      println("Input error");
    return; // return false;
  }
  sendCmd(token, args);
}

void Set_Value(String theText)
{
  sendCmdFloat(Token.SET_VALUE, theText, 1);
}

void Process_Value(String theText)
{
  // do nothing, even if we get here
}

void Output(String theText)
{
  // send output (only makes sense in manual mode)
  sendCmdFloat(Token.OUTPUT, theText, 1);
}

void Auto_Manual() 
{
  AMCurrent.setValue("---");
  if(AMButton.getCaptionLabel().getText() == "Set Automatic") 
  {        
    AMButton.setCaptionLabel("Set Manual Control");  
    sendCmdInteger(Token.AUTO_CONTROL, 1);
  }
  else
  {   
    AMButton.setCaptionLabel("Set Automatic");  
    sendCmdInteger(Token.AUTO_CONTROL, 0);
  }
}

void Alarm_Enable() 
{
  AlarmEnableCurrent.setValue("---");
  if(AlarmEnableButton.getCaptionLabel().getText() == "Disable Alarm") 
  {
    alarmOn = false;
    tripped = false; // clear alarm  
    AlarmEnableButton.setCaptionLabel("Enable Alarm"); 
    sendCmdInteger(Token.ALARM_ON, 0);
  }
  else
  {
    alarmOn = true;    
    AlarmEnableButton.setCaptionLabel("Disable Alarm"); 
    sendCmdInteger(Token.ALARM_ON, 1);
  }
}

void Alarm_Min(String theText)
{
  tripLowerLimit = Float.valueOf(theText).floatValue();
  sendCmdFloat(Token.ALARM_MIN, theText, 1);
}

void Alarm_Max(String theText)
{
  tripUpperLimit = Float.valueOf(theText).floatValue();
  sendCmdFloat(Token.ALARM_MAX, theText, 1);
}

void Alarm_Reset() 
{
  AutoResetCurrent.setValue("---");
  if(AutoResetButton.getCaptionLabel().getText() == "Set Manual Reset") 
  {
    alarmAutoReset = false;
    AutoResetButton.setCaptionLabel("Set Auto Reset"); 
    sendCmdInteger(Token.ALARM_AUTO_RESET, 0);
  }
  else
  {
    alarmAutoReset = true;  
    AutoResetButton.setCaptionLabel("Set Manual Reset"); 
    sendCmdInteger(Token.ALARM_AUTO_RESET, 1);
  }
}

void Kp(String theText)
{
  sendCmdFloat(Token.KP, theText, 3);
}

void Ki(String theText)
{
  sendCmdFloat(Token.KI, theText, 3);
}

void Kd(String theText)
{
  sendCmdFloat(Token.KD, theText, 3);
}

void Direct_Reverse() 
{
  DRCurrent.setValue("---");
  if(DRButton.getCaptionLabel().getText()== "Set Reverse Action") 
  {
    DRButton.setCaptionLabel("Set Direct Action"); 
    sendCmdInteger(Token.REVERSE_ACTION, 1);
  }
  else
  {    
    DRButton.setCaptionLabel("Set Reverse Action"); 
    sendCmdInteger(Token.REVERSE_ACTION, 0);
  }
}

void AutoTune_On_Off() 
{
  ATCurrent.setValue("---");
  if(ATButton.getCaptionLabel().getText() == "Set Auto Tune OFF") 
  {
    ATButton.setCaptionLabel("Set Auto Tune ON");  
    sendCmdInteger(Token.AUTO_TUNE_ON, 0);
  }
  else
  {   
    ATButton.setCaptionLabel("Set Auto Tune OFF");
    sendCmdInteger(Token.AUTO_TUNE_ON, 1);
  }
}

void Output_Step(String theText)
{  
  String[] args = {"", "", ""};
  Float n;
  try
  {
    n = Float.valueOf(theText).floatValue();
    args[0] = nf(n, 0, 1);
    args[1] = nf(Float.valueOf(nLabel.getStringValue()).floatValue(), 0, 1);
    args[2] = nf(Float.valueOf(lbLabel.getStringValue()).floatValue(), 0, 0);
  }
  catch(NumberFormatException ex)
  {
    if (debug)
      println("Input error");
    return; // return false;
  }
  //oSLabel.setValue(nf(n, 0, 1)); // must wait for acknowledgment
  sendCmd(Token.AUTO_TUNE_PARAMETERS, args);
}

void Noise_Band(String theText)
{  
  String[] args = {"", "", ""};
  Float n;
  try
  {
    n = Float.valueOf(theText).floatValue();
    args[0] = nf(Float.valueOf(oSLabel.getStringValue()).floatValue(), 0, 1); 
    args[1] = nf(n, 0, 1);
    args[2] = nf(Float.valueOf(lbLabel.getStringValue()).floatValue(), 0, 0);
  }
  catch(NumberFormatException ex)
  {
    if (debug)
      println("Input error");
    return; // return false;
  }
  //nLabel.setValue(nf(n, 0, 1)); // must wait for acknowledgment
  sendCmd(Token.AUTO_TUNE_PARAMETERS, args);
}

void Look_Back(String theText)
{  
  String[] args = {"", "", ""};
  Float n;
  try
  {
    n = Float.valueOf(theText).floatValue();
    args[0] = nf(Float.valueOf(oSLabel.getStringValue()).floatValue(), 0, 1); 
    args[1] = nf(Float.valueOf(nLabel.getStringValue()).floatValue(), 0, 1);
    args[2] = nf(n, 0, 1);
  }
  catch(NumberFormatException ex)
  {
    if (debug)
      println("Input error");
    return; // return false;
  }
  //lbLabel.setValue(nf(n, 0, 0)); // must wait for acknowledgment
  sendCmd(Token.AUTO_TUNE_PARAMETERS, args);
}

void Calibration(String theText)
{
  sendCmdFloat(Token.CALIBRATION, theText, 1);
}

void Window(String theText)
{
  sendCmdFloat(Token.OUTPUT_CYCLE, theText, 1);
}

void SendProfileName()
{
  // save profileExportNumber
  // storedProfileExportNumber holds the profile number
  // we will eventually export to
  storedProfileExportNumber = profileExportNumber;
  
  String[] args = {profs[curProf].Name};
  Msg m = new Msg(Token.PROFILE_NAME, args, true);
  if (!m.queue(msgQueue))
    throw new NullPointerException("Invalid command: " + Token.PROFILE_NAME.symbol + " " + join(args, " "));
  sendAll(msgQueue, myPort);
}

void Run_Profile()
{
  if (ProfCmd.getCaptionLabel().getText() == "Run Profile") // run profile
  {
    ProfCmd.setCaptionLabel("Stop Profile");
    sendCmdInteger(Token.PROFILE_EXECUTE_BY_NUMBER, curProf);
  }
  else // stop profile
  {
    ProfCmd.setCaptionLabel("Run Profile");
    sendCmd(Token.PROFILE_CANCEL, NO_ARGS);
  }
}
      













