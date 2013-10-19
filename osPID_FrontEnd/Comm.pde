String LastError = "";

void Connect()
{
  if (!madeContact)
  {
    try
    {
      ConnectButton.lock();
      LastError = "";
      ConnectButton.setCaptionLabel("Connecting...");  
      nPoints = 0;
      startTime = millis();
      for(int i = 0; i < CommPorts.length; i++)
      {
        if (portRadioButton.getItem(i).getState())
        {
          // open new serial connection
          // this resets the arduino
          myPort = new Serial(this, CommPorts[i], baudRates[baudRateIndex]); 
          portOpen = true;
          myPort.bufferUntil(10); 
          
          // delay a little while until the arduino is ready to communicate
          delay(1000);
          
          // now send a request for osPID type;
          Msg m = new Msg(Token.IDENTIFY, NO_ARGS, true);
          if (!m.queue(msgQueue))
            throw new NullPointerException("Invalid command: " + Token.IDENTIFY.symbol);
          
          m = new Msg(Token.EXAMINE_SETTINGS, NO_ARGS, true);
          if (!m.queue(msgQueue))
            throw new NullPointerException("Invalid command: " + Token.EXAMINE_SETTINGS.symbol);
          sendAll(msgQueue, myPort);
          
          break;
        }
      }
    }
    catch (Exception ex)
    {
      LastError = ex.toString();
      println(LastError);
      ConnectButton.setCaptionLabel("Connect"); 
    } 
  }
  else // disconnect
  {
    myPort.stop();
    madeContact = false;
    portOpen = false;
    ConnectButton.setCaptionLabel("Connect"); 
    Nullify();
  } 
}

int currentxferStep = -1;
String lastRead = "";

//take the string the arduino sends us and parse it
void serialEvent(Serial myPort)
{
  // parse Serial input
  String read = myPort.readStringUntil(10).replace("\r\n","");
  if (outputFileName != "") 
    output.print(str(millis()) + " " + read);
  if (debug)
    print("I heard:" + read + "\n");

  String[] s = split(read, "::");
  if (s.length == 1)
  {
    lastRead = read;
    return;
  }
    
  String[] c = split(s[0], " ");
    
  if (s[1].equals("ACK")) // acknowledgement of successful command
  {
    processResponse(c[0].charAt(0), Arrays.copyOfRange(c, 1, c.length), true);
    // now find msg and remove from queue
    if (debug && !removeAcknowledged(msgQueue, c))
      println("Couldn't find msg to remove");
  }  
  else if (s[1].equals("OK")) // response to query
  {
    byte n = 0;
    String[] r = {"", "", ""};
    String regex = "\"([^\"]*)\"|(\\S+)";
    Matcher m = Pattern.compile(regex).matcher(lastRead);
    while (m.find())
    {
      if (m.group(1) != null) 
      {
        r[n] = m.group(1);
      } 
      else 
      {
        r[n] = m.group(2);
      }
      n++;
    }    
    processResponse(c[0].charAt(0), Arrays.copyOfRange(r, 0, n), false);
    if (debug && !removeAcknowledged(msgQueue, c))
      println("Couldn't find msg to remove");
  }
  else // don't know what
  {
    // ignore
    ;
  }
  lastRead = read;
}

