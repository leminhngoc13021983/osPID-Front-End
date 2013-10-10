RadioButton protIr1, protIr2, protIr3, protIr4;
Textfield protItxt1, protItxt2, protItxt3, protItxt4;

RadioButton protOr1, protOr2, protOr3, protOr4;
Textfield protOtxt1, protOtxt2, protOtxt3, protOtxt4;

ArrayList InputControls = new ArrayList(), OutputControls = new ArrayList(); //in case we need to kill them mid-run
/*
void ClearInput()
{
  for(int i = 0; i < InputControls.size(); i++)
  {
    if(InputControls.get(i).getClass().equals(controlP5.RadioButton.class))
    {
      ((ControllerGroup)InputControls.get(i)).remove();
    }
    else ((Controller)InputControls.get(i)).remove();
  }  
  InputCard = "";
}

void ClearOutput()
{
  for(int i = 0; i < OutputControls.size(); i++)
  {
    if(OutputControls.get(i).getClass().equals(controlP5.RadioButton.class))
    {
      ((ControllerGroup)OutputControls.get(i)).remove();
    }
    else ((Controller)OutputControls.get(i)).remove();
  }
  OutputCard = "";
}
*/
void CreateUI(String tab, int top)
{
  /*
  ClearInput();
  InputControls.clear();
  */
  controlP5.addTextlabel("spec0", "Specify which input to use: ", configLeft, top);

  sensorRadioButton = controlP5.addRadioButton("radioButton2", configLeft, top + 22);
  sensorRadioButton.setColorForeground(color(120));
  sensorRadioButton.setColorActive(color(255));
  sensorRadioButton.setColorLabel(color(255));
  sensorRadioButton.setItemsPerRow(1);
  sensorRadioButton.setSpacingColumn(75);
  addToRadioButton(sensorRadioButton, "Thermistor", 0);
  addToRadioButton(sensorRadioButton, "DS18B20+", 1);
  addToRadioButton(sensorRadioButton, "Thermocouple", 2);
  sensorRadioButton.getItem(0).setState(true);
  
  sensorRadioButton.moveTo(tab); 
  
  InputControls.add(sensorRadioButton);
}

void PopulateCardFields(String[] fields)
{
  int v = int(fields[1]); 
  if (v == 0) 
    sensorRadioButton.getItem(0).setState(true);
  else if (v == 1) 
    sensorRadioButton.getItem(1).setState(true);
  else if (v == 2) 
    sensorRadioButton.getItem(2).setState(true);
}

void Send_Input_Config()
{  
  //build the send string for the appropriate input card
  myPort.write(byte(5));
  Byte a = 0;
  if(sensorRadioButton.getState(1) == true)
    a = 1;
  myPort.write(a);

    /*
    myPort.write(floatArrayToByteArray(
      new float[]
      {
        float(R0Field.getText()),
        float(BetaField.getText()), 
        float(T0Field.getText()),
        float(R0Field.getText()),//hidden reference resistance
      }
    ));
    */
}

void Send_Output_Config()
{
  byte[] toSend;
  myPort.write(byte(6));
  //byte o = (r3.getState(0) == true) ? (byte) 0 : (byte) 1;

  //myPort.write(o);
    /*
    myPort.write(floatArrayToByteArray(
      new float[]
      {
        float(oSecField.getText())                
      }
    ));
    */
}








