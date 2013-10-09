String LastError = "";

void Connect()
{
  if(!madeContact)
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
          byte[] typeReq = new byte[]
          {
            0, 0                              
          };
          myPort.write(typeReq);
          
  /* Need to:
   *   identify osPID name and version and print it up top somewhere?
   */
   
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
    ClearInput();
    ClearOutput();
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

void Reset_Defaults()
{
  byte identifier = 4;
  myPort.write(identifier);
  myPort.write((byte)1); 
}

String InputCreateReq = "", OutputCreateReq = "";
//take the string the arduino sends us and parse it
void serialEvent(Serial myPort)
{
  String read = myPort.readStringUntil(10);
  if(outputFileName != "") 
    output.print(str(millis()) + " " + read);
  String[] s = split(read, " ");
  print(read);

  if((s.length == 4) && s[0].equals("osPID"))
  {
    if((InputCard == "") || !InputCard.equals(trim(s[2]))) 
      InputCreateReq = trim(s[2]);
    if((OutputCard == "") || !OutputCard.equals(trim(s[3]))) 
      OutputCreateReq = trim(s[3]);
    ConnectButton.setCaptionLabel("Disconnect");
    madeContact = true;
  }
  if(!madeContact) 
    return;
    
  if (s[0] == "OK:") // acknowledgement
  {
    switch(s[1].charAt(0)) // acknowledged send
    {
      case 'M':
        AMLabel.setValue(int(s[2]) == 1 ? "Automatic" : "Manual");
        break;
      case 'S':        
        SPField.setText(s[2]);
        break;
      case 'O':        
        OutField.setText(s[2]);
        break; 
      case 'p': 
        PField.setText(s[2]); 
        break; 
      case 'i':    
        IField.setText(s[2]); 
        break; 
      case 'd':    
        DField.setText(s[2]);
        break; 
      case 'R': 
        DRLabel.setValue(int(s[2]) == 0 ? "Direct" : "Reverse" );
        break; 
      case 'A': 
        ATLabel.setValue(int(s[2]) == 0 ? "OFF" : "ON" );
        break; 
      case 'a': 
        oSField.setText(s[2]);
        nField.setText(s[3]);
        lbField.setValue(s[4]);    
        break;         
      default: 
    } 
  }  
  else
  {
    switch (s[0].charAt(0)) // query command
    {
      case 'M':
        AMCurrent.setValue((int(s[1]) == 1) ? "Automatic" : "Manual"); 
        break;
      case 'S':        
        Setpoint = float(s[1]);
        SPLabel.setValue(s[1]); 
        break;
      case 'O':        
        Output = float(s[1]);
        OutLabel.setValue(s[1]); 
        break; 
      case 'p': 
        PLabel.setValue(s[1]);
        break; 
      case 'i': 
        ILabel.setValue(s[1]);
        break; 
      case 'd': 
        DLabel.setValue(s[1]);
        break; 
      case 'R': 
        DRCurrent.setValue(int(s[1]) == 0 ? "Direct" : "Reverse" );
        break; 
      case 'A': 
        ATCurrent.setValue(int(s[1]) == 0 ? "ATune Off" : "ATune On" );
        break; 
      case 's': 
        oSLabel.setValue(s[1]);
        nLabel.setValue(s[2]);
        lbLabel.setValue(trim(s[3]));
        break;   
      default:
    }
  }
  
  
/*
   if(s[0].equals("IPT") && (InputCard != null))
  {
    PopulateCardFields(InputCard, s);
  }
  else if(s[0].equals("OPT") && (OutputCard != null))
  {
    PopulateCardFields(OutputCard, s);
  }
  else 
  */
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
        "Step=" + s[1] + ", Ramping Setpoint", 
        float(trim(s[3])) / 1000 + " Sec remaining"            
      };
      break;
    case 2: //wait
      float helper = float(trim(s[4]));
      msg = new String[]
      {
        "Running Profile", 
        "",
        "Step=" + s[1] + ", Waiting",
        "Distance Away= " + s[3],
        (helper < 0 ? "Waiting for cross" : ("Time in band= "+helper/1000+" Sec" ))            
      };
      break;
    case 3: //step
      msg = new String[]
      {
        "Running Profile", 
        "",
        "Step="+s[1]+", Stepped Setpoint",
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



