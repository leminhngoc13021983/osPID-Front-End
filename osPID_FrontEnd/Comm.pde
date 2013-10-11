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
          Msg m = new Msg(Token.IDENTIFY, NO_ARGS);
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
      //println(LastError);
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

int currentxferStep = -1;
void processCommand(String[] c)
{
  char symbol = c[0].charAt(0);
  if (symbol == Token.SET_VALUE.symbol)
    SPField.setText(c[1]);
  else if (symbol == Token.OUTPUT.symbol)
    OutField.setText(c[1]);
  else if (symbol == Token.AUTO_CONTROL.symbol)
    AMCurrent.setValue(int(c[1]) == 1 ? "Automatic" : "Manual"); // current rather than label... I think?
  else if (symbol == Token.ALARM_ON.symbol)
    AlarmEnableCurrent.setValue(int(c[1]) == 0 ? "Alarm OFF" : "Alarm ON" );
  else if (symbol == Token.ALARM_MIN.symbol)
    MinField.setText(c[1]);
  else if (symbol == Token.ALARM_MAX.symbol)
    MaxField.setText(c[1]);
  else if (symbol == Token.ALARM_AUTO_RESET.symbol)
    AutoResetCurrent.setValue(int(c[1]) == 0 ? "Manual Reset" : "Auto Reset" );
  else if (symbol == Token.KP.symbol)
    PField.setText(c[1]);
  else if (symbol == Token.KI.symbol)
    IField.setText(c[1]);
  else if (symbol == Token.KD.symbol)
    DField.setText(c[1]);
  else if (symbol == Token.REVERSE_ACTION.symbol)
    DRCurrent.setValue(int(c[1]) == 0 ? "Direct Action" : "Reverse Action" );
  else if (symbol == Token.AUTO_TUNE_ON.symbol)
    ATCurrent.setValue(int(c[1]) == 0 ? "Auto Tune OFF" : "Auto Tune ON" );
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
    winField.setText(c[1]);
}

void query(Token t)
{
  Msg m = new Msg(t, QUERY);
  if (!m.queue(msgQueue))
    throw new NullPointerException("Invalid command");
}

String InputCreateReq = "", OutputCreateReq = "";
//take the string the arduino sends us and parse it
void serialEvent(Serial myPort)
{
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
    
    // query profile stuff
  }
  if (!madeContact) 
    return;
    
  if (o[0] == "OK") // acknowledgement of successful command
  {
    processCommand(c);
    // now find msg and remove from queue
  }  
  else if (s[0].charAt(1) == '?') // response to query
  {
    processCommand(s);
  }
  else // don't know what
  {
    // ignore
    return;
  }
  
  // old code
  /*
  if((s.length > 3) && (s[0].equals("PROF")))
  {
    lastReceipt = millis();
    int curType = int(trim(s[2]));
    curProfStep = int(s[1]);
    ProfCmd.setCaptionLabel("Stop Profile");
    String[] msg;
    switch(curType)
    {
    case 1: //ramp
      msg = new String[]
      {
        "Running Profile", 
        "", 
        "Step = " + s[1] + ", Ramping Setpoint", 
        float(trim(s[3])) / 1000 + " Sec remaining"            
      };
      break;
    case 2: //wait
      float helper = float(trim(s[4]));
      msg = new String[]
      {
        "Running Profile", 
        "",
        "Step = " + s[1] + ", Waiting",
        "Distance Away= " + s[3],
        (helper < 0 ? "Waiting for cross" : ("Time in band= " + helper / 1000 + " Sec" ))            
      };
      break;
    case 3: //step
      msg = new String[]
      {
        "Running Profile", 
        "",
        "Step=" + s[1] + ", Stepped Setpoint",
        " Waiting for "+ float(trim(s[3])) / 1000 + " Sec"            
      };
      break;

    default:
      msg = new String[0];
      break;
    }
    populateStat(msg);
  }
  else if(trim(s[0]).equals("P_DN"))
  {
    lastReceiptTime = millis() - 10000;
    ProfileRunTime();
  }

  if((s.length == 5) && (s[0].equals("ProfAck")))
  {
    lastReceiptTime = millis();
    String[] profInfo = new String[]
    {
      "Transferring Profile",
      "Step "+s[1]+" successful"            
    };
    populateStat(profInfo);
    currentxferStep = int(s[1]) + 1;
    if(currentxferStep < pSteps) 
      SendProfileStep(byte(currentxferStep));
    else if(currentxferStep >= pSteps) 
      SendProfileName();
  }
  else if(s[0].equals("ProfDone"))
  {
    lastReceiptTime = millis() + 7000;//extra display time
    String[] profInfo = new String[]
    {
      "Profile Transfer",
      "Profile Sent Successfully"        
    };
    populateStat(profInfo);
    currentxferStep = 0;
  }
  else if(s[0].equals("ProfError"))
  {
    lastReceiptTime = millis() + 7000;//extra display time
    String[] profInfo = new String[]
    {
      "Profile Transfer",
      "Error Sending Profile"            
    };
    populateStat(profInfo);
  }
  */
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