void processResponse(char symbol, String[] c, boolean acknowledgeCmd)
{
  // would do switch() ... case: here 
  // but java doesn't like arbitrary case symbols
  if (symbol == Token.IDENTIFY.symbol)
  {
    String[] r = split(lastRead, " ");
    if (r.length < 2)
      return;
    if (!r[1].equals("Stripboard_osPID"))
      return;
      
    // made connection
    ConnectButton.unlock();
    ConnectButton.setCaptionLabel("Disconnect");
    madeContact = true;
    // now query for information
    queryAll();
    return;
  }
  if (!madeContact) 
    return;
    
  if (symbol == Token.SET_VALUE.symbol)
  {
    Setpoint = Float.valueOf(c[0]).floatValue();
    SPLabel.setText(nf(Setpoint, 0, 1));
  }
  else if (symbol == Token.OUTPUT.symbol)
  {
    Output = Float.valueOf(c[0]).floatValue();
    OutLabel.setText(nf(Output, 0, 1));
  }
  else if (symbol == Token.INPUT.symbol)
  {
    Input = Float.valueOf(c[0]).floatValue();
    InLabel.setText(nf(Input, 0, 1));
  }
  else if (symbol == Token.AUTO_CONTROL.symbol)
  {
    if (Integer.parseInt(c[0]) == 0)
    {
      AMCurrent.setValue("Manual"); 
      AMButton.setCaptionLabel("Set Automatic"); 
    }
    else
    {
      AMCurrent.setValue("Automatic"); 
      AMButton.setCaptionLabel("Set Manual Control"); 
    }
  }
  else if (symbol == Token.ALARM_ON.symbol)
  {
    if (Integer.parseInt(c[0]) == 0)
    {
      alarmOn = false;
      tripped = false;
      AlarmEnableCurrent.setValue("Alarm Disabled");
      AlarmEnableButton.setCaptionLabel("Enable Alarm"); 
    }
    else
    {
      alarmOn = true;
      AlarmEnableCurrent.setValue("Alarm Enabled");
      AlarmEnableButton.setCaptionLabel("Disable Alarm"); 
    }
  }
  else if (symbol == Token.ALARM_MIN.symbol)
  {
    tripLowerLimit = Float.valueOf(c[0]).floatValue();
    MinLabel.setText(c[0]);
  }
  else if (symbol == Token.ALARM_MAX.symbol)
  {
    tripUpperLimit = Float.valueOf(c[0]).floatValue();
    MaxLabel.setText(c[0]);
  }
  else if (symbol == Token.ALARM_AUTO_RESET.symbol)
  {
    if (Integer.parseInt(c[0]) == 0)
    {
      alarmAutoReset = false;
      AutoResetCurrent.setValue("Manual Reset");
      AutoResetButton.setCaptionLabel("Set Auto Reset");  
    }
    else
    {
      alarmAutoReset = true;
      AutoResetCurrent.setValue("Auto Reset");
      AutoResetButton.setCaptionLabel("Set Manual Reset"); 
    }
  }
  else if (symbol == Token.ALARM_STATUS.symbol)
  {
    tripped = (Integer.parseInt(c[0]) != 0);
  }
  else if (symbol == Token.KP.symbol)
  {
    PLabel.setText(c[0]);
  }
  else if (symbol == Token.KI.symbol)
  {
    ILabel.setText(c[0]);
  }
  else if (symbol == Token.KD.symbol)
  {
    DLabel.setText(c[0]);
  }
  else if (symbol == Token.REVERSE_ACTION.symbol)
  {
    if (Integer.parseInt(c[0]) == 0)
    {
      DRCurrent.setValue("Direct Action");
      DRButton.setCaptionLabel("Set Reverse Action"); 
    }
    else
    {
      DRCurrent.setValue("Reverse Action");
      DRButton.setCaptionLabel("Set Direct Action"); 
    }
  }
  else if (symbol == Token.AUTO_TUNE_ON.symbol)
  {
    if (Integer.parseInt(c[0]) == 0)
    {
      ATCurrent.setValue("Auto Tune OFF");
      ATButton.setCaptionLabel("Set Auto Tune ON");  
    }
    else
    {
      ATCurrent.setValue("Auto Tune ON");
      ATButton.setCaptionLabel("Set Auto Tune OFF");  
    }
  }
  else if (symbol == Token.AUTO_TUNE_PARAMETERS.symbol)
  {
    oSLabel.setText(c[0]);
    nLabel.setText(c[1]);
    lbLabel.setText(c[2]);  
  } 
  else if (symbol == Token.SENSOR.symbol)
  {
    sensor = Integer.parseInt(c[0]);
    sensorRadioButton.getItem(sensor).setState(true);
  }
  else if (symbol == Token.CALIBRATION.symbol)
  {
    calibration = Float.valueOf(c[0]).floatValue();
    calLabel.setText(c[0]);
  }
  else if (symbol == Token.OUTPUT_CYCLE.symbol)
  {
    winLabel.setText(c[0]);
  }
  else if (symbol == Token.PROFILE_NAME.symbol)
  {
    if (acknowledgeCmd)
    {
      // acknowledged send of profile name
      // begin transfer of profiles steps
      currentxferStep = 0;
      sendProfileStep((byte)currentxferStep);
    }
    else
    {
      for (int i = 0; i < 3; i++)
      {
        profileRadioButton.getItem(i).setCaptionLabel(c[i].replaceAll("^\"|\"$", ""));
      }
    }
  }
  else if (symbol == Token.PROFILE_STEP.symbol)
  {
    if (acknowledgeCmd)
    {
      exportProfileStep(c);
    }
    else
    {
      reportWhileRunningProfile(c);
      // keep counting elapsed using millis();
    }
  }
  else if (symbol == Token.PROFILE_SAVE.symbol) // not queryable
  {
    lastReceiptTime = millis() + 7000; // extra display time
    String[] profInfo = 
    {
      "Profile Transfer",
      "Profile Sent Successfully"        
    };
    populateStat(profInfo);
  }
  else if (symbol == Token.PROFILE_EXECUTE_BY_NUMBER.symbol) // not queryable
  {
    // FIXME
    //activeProfileIndex = Integer.parseInt(c[0]);
    //runningProfile = true;
  }
  else if (
    (symbol == Token.QUERY.symbol) ||
    (symbol == Token.EXAMINE_SETTINGS.symbol)
  ) // not queryable
  {
    // do nothing
  }
  else
  {
    println("Unprocessed response");
    println(join(c, " "));
  }
}

