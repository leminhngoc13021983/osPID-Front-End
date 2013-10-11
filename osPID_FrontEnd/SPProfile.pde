int NR_STEPS = 16;
int NAME_LENGTH = 15;

class Profile
{
  public ProfileState[] step = new ProfileState[NR_STEPS];
  public String errorMsg = "";
  public String Name = "";
  
  public Profile()
  {
    for (byte i = 0; i < NR_STEPS; i++ )
      step[i] = new ProfileState();
  }
}

class ProfileState
{
  public byte type;
  public int duration;
  public float targetSetpoint;
  
  public float maximumError = targetSetpoint;
  
  public ProfileState()
  {
    type = ProfileStep.INVALID.code;
  }
}


Profile profs[];
int curProf = -1;

long lastReceiptTime = -1000;
String profname = "";
int curProfStep = -1;


void ProfileRunTime()
{
  if (lastReceiptTime + 3000 < millis())
  {
    for (int i = 0; i < 6; i++)
    { 
      ((controlP5.Textlabel)controlP5.controller("profstat" + i)).setValue("");
      //((controlP5.Textlabel)controlP5.controller("dashstat" + i)).setValue("");
      curProfStep = -1;
      ProfCmd.setCaptionLabel("Run Profile");
    } 
  }
}


void ReadProfiles(String directory)
{
  //get all text files in the directory 
  String[] files = listFileNames(directory);
  profs = new Profile[files.length];
  for (int i = 0; i < files.length; i++)
  {
    profs[i] = CreateProfile(directory + File.separator + files[i]); 
  }
  if (profs.length > 0)
    curProf = 0;
}


String[] listFileNames(String dir) 
{
  File file = new File(dir);
  if (file.isDirectory()) 
  {
    String names[] = file.list();
    return names;
  } 
  else 
  {
    // If it's not a directory
    return null;
  }
}


Profile CreateProfile(String filename)
{
  BufferedReader reader = createReader(filename);
  String ln = null;
  int count = 0;
  Profile ret = new Profile();
  while ((count == 0) || ((ln != null) && (count - 1 < NR_STEPS)))
  {
    try 
    {
      ln = reader.readLine();
    } 
    catch (IOException e) 
    {
      e.printStackTrace();
      ln = null;
    }
    if (ln != null) 
    {
      //pull the commands from this line.  if there's an error, record and leave
      try
      {
        int ind = ln.indexOf("//");
        if (ind > 0) 
          ln = trim(ln.substring(0, ind));
        if (count == 0) 
          ret.Name = (ln.length() < NAME_LENGTH) ? ln : ln.substring(0, NAME_LENGTH - 1);
        else
        {
          String s[] = split(ln, ','); 
          byte t = (byte) int(trim(s[0]));
          float v = float(trim(s[1]));
          int time = int(trim(s[2]));
          ret.step[count - 1].type = t;
          ret.step[count - 1].targetSetpoint = v;
          ret.step[count - 1].duration = time;
          if (time < 0)
            ret.errorMsg = "Time cannot be negative";
          else if ((t == ProfileStep.WAIT_TO_CROSS.code) && (v < 0)) 
            ret.errorMsg = "Wait Band cannot be negative";
          else if (
            ((t & ProfileStep.TYPE_MASK.code) > ProfileStep.LAST_VALID_STEP.code) &&
            (t != ProfileStep.FLAG_BUZZER.code) &&
            (t != ProfileStep.INVALID.code)
          )
          {
            ret.errorMsg = "Unrecognized step type";
          }   
          if (ret.errorMsg != "") 
            ret.errorMsg = "Error on line "+ (count + 1) + ". " + ret.errorMsg;
        }
      }
      catch(Exception ex)
      {
        if (ret.step[count].duration < 0)  
          ret.errorMsg = "Error on line " + (count + 1) + ". " + ex.getMessage();      
      }
      println(ret.errorMsg);
      if (ret.errorMsg != "") 
        return ret;
    }
    count++;
  } 
  return ret;
}


