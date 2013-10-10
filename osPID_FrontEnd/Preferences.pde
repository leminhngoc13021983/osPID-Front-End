// puts preference array into the correct fields
void PopulatePrefVals()
{
  for (int i = 0; i < prefs.length; i++)
    controlP5.controller(prefs[i]).setValueLabel(prefVals[i] + ""); 
}

// translates the preference array in the corresponding local variables
// and makes any required UI changes
void PrefsToVals()
{
  windowWidth = int(prefVals[0]);
  windowHeight = int(prefVals[1]);
  InScaleMin = prefVals[2];
  InScaleMax = prefVals[3];
  OutScaleMin = prefVals[4];
  OutScaleMax = prefVals[5];    
  windowSpan = int(prefVals[6] * 1000 * 60);

  inputTop = 25;
  inputHeight = (windowHeight-70) * 2/3;
  outputTop = inputHeight + 50;
  outputHeight = (windowHeight-70) * 1/3;

  ioWidth = windowWidth - ioLeft - 50;
  ioRight = ioLeft + ioWidth;

  arrayLength = windowSpan / refreshRate+1;
  InputData = (float[])resizeArray(InputData, arrayLength);
  SetpointData = (float[])resizeArray(SetpointData, arrayLength);
  OutputData = (float[])resizeArray(OutputData, arrayLength);   

  pointWidth= (ioWidth) / float(arrayLength - 1);
  resizer(windowWidth, windowHeight);
}

private static Object resizeArray(Object oldArray, int newSize) 
{
  int oldSize = java.lang.reflect.Array.getLength(oldArray);
  Class elementType = oldArray.getClass().getComponentType();
  Object newArray = java.lang.reflect.Array.newInstance(elementType,newSize);
  int preserveLength = Math.min(oldSize, newSize);
  if (preserveLength > 0)
    System.arraycopy (oldArray, 0, newArray, 0, preserveLength);
  return newArray; 
}

//resizes the form
void resizer(int w, int h)
{
  size(w, h);
  frame.setSize(w, h + 25);
}

void Save_Preferences()
{
  for (int i = 0; i < prefs.length; i++)
  {
    try
    {
      prefVals[i] = Float.valueOf(controlP5.controller(prefs[i]).valueLabel().getText()).floatValue(); 
    }
    catch(NumberFormatException ex)
    {
      println("Input error when setting preferences");
    }
  }
  PrefsToVals();
  PopulatePrefVals(); //in case there was an error we want to put the good values back in

  PrintWriter output;
  try
  {
    output = createWriter("prefs.txt");
    for (int i = 0; i < prefVals.length; i++) 
      output.println(prefVals[i]);
    output.flush();
    output.close();
  }
  catch(Exception ex)
  {
    println("Output error when saving preferences");
  }
}
 
