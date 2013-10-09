void sendCmdFloat(String cmd, String theText, int decimals)
{
  try
  {
    cmd = cmd + " " + nf(Float.valueOf(theText).floatValue(), 0, decimals);
  }
  catch(NumberFormatException ex)
  {
    // updateDashStatus("Input error");
    return; // return false;
  }
  // myPort.write(cmd);
  updateDashStatus(cmd);
  // return true;
}

void Set_Value(String theText)
{
  sendCmdFloat("S", theText, 1);
}

void Process_Value(String theText)
{
  // do nothing, even if we get here
}

void Output(String theText)
{
  // send output (only makes sense in manual mode)
  sendCmdFloat("O", theText, 1);
}

void Auto_Manual() 
{
  String cmd;
  if(AMButton.getCaptionLabel().getText() == "Set PID Control") 
  {
    AMLabel.setValue("PID Control");        
    AMButton.setCaptionLabel("Set Manual Control");  
    cmd = "M 1";
  }
  else
  {
    AMLabel.setValue("Manual Control");   
    AMButton.setCaptionLabel("Set PID Control"); 
    cmd = "M 0";
  }
  //myPort.write(cmd);
  updateDashStatus(cmd);
}

void Alarm_Enable() 
{
  String cmd;
  if(AlarmEnableButton.getCaptionLabel().getText() == "Set Alarm Off") 
  {
    AlarmEnableLabel.setValue("Alarm OFF");  
    AlarmEnableButton.setCaptionLabel("Set Alarm On"); 
    cmd = "L 0"; 
  }
  else
  {
    AlarmEnableLabel.setValue("Alarm ON");     
    AlarmEnableButton.setCaptionLabel("Set Alarm Off");  
    cmd = "L 1";
  }
  //myPort.write(cmd);
  updateDashStatus(cmd);
}

void Alarm_Min(String theText)
{
  sendCmdFloat("l", theText, 1);
}

void Alarm_Max(String theText)
{
  sendCmdFloat("u", theText, 1);
}

void Alarm_Reset() 
{
  String cmd;
  if(AutoResetButton.getCaptionLabel().getText() == "Set Manual Reset") 
  {
    AutoResetLabel.setValue("Manual Reset");
    AutoResetButton.setCaptionLabel("Set Auto Reset");
    cmd = "t 0";
  }
  else
  {
    AutoResetLabel.setValue("Auto Reset");  
    AutoResetButton.setCaptionLabel("Set Manual Reset"); 
    cmd = "t 1";
  }
  //myPort.write(cmd);
  updateDashStatus(cmd);
}

void Kp(String theText)
{
  sendCmdFloat("p", theText, 3);
}

void Ki(String theText)
{
  sendCmdFloat("i", theText, 3);
}

void Kd(String theText)
{
  sendCmdFloat("d", theText, 3);
}

void Direct_Reverse() 
{
  String cmd;
  if(DRButton.getCaptionLabel().getText()== "Set Reverse Action") 
  {
    DRLabel.setValue("Reverse Action");  
    DRButton.setCaptionLabel("Set Direct Action"); 
    cmd = "R 1";
  }
  else
  {
    DRLabel.setValue("Direct Action");     
    DRButton.setCaptionLabel("Set Reverse Action"); 
    cmd = "R 0";
  }
  //myPort.write(cmd);
  updateDashStatus(cmd);
}

void AutoTune_On_Off() 
{
  String cmd;
  if(ATButton.getCaptionLabel().getText() == "Set Auto Tune Off") 
  {
    ATLabel.setValue("Auto Tune OFF");
    ATButton.setCaptionLabel("Set Auto Tune On");  
    cmd = "A 0";
  }
  else
  {
    ATLabel.setValue("Auto Tune ON");   
    ATButton.setCaptionLabel("Set Auto Tune Off");
    cmd = "A 1";
  }
  //myPort.write(cmd);
  updateDashStatus(cmd);
}

void Output_Step(String theText)
{  
  String cmd;
  Float n;
  try
  {
    n = Float.valueOf(theText).floatValue();
    cmd = "a " + nf(n, 0, 1) + 
    " " + nf(Float.valueOf(nLabel.getStringValue()).floatValue(), 0, 1) + 
    " " + nf(Float.valueOf(lbLabel.getStringValue()).floatValue(), 0, 0);
  }
  catch(NumberFormatException ex)
  {
    // updateDashStatus("Input error");
    return; // return false;
  }
  oSLabel.setValue(nf(n, 0, 1));
  //myPort.write(cmd);
  updateDashStatus(cmd);
}

void Noise_Band(String theText)
{  
  String cmd;
  Float n;
  try
  {
    n = Float.valueOf(theText).floatValue();
    cmd = "a " + nf(Float.valueOf(oSLabel.getStringValue()).floatValue(), 0, 1) + 
    " " + nf(n, 0, 1) + 
    " " + nf(Float.valueOf(lbLabel.getStringValue()).floatValue(), 0, 0);
  }
  catch(NumberFormatException ex)
  {
    // updateDashStatus("Input error");
    return; // return false;
  }
  nLabel.setValue(nf(n, 0, 1));
  //myPort.write(cmd);
  updateDashStatus(cmd);
}

void Look_Back(String theText)
{  
  String cmd;
  Float n;
  try
  {
    n = Float.valueOf(theText).floatValue();
    cmd = "a " + nf(Float.valueOf(oSLabel.getStringValue()).floatValue(), 0, 1) + 
    " " + nf(Float.valueOf(nLabel.getStringValue()).floatValue(), 0, 0) + 
    " " + nf(n, 0, 0);
  }
  catch(NumberFormatException ex)
  {
    // updateDashStatus("Input error");
    return; // return false;
  }
  lbLabel.setValue(nf(n, 0, 0));
  //myPort.write(cmd);
  updateDashStatus(cmd);
}

void updateDashStatus(String update)
{
  if (dashStatus < 5)
  {
    ((controlP5.Textlabel)controlP5.controller("dashstat" + dashStatus)).setValue(update);
    dashStatus++;
  }
  else
  {
    for (int i = 0; i < 5; i++)
    {
      ((controlP5.Textlabel)controlP5.controller("dashstat" + i)).setValue(
        ((controlP5.Textlabel)controlP5.controller("dashstat" + i + 1)).getStringValue() // fails
      );
    }
    ((controlP5.Textlabel)controlP5.controller("dashstat5")).setValue(update);
  }
}
    
      













