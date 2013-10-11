void controlEvent(ControlEvent theControlEvent) 
{
  if (theControlEvent.isTab()) 
  { 
    currentTab = theControlEvent.tab().id();
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
    // update value of sensor
    sensor = (int)theControlEvent.group().value();
    // queue command to microcontroller to update value of sensor
    String[] args = {Integer.toString(sensor)};
    Msg m = new Msg(Token.SENSOR, args);
    if (!m.queue(msgQueue))
      throw new NullPointerException("Invalid command");
    
    // update calibration value
    calibration = 0.0;
    // nullify calibration text label
    calLabel.setValueLabel("---");
    // queue query to microcontroller to request calibration value
    m = new Msg(Token.CALIBRATION, QUERY);
    if (!m.queue(msgQueue))
      //throw new NullPointerException("Invalid command");
      println("Invalid command");
    
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
  Msg m = new Msg(token, args);
  if (!m.queue(msgQueue))
    throw new NullPointerException("Invalid command");
  String cmd = token.symbol + " " + join(args, " ");
  //updateDashStatus(cmd);
  // return true;
  
  sendAll(msgQueue, myPort);
  
  // debug
  ListIterator m1 = msgQueue.listIterator();
  String c1;
  int i1 = 0;
  while (m1.hasNext() && i1 < 6)
  {
    Msg nextMsg1 = (Msg)m1.next();
    c1 = nextMsg1.getToken().symbol + " " + join(nextMsg1.getArgs(), " ");
    if (nextMsg1.sent())
      c1 = c1 + "s";
    else if (nextMsg1.markedReadyToSend())
      c1 = c1 + "r";
    else  if (nextMsg1.queued())
      c1 = c1 + "q";
    ((controlP5.Textlabel)controlP5.controller("dashstat" + i1)).setStringValue(c1);
    i1++;
  }
  for (int i2=i1;i2<6;i2++)
  {
   ((controlP5.Textlabel)controlP5.controller("dashstat" + i2)).setStringValue("");
  } 
  
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
    // updateDashStatus("Input error");
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
    // updateDashStatus("Input error");
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
  if(AMButton.getCaptionLabel().getText() == "Set PID Control") 
  {
    AMLabel.setValue("PID Control");        
    AMButton.setCaptionLabel("Set Manual Control");  
    sendCmdInteger(Token.AUTO_CONTROL, 1);
  }
  else
  {
    AMLabel.setValue("Manual Control");   
    AMButton.setCaptionLabel("Set PID Control");  
    sendCmdInteger(Token.AUTO_CONTROL, 0);
  }
}

void Alarm_Enable() 
{
  if(AlarmEnableButton.getCaptionLabel().getText() == "Set Alarm Off") 
  {
    AlarmEnableLabel.setValue("Alarm OFF");  
    AlarmEnableButton.setCaptionLabel("Set Alarm On"); 
    sendCmdInteger(Token.ALARM_ON, 0);
  }
  else
  {
    AlarmEnableLabel.setValue("Alarm ON");     
    AlarmEnableButton.setCaptionLabel("Set Alarm Off"); 
    sendCmdInteger(Token.ALARM_ON, 1);
  }
}

void Alarm_Min(String theText)
{
  sendCmdFloat(Token.ALARM_MIN, theText, 1);
}

void Alarm_Max(String theText)
{
  sendCmdFloat(Token.ALARM_MAX, theText, 1);
}

void Alarm_Reset() 
{
  if(AutoResetButton.getCaptionLabel().getText() == "Set Manual Reset") 
  {
    AutoResetLabel.setValue("Manual Reset");
    AutoResetButton.setCaptionLabel("Set Auto Reset"); 
    sendCmdInteger(Token.ALARM_AUTO_RESET, 0);
  }
  else
  {
    AutoResetLabel.setValue("Auto Reset");  
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
  if(DRButton.getCaptionLabel().getText()== "Set Reverse Action") 
  {
    DRLabel.setValue("Reverse Action");  
    DRButton.setCaptionLabel("Set Direct Action"); 
    sendCmdInteger(Token.REVERSE_ACTION, 1);
  }
  else
  {
    DRLabel.setValue("Direct Action");     
    DRButton.setCaptionLabel("Set Reverse Action"); 
    sendCmdInteger(Token.REVERSE_ACTION, 0);
  }
}

void AutoTune_On_Off() 
{
  if(ATButton.getCaptionLabel().getText() == "Set Auto Tune Off") 
  {
    ATLabel.setValue("Auto Tune OFF");
    ATButton.setCaptionLabel("Set Auto Tune On");  
    sendCmdInteger(Token.AUTO_TUNE_ON, 0);
  }
  else
  {
    ATLabel.setValue("Auto Tune ON");   
    ATButton.setCaptionLabel("Set Auto Tune Off");
    sendCmdInteger(Token.AUTO_TUNE_ON, 1);
  }
}

void Output_Step(String theText)
{  
  String[] args = {""};
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
    // updateDashStatus("Input error");
    return; // return false;
  }
  //oSLabel.setValue(nf(n, 0, 1)); // must wait for acknowledgment
  sendCmd(Token.AUTO_TUNE_PARAMETERS, args);
}

void Noise_Band(String theText)
{  
  String cmd;
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
    // updateDashStatus("Input error");
    return; // return false;
  }
  //nLabel.setValue(nf(n, 0, 1)); // must wait for acknowledgment
  sendCmd(Token.AUTO_TUNE_PARAMETERS, args);
}

void Look_Back(String theText)
{  
  String cmd;
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
    // updateDashStatus("Input error");
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

void Send_Profile()
{
  // FIXME
  currentxferStep=0;
  SendProfileStep(byte(currentxferStep), myPort);
}

void SendProfileStep(byte step, Serial myPort)
{
  ProfileState s = profs[curProf].step[step];
  
  // FIXME queue message 
  sendAll(msgQueue, myPort);
}

void SendProfileName(Serial myPort)
{
  byte identifier = 7;
  byte[] toSend = new byte[9];
  toSend[0] = identifier;
  toSend[1] = byte(currentxferStep);
  try
  {
    byte[] n = profs[curProf].Name.getBytes();
    int copylen = (n.length > NAME_LENGTH)? NAME_LENGTH : n.length;
    for(int i = 0; i < NAME_LENGTH; i++) 
      toSend[i + 2] = (i < copylen) ? n[i] : (byte)' ';
  }
  catch(Exception ex)
  {
    print(ex.toString());
  }
  
  // FIXME queue message 
  sendAll(msgQueue, myPort);
}

void Run_Profile()
{
  // FIXME
  byte[] toSend = new byte[2];
  toSend[0] = 8;
  if (ProfCmd.getCaptionLabel().getText() == "Run Profile") // run profile
  {
    toSend[1] = 1;
  }
  else // stop profile
  {
    toSend[1] = 0;
  }
  myPort.write(toSend);
}
      