void DrawProfile(Profile p, float x, float y, float w, float h)
{
  //if (p == null) return; 
  float step = w / (float) NR_STEPS;
  textFont(AxisFont);
  //scan for the minimum and maximum
  float minimum = 100000000, maximum = -10000000;
  for (int i = 0; i < NR_STEPS; i++)
  {
    byte t = p.step[i].type;
    if ((t == ProfileStep.RAMP_TO_SETPOINT.code) || (t == ProfileStep.JUMP_TO_SETPOINT.code)) 
    {
      float v = p.step[i].targetSetpoint;
      if (v < minimum)
        minimum = v;
      if (v > maximum)
        maximum = v;
    }
  }
  if (minimum == maximum)
  {
    minimum -= 1;
    maximum += 1;
  }

  float bottom = y + h;
  
  strokeWeight(4);
  float lasty = bottom - h / 2;
  for (int i = 0; i < NR_STEPS; i++)
  {
    if ((i == curProfStep) && ((millis() % 2000 < 1000)))
      stroke(255, 0, 0);
    else 
      stroke(255);
    
    byte t = p.step[i].type;
    float v = bottom - (p.step[i].targetSetpoint - minimum) / (maximum - minimum) * h;
    float x1 = x + step * (float)i;
    float x2 = x + step * (float)(i + 1);
    if (t == ProfileStep.RAMP_TO_SETPOINT.code) 
    {
      line(x1, lasty, x2, v);
      text(p.step[i].targetSetpoint, x2, v - 4);
      lasty = v;
    }
    else if ((t == ProfileStep.WAIT_TO_CROSS.code) || (t == ProfileStep.SOAK_AT_VALUE.code)) 
    {    
      strokeWeight(8);
      line(x1, lasty, x2, lasty);        
      strokeWeight(4);
    }
    else if (t == ProfileStep.JUMP_TO_SETPOINT.code) 
    {
      line(x1, lasty, x1, v);
      strokeWeight(8);
      line(x1, v, x2, v);    
      strokeWeight(4);
      lasty = v;
      text(p.step[i].targetSetpoint, x1, lasty - 4);
    }
    else if (t == ProfileStep.FLAG_BUZZER.code) 
    {
      line(x1, lasty, x2, lasty);
    }
    else if ((t & ProfileStep.TYPE_MASK.code) > ProfileStep.LAST_VALID_STEP.code)
    {
      // end
      break;
    }
  }

  fill(0);
   
  rotate(-90 * PI / 180);
  float lastv = 999;
  for (int i = 0; i < NR_STEPS; i++)
  {
    byte t = p.step[i].type;
    float v = p.step[i].targetSetpoint;
    String s1 = "", s2 = "", s3 = "";

    if (t == ProfileStep.SOAK_AT_VALUE.code) 
    {
      s1 = "Soak at " + v; 
      s2 = "For " + p.step[i].duration / 1000 + " Sec";
    }
    else if (t == ProfileStep.RAMP_TO_SETPOINT.code) 
    {
      s1 = "Ramp SP to " + v; 
      s2 = "Over " + p.step[i].duration / 1000 + " Sec";
    }
    else if ((t == ProfileStep.WAIT_TO_CROSS.code) && (v == 0)) 
    {
      s1 = "Wait until Input"; 
      s2 = "Crosses " + lastv;
    }
    else if  (t == ProfileStep.WAIT_TO_CROSS.code) 
    {
      s1 = "Wait until Input is"; 
      s2 = "Within " + v + " of " + lastv;
      s3 = "for " + p.step[i].duration / 1000 +" Sec";
    }
    else if(t == ProfileStep.JUMP_TO_SETPOINT.code) 
    {
      s1 = "Step SP to "+ v + " then"; 
      s2 = "wait " + p.step[i].duration / 1000 + " Sec";
    }
    else if (t == ProfileStep.FLAG_BUZZER.code) 
    {
      s1 = "Buzz for " + p.step[i].duration / 1000 + " Sec"; 
    }
    else if ((t & ProfileStep.TYPE_MASK.code) > ProfileStep.LAST_VALID_STEP.code)
    { 
      // end profile
      break;
    }
    
    if (s1 != "")
    {
      text(s1, -(outputTop + outputHeight - 30), x + i * step + 10);
      text(s2, -(outputTop + outputHeight - 30), x + i * step + 20);
      text(s3, -(outputTop + outputHeight - 30), x + i * step + 30);
    }
    lastv = v;
  }

  rotate(90 * PI / 180);

  textFont(ProfileFont);
  for (int i = 0; i < NR_STEPS; i++)
  {
    byte t = p.step[i].type;
    if (t == ProfileStep.INVALID.code)
    {
      break;
    }
    text(i, x + i * step + 5, outputTop + outputHeight);
  }

  if (p.errorMsg != "")
  {
    fill(255, 0, 0);
    text(p.errorMsg, ioLeft, inputTop);
    fill(0);
  }
  strokeWeight(1);
}