void query(Token t)
{
  Msg m = new Msg(t, QUERY, true);
  if (!m.queue(msgQueue))
    throw new NullPointerException("Invalid command " + t.symbol + "?");
}

void queryAll()
{
  // query for information
  // a little at a time and
  // give the arduino some time to respond
  // or else its input buffer may overflow
  query(Token.ALARM_STATUS);
  query(Token.SENSOR);
  query(Token.CALIBRATION);
  Msg m = new Msg(Token.QUERY, NO_ARGS, true);
  if (!m.queue(msgQueue))
    throw new NullPointerException("Invalid command: " + Token.QUERY);
  sendAll(msgQueue, myPort); 
  delay(50);
    
  query(Token.AUTO_CONTROL);
  query(Token.ALARM_ON);
  query(Token.ALARM_MIN);
  query(Token.ALARM_MAX);
  query(Token.ALARM_AUTO_RESET);
  sendAll(msgQueue, myPort); 
  delay(50);
    
  query(Token.KP);
  query(Token.KI);
  query(Token.KD);
  query(Token.REVERSE_ACTION);
  query(Token.AUTO_TUNE_ON);
  query(Token.AUTO_TUNE_PARAMETERS);
  query(Token.OUTPUT_CYCLE);
  sendAll(msgQueue, myPort); 
  delay(50);
    
  query(Token.PROFILE_NAME);
  sendAll(msgQueue, myPort); 
}

