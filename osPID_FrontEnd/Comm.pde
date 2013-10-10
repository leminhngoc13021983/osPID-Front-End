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
  else // madeContact
  {
    myPort.stop();
    madeContact = false;
    ConnectButton.setCaptionLabel("Connect"); 
    //ClearInput();
    //ClearOutput();
    Nullify();
  } 
}

void Run_Profile()
{
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

void Send_Profile()
{
  currentxferStep=0;
  SendProfileStep(byte(currentxferStep));
}

int currentxferStep = -1;

void SendProfileStep(byte step)
{
  byte identifier = 7;
  Profile p = profs[curProf];
  float[] temp = new float[2];
  temp[0] = p.vals[step];
  temp[1] = p.times[step];

  byte[] toSend = new byte[11];
  toSend[0] = identifier;
  toSend[1] = step;
  toSend[2] = p.types[step];
  //arraycopy(floatArrayToByteArray(temp), 0, toSend, 3, 8);
  myPort.write(toSend);
}

void SendProfileName()
{
  byte identifier = 7;
  byte[] toSend = new byte[9];
  toSend[0] = identifier;
  toSend[1] = byte(currentxferStep);
  try
  {
    byte[] n = profs[curProf].Name.getBytes();
    int copylen = n.length>7? 7:n.length;
    for(int i = 0; i < 7; i++) 
      toSend[i + 2] = (i < copylen ? n[i] : 32);
  }
  catch(Exception ex)
  {
    print(ex.toString());
  }
  myPort.write(toSend);
}

void processCommand(String[] c)
{
  char symbol = c[0].charAt(0);
  if (symbol == Token.AUTO_CONTROL.symbol)
    AMCurrent.setValue(int(c[1]) == 1 ? "Automatic" : "Manual");
  else if (symbol == Token.SET_VALUE.symbol)
    SPField.setText(c[1]);
  else if (symbol == Token.OUTPUT.symbol)
    OutField.setText(c[1]);
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
  else if (symbol == Token.CALIBRATION.symbol)
  {
    calibration = float(c[1]);
    calField.setText(c[1]);
  }
  else if (symbol == Token.OUTPUT_CYCLE.symbol)
    winField.setText(c[1]);
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

  if ((c[0].charAt(0) == Token.IDENTIFY.symbol) && o[0].equals("osPID"))
  {
    // made connection
    ConnectButton.setCaptionLabel("Disconnect");
    madeContact = true;
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
  if((s.length > 3) && (s[0].equals("PROF")))
  {
    lastReceiptTime=millis();
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
}

void populateStat(String[] msg)
{
  for(int i = 0; i < 6; i++)
  {
    //((controlP5.Textlabel)controlP5.controller("dashstat" + i)).setValue(i < msg.length ? msg[i] : "");
    ((controlP5.Textlabel)controlP5.controller("profstat" + i)).setValue(i < msg.length ? msg[i] : "");
  }
}



