String LastError = "";

void Connect()
{
  if (!madeContact)
  {
    try
    {
      LastError = "";
      ConnectButton.setCaptionLabel("Connecting...");  
      nPoints = 0;
      startTime = millis();
      for(int i = 0; i < CommPorts.length; i++)
      {
        if (portRadioButton.getItem(i).getState())
        {
          myPort = new Serial(this, CommPorts[i], baudRates[baudRateIndex]); 
          myPort.bufferUntil(10); 
          //immediately send a request for osPID type;
          Msg m = new Msg(Token.IDENTIFY, NO_ARGS, true);
          if (!m.queue(msgQueue))
            throw new Exception("Invalid command");
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
    ConnectButton.setCaptionLabel("Connect"); 
    Nullify();
  } 
}

void query(Token t)
{
  Msg m = new Msg(t, QUERY, true);
  if (!m.queue(msgQueue))
    throw new NullPointerException("Invalid command");
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
  query(Token.QUERY);
  sendAll(msgQueue, myPort); 
  delay(100);
    
  query(Token.AUTO_CONTROL);
  query(Token.ALARM_ON);
  query(Token.ALARM_MIN);
  query(Token.ALARM_MAX);
  query(Token.ALARM_AUTO_RESET);
  sendAll(msgQueue, myPort); 
  delay(100);
    
  query(Token.KP);
  query(Token.KI);
  query(Token.KD);
  query(Token.REVERSE_ACTION);
  query(Token.AUTO_TUNE_ON);
  query(Token.AUTO_TUNE_PARAMETERS);
  query(Token.OUTPUT_CYCLE);
  sendAll(msgQueue, myPort); 
  delay(100);
    
  query(Token.PROFILE_NAME);
  sendAll(msgQueue, myPort); 
}

void processResponse(String[] c, boolean acknowledgeCmd)
{
  char symbol = c[0].charAt(0);
  // would do switch() ... case: here 
  // but java doesn't like arbitrary case symbols
  if (symbol == Token.SET_VALUE.symbol)
  {
    Setpoint = Float.valueOf(c[1]).floatValue();
    SPField.setText(nf(Setpoint, 0, 1));
  }
  else if (symbol == Token.OUTPUT.symbol)
  {
    Output = Float.valueOf(c[1]).floatValue();
    OutField.setText(nf(Output, 0, 1));
  }
  else if (symbol == Token.INPUT.symbol)
  {
    Input = Float.valueOf(c[1]).floatValue();
    InField.setText(nf(Input, 0, 1));
  }
  else if (symbol == Token.AUTO_CONTROL.symbol)
  {
    AMCurrent.setValue(int(c[1]) == 1 ? "Automatic" : "Manual"); // current rather than label... I think?
  }
  else if (symbol == Token.ALARM_ON.symbol)
  {
    AlarmEnableCurrent.setValue(int(c[1]) == 0 ? "Alarm OFF" : "Alarm ON" );
  }
  else if (symbol == Token.ALARM_MIN.symbol)
  {
    MinField.setText(c[1]);
  }
  else if (symbol == Token.ALARM_MAX.symbol)
  {
    MaxField.setText(c[1]);
  }
  else if (symbol == Token.ALARM_AUTO_RESET.symbol)
  {
    AutoResetCurrent.setValue(int(c[1]) == 0 ? "Manual Reset" : "Auto Reset" );
  }
  else if (symbol == Token.KP.symbol)
  {
    PField.setText(c[1]);
  }
  else if (symbol == Token.KI.symbol)
  {
    IField.setText(c[1]);
  }
  else if (symbol == Token.KD.symbol)
  {
    DField.setText(c[1]);
  }
  else if (symbol == Token.REVERSE_ACTION.symbol)
  {
    DRCurrent.setValue(int(c[1]) == 0 ? "Direct Action" : "Reverse Action" );
  }
  else if (symbol == Token.AUTO_TUNE_ON.symbol)
  {
    ATCurrent.setValue(int(c[1]) == 0 ? "Auto Tune OFF" : "Auto Tune ON" );
  }
  else if (symbol == Token.AUTO_TUNE_PARAMETERS.symbol)
  {
    oSField.setText(c[1]);
    nField.setText(c[2]);
    lbField.setValue(c[3]);  
  } 
  else if (symbol == Token.SENSOR.symbol)
  {
    sensor = int(c[1]);
    sensorRadioButton.getItem(sensor).setState(true);
  }
  else if (symbol == Token.CALIBRATION.symbol)
  {
    calibration = float(c[1]);
    calField.setText(c[1]);
  }
  else if (symbol == Token.OUTPUT_CYCLE.symbol)
  {
    winField.setText(c[1]);
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
        profileRadioButton.getItem(i).setCaptionLabel(c[i + 1].replaceAll("^\"|\"$", ""));
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
    //activeProfileIndex = Integer.parseInt(c[1]);
    //runningProfile = true;
  }
  else
  {
    println("Unprocessed response");
    println(join(c, " "));
  }
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
          throw new NullPointerException("Invalid command");
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
    throw new NullPointerException("Invalid command");
  sendAll(msgQueue, myPort);
}

int currentxferStep = -1;
String InputCreateReq = "", OutputCreateReq = "";

//take the string the arduino sends us and parse it
void serialEvent(Serial myPort)
{
  // parse Serial input
  String read = myPort.readStringUntil(10);
  if (outputFileName != "") 
    output.print(str(millis()) + " " + read);
  String[] s = split(read, "::");
  String[] c = split(s[0], " ");
  String[] o = split(s[1], " ");
  print(read);

  if ((c[0].charAt(0) == Token.IDENTIFY.symbol) && o[0].equals("osPID")) // or whatever identifier
  {
    // made connection
    ConnectButton.setCaptionLabel("Disconnect");
    madeContact = true;
    // now query for information
    queryAll();
  }
  if (!madeContact) 
    return;
    
  if (o[0] == "ACK") // acknowledgement of successful command
  {
    processResponse(c, true);
    // now find msg and remove from queue
  }  
  else if ((c[0].charAt(1) == '?') && (o[0] == "OK")) // response to query
  {
    processResponse(s, false);
  }
  else // don't know what
  {
    // ignore
    return;
  }
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