void exportProfileStep(String[] c)
{
  // check to see if type, duration, and target setpoint 
  // match those of the step recently sent
  ProfileState s = profs[curProf].step[currentxferStep];
  String[] profInfo;
  try
  {
    if (
      (Integer.parseInt(c[1]) == s.type) &
      (Integer.parseInt(c[2]) == s.duration) &&
      (Float.valueOf(c[3]).floatValue() == s.targetSetpoint)
    )
    {
      // successfully acknowledged transfer of previous step
      lastReceiptTime = millis();
      profInfo = new String[] {
        "Transferring Profile",
        "Step " + (currentxferStep + 1) + " successful"            
      };
      populateStat(profInfo);
      // next step
      currentxferStep++;
      if (currentxferStep < NR_STEPS) 
      {
        // send next step
        sendProfileStep((byte)currentxferStep);
      }
      else
      {
        // all steps sent
        // now save profile on microcontroller
        currentxferStep = 0;
        String[] args = {nf(storedProfileExportNumber, 0, 0)};
        Msg m = new Msg(Token.PROFILE_SAVE, args, true);
        if (!m.queue(msgQueue))
          throw new NullPointerException("Invalid command: " + Token.PROFILE_SAVE.symbol + " " + join(args, " "));
        sendAll(msgQueue, myPort);
      }
    }
    else
    {
      // unexpected profile step
      lastReceiptTime = millis() + 7000; // extra display time
      profInfo = new String[]
      {
        "Profile Transfer",
        "Error Sending Profile"            
      };
      populateStat(profInfo);
    }
  }
  catch(NumberFormatException ex)
  {
    println("Expected number, string format unexpected.");
    return;
  }
}

void sendProfileStep(byte step)
{
  ProfileState s = profs[curProf].step[step];
  String[] args = {nf(float(s.type), 0, 0), nf((float)s.duration, 0, 0), nf(s.targetSetpoint, 0, 1)};
  // resend = false because resent profile steps might end up in the wrong order
  Msg m = new Msg(Token.PROFILE_STEP, args, false); 
  if (!m.queue(msgQueue))
    throw new NullPointerException("Invalid command: " + Token.PROFILE_STEP.symbol + " " + join(args, " "));
  sendAll(msgQueue, myPort);
}
  
void reportWhileRunningProfile(String[] c) 
{
  int activeProfileIndex = Integer.parseInt(c[1]);
  int step = Integer.parseInt(c[2]);
  int type = Integer.parseInt(c[3]);
  float targetSetpoint = Float.valueOf(c[4]).floatValue();
  long time = Integer.parseInt(c[5]);
  
  lastReceiptTime = millis();
  String[] msg;
  if (type == ProfileStep.RAMP_TO_SETPOINT.code)
  {
    msg = new String[]
    {
      "Running Profile", 
      "", 
      "Ramping set value to " + targetSetpoint,
      float(int(time)) / 1000.0 + " Sec remaining"            
    };
  }
  else if (type == ProfileStep.WAIT_TO_CROSS.code)
  {
    msg = new String[]
    {
      "Running Profile", 
      "",
      "Waiting to cross set value" + Setpoint,           // FIXME what about when maximumError != 0
      "Distance Away= " + abs(Input - Setpoint),
      "Time elapsed = " + time / 1000 + " Sec"
    };
  }
  else if (type == ProfileStep.JUMP_TO_SETPOINT.code)
  {
    msg = new String[]
    {
      "Running Profile", 
      "",
      "Jumped to set value " + targetSetpoint,
      float(int(time)) / 1000 + " Sec remaining"
    };
  }
  else if (type == ProfileStep.SOAK_AT_VALUE.code)
  {
    msg = new String[]
    {
      "Running Profile", 
      "",
      "Soaking at " + targetSetpoint,
      float(int(time)) / 1000 + " Sec remaining"
    };
  }
  else
  {
    msg = new String[0];
  }
  populateStat(msg);
}

void populateStat(String[] msg)
{
  for(int i = 0; i < 6; i++)
  {
    //((controlP5.Textlabel)controlP5.controller("dashstat" + i)).setValue(i < msg.length ? msg[i] : "");
    ((controlP5.Textlabel)controlP5.controller("profstat" + i)).setValue(i < msg.length ? msg[i] : "");
  }
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
