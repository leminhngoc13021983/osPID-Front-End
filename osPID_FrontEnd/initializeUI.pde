void createTabs()
{
  controlP5.tab("Tab1").activateEvent(true);
  controlP5.tab("Tab1").setId(2);
  controlP5.tab("Tab1").setLabel("Tune");

  // in case you want to receive a controlEvent when
  // a  tab is clicked, use activeEvent(true)
  controlP5.tab("Tab2").activateEvent(true);
  controlP5.tab("Tab2").setId(3);
  controlP5.tab("Tab2").setLabel("Config");

  // in case you want to receive a controlEvent when
  // a  tab is clicked, use activeEvent(true)
  controlP5.tab("Tab3").activateEvent(true);
  controlP5.tab("Tab3").setId(4);
  controlP5.tab("Tab3").setLabel("Prefs");
  
  // in case you want to receive a controlEvent when
  // a  tab is clicked, use activeEvent(true)
  controlP5.tab("Tab4").activateEvent(true);
  controlP5.tab("Tab4").setId(5);
  controlP5.tab("Tab4").setLabel("Profile");

  controlP5.tab("default").activateEvent(true);
  // to rename the label of a tab, use setLabe("..."),
  // the name of the tab will remain as given when initialized.
  controlP5.tab("default").setLabel("Run");
  controlP5.tab("default").setId(1);
}

void populateDashTab()
{  
  // RadioButtons for available CommPorts
  ConnectButton = controlP5.addButton("Connect", 0.0, commLeft, commTop, fieldW, 20);
  ConnectButton.setCaptionLabel("Connect");  

  portRadioButton = controlP5.addRadioButton("portRadioButton", commLeft + 2, commTop + 27);
  portRadioButton.setColorForeground(color(120));
  portRadioButton.setColorActive(color(255));
  portRadioButton.setColorLabel(color(255));
  portRadioButton.setItemsPerRow(1);
  portRadioButton.setSpacingColumn(75);

  CommPorts = Serial.list();
  for (int i = 0; i < CommPorts.length; i++)
  {
    addToRadioButton(portRadioButton, CommPorts[i], i); 
  }
  if (CommPorts.length > 0) 
    portRadioButton.getItem(0).setState(true);
  commH = 27 + 12 * CommPorts.length;
  
  // radio buttons for serial speed
  speedRadioButton = controlP5.addRadioButton("baudRateRadioButton", commLeft + 2, commH + 29);
  speedRadioButton.setColorForeground(color(120));
  speedRadioButton.setColorActive(color(255));
  speedRadioButton.setColorLabel(color(255));
  speedRadioButton.setItemsPerRow(1);
  speedRadioButton.setSpacingColumn(75);  
  for(int i = 0; i < baudRates.length; i++)
  {
    addToRadioButton(speedRadioButton, nf(baudRates[i], 0, 0) + " baud", i);
  }
  speedRadioButton.getItem(0).setState(true); // set to lowest baud rate initially

  // dashboard     
  dashTop = commTop + commH + 65; 
  SPField = controlP5.addTextfield("Set_Value", dashLeft + 2, dashTop, fieldW, 20);  
  SPField.setCaptionLabel("Set Value");  
  SPLabel = controlP5.addTextlabel("SV", "---", dashLeft + fieldW + 10, dashTop + 3);              
  InField = controlP5.addTextfield("Process_Value", dashLeft + 2, dashTop + 40, fieldW, 20);   
  InField.setCaptionLabel("Process Value");
  InField.lock(); // we don't need to enter input
  InLabel = controlP5.addTextlabel("PV", "---", dashLeft + fieldW + 10, dashTop + 43);             
  OutField = controlP5.addTextfield("Output", dashLeft + 2, dashTop + 80, fieldW, 20);              
  OutLabel = controlP5.addTextlabel("Out", "---", dashLeft + fieldW + 10, dashTop + 83);   
  AMButton = controlP5.addButton("Auto_Manual", 0.0, dashLeft, dashTop + 120, fieldW, 20);     
  AMButton.setCaptionLabel("Set Manual Control");  
  AMLabel = controlP5.addTextlabel("AM", "Manual Control", dashLeft - 2, dashTop + 142);   
  AMCurrent = controlP5.addTextlabel("AMCurrent", "Manual Control", dashLeft + fieldW + 10, dashTop + 123); 
  //controlP5.addButton("Update_Dashboard", 0.0, dashLeft, dashTop + 160, 160, 20);         
  int dashStatTop = configTop + 490;
  for (int i = 0; i < 6; i++)
  { 
    controlP5.addTextlabel("dashstat" + i, "" + i, configLeft, dashStatTop + 12 * i + 5);
  }
  
  // alarm controls 
  alarmTop = dashTop + 170;
  AlarmEnableButton = controlP5.addButton("Alarm_Enable", 0.0, dashLeft, alarmTop, fieldW, 20);   
  AlarmEnableButton.setCaptionLabel("Set Alarm On");  
  AlarmEnableLabel = controlP5.addTextlabel("Alarm", "Alarm OFF", dashLeft - 2, alarmTop + 22);  
  AlarmEnableCurrent = controlP5.addTextlabel("AlarmEnableCurrent", "Alarm OFF", dashLeft +fieldW + 1090, alarmTop + 3);  
  MinField = controlP5.addTextfield("Alarm_Min", dashLeft + 2, alarmTop + 40, fieldW, 20);  
  MinField.setCaptionLabel("Alarm Min");  
  MinLabel = controlP5.addTextlabel("Min", "---", dashLeft + fieldW + 10, alarmTop + 43);             
  MaxField = controlP5.addTextfield("Alarm_Max", dashLeft + 2, alarmTop + 80, fieldW, 20);     
  MaxField.setCaptionLabel("Alarm Max");              
  MaxLabel = controlP5.addTextlabel("Max", "---", dashLeft + fieldW + 10, alarmTop + 83);          
  AutoResetButton = controlP5.addButton("Alarm_Reset", 0.0, dashLeft, alarmTop + 120, fieldW, 20); 
  AutoResetButton.setCaptionLabel("Set Auto Reset");           
  AutoResetLabel = controlP5.addTextlabel("Alarm Reset", "Manual Reset", dashLeft - 2, alarmTop + 142);  
  AutoResetCurrent = controlP5.addTextlabel("AutoResetCurrent", "Manual Reset", dashLeft + fieldW + 10, alarmTop + 123);       
  
  controlP5.addTextlabel("dashstatus", "Status", configLeft + 5, dashStatTop - 8);
}

void populateTuneTab()
{
  // PID tunings
  PField = controlP5.addTextfield("Kp", tuneLeft + 2, tuneTop, fieldW, 20);  
  PField.setCaptionLabel("Kp  (Proportional)");
  PLabel = controlP5.addTextlabel("P", "4", tuneLeft + fieldW + 10, tuneTop + 3);                      
  IField = controlP5.addTextfield("Ki", tuneLeft + 2, tuneTop + 40, fieldW, 20);  
  IField.setCaptionLabel("Ki  (Integral)");            
  ILabel = controlP5.addTextlabel("I", "5", tuneLeft + fieldW + 10, tuneTop + 43);                
  DField = controlP5.addTextfield("Kd", tuneLeft + 2, tuneTop + 80, fieldW, 20);  
  DField.setCaptionLabel("Kd  (Derivative)");           
  DLabel = controlP5.addTextlabel("D", "6", tuneLeft + fieldW + 10, tuneTop + 83);                  
  DRButton = controlP5.addButton("Direct_Reverse", 0.0, tuneLeft, tuneTop + 120, fieldW, 20);     
  DRButton.setCaptionLabel("Set Direct Action"); 
  DRLabel = controlP5.addTextlabel("DR","Direct", tuneLeft - 2, tuneTop + 144);              
  DRCurrent = controlP5.addTextlabel("DRCurrent", "Direct", tuneLeft + fieldW + 10, tuneTop + 123);  

  PField.moveTo("Tab1"); 
  IField.moveTo("Tab1"); 
  DField.moveTo("Tab1");
  DRButton.moveTo("Tab1");  
  DRLabel.moveTo("Tab1"); 
  PLabel.moveTo("Tab1");
  ILabel.moveTo("Tab1"); 
  DLabel.moveTo("Tab1"); 
  DRCurrent.moveTo("Tab1");

  // Autotune settings   
  ATButton = controlP5.addButton("AutoTune_On_Off", 0.0, ATLeft, ATTop, fieldW, 20);  
  ATButton.setCaptionLabel("Set Auto Tune On");  
  ATLabel = controlP5.addTextlabel("ATune", "Auto Tune OFF", ATLeft - 2, ATTop + 22);  
  ATCurrent = controlP5.addTextlabel("ATuneCurrent", "Auto Tune OFF", ATLeft + fieldW + 10, ATTop + 3);  
  oSField = controlP5.addTextfield("Output_Step", ATLeft + 2, ATTop + 40, fieldW, 20);            
  oSField.setCaptionLabel("Output Step");
  oSLabel = controlP5.addTextlabel("oStep", "20.0", ATLeft + fieldW + 10, ATTop + 43);             
  nField = controlP5.addTextfield("Noise_Band", ATLeft + 2, ATTop + 80, fieldW, 20);       
  nField.setCaptionLabel("Noise Band");              
  nLabel = controlP5.addTextlabel("noise", "1.0", ATLeft + fieldW + 10, ATTop + 83);          
  lbField = controlP5.addTextfield("Look_Back", ATLeft + 2, ATTop + 120, fieldW, 20);       
  lbField.setCaptionLabel("Look Back");                 
  lbLabel = controlP5.addTextlabel("lback", "10", ATLeft + fieldW + 10, ATTop + 123);    

  oSField.moveTo("Tab1"); 
  nField.moveTo("Tab1"); 
  lbField.moveTo("Tab1");
  ATButton.moveTo("Tab1");
  ATLabel.moveTo("Tab1");  
  oSLabel.moveTo("Tab1"); 
  nLabel.moveTo("Tab1");
  lbLabel.moveTo("Tab1");
  ATCurrent.moveTo("Tab1"); 
}

void populateConfigTab()
{
  /* Need to:
   *   
   *  Add other buttons?
   */
   
  // calibration
  calField = controlP5.addTextfield("Calibration", configLeft + 2, configTop + 60, fieldW, 20);            
  calLabel = controlP5.addTextlabel("cal", "---", configLeft + fieldW + 10, configTop + 63); 
  calField.moveTo("Tab2");
  calLabel.moveTo("Tab2");  
   
  // sensor
  specLabel = controlP5.addTextlabel("spec0", "Specify which input to use: ", configLeft, configTop);
  sensorRadioButton = controlP5.addRadioButton("radioButton2", configLeft + 2, configTop + 20);
  sensorRadioButton.setColorForeground(color(120));
  sensorRadioButton.setColorActive(color(255));
  sensorRadioButton.setColorLabel(color(255));
  sensorRadioButton.setItemsPerRow(1);
  sensorRadioButton.setSpacingColumn(75);
  addToRadioButton(sensorRadioButton, "Thermistor", 0);
  addToRadioButton(sensorRadioButton, "DS18B20+", 1);
  addToRadioButton(sensorRadioButton, "Thermocouple", 2);
  sensorRadioButton.getItem(0).setState(true);
  specLabel.moveTo("Tab2");
  sensorRadioButton.moveTo("Tab2");

  // output cycle period  
  winField = controlP5.addTextfield("Window", configLeft + 2, configTop + configH + 15, fieldW, 20);    
  winField.setCaptionLabel("Output Cycle (sec)");                       
  winLabel = controlP5.addTextlabel("win", "---", configLeft + fieldW + 10, configTop + configH + 18); 
  winField.moveTo("Tab2");
  winLabel.moveTo("Tab2"); 
}

void populatePrefTab()
{
  /* Need to:
   *   
   *   Set Fahrenheit/Celsius?
   *   Set power on action
   *   Clear EEPROM 
   *   Any other commands?
   *   
   */
   
  //preferences
  for (int i = 0; i < prefs.length; i++)
  {
    controlP5.addTextfield(prefs[i], 10, 30 + 40 * i, fieldW, 20);    
    controlP5.controller(prefs[i]).moveTo("Tab3");
  }
  SavePreferencesButton = controlP5.addButton("Save_Preferences", 0.0, 10, 30 + 40 * prefs.length, 160, 20);
  SavePreferencesButton.setCaptionLabel("Save Preferences");
  SavePreferencesButton.moveTo("Tab3");
  PopulatePrefVals(); 
}

void populateProfileTab()
{
  configH = 10 + 15 * profs.length;
  LBPref = controlP5.addListBox("Available Profiles", configLeft, configTop + 5, 160, 120);
  controlP5.addTextlabel("spec4", "Currently Displaying: ", configLeft + 5, configTop + configH);   
 
  // uploaded profiles
  profLabel = controlP5.addTextlabel("prof0", "Upload over which profile: ", configLeft, configTop + configH + 40);
  profileRadioButton = controlP5.addRadioButton("radioButton3", configLeft + 2, configTop + configH + 60);
  profileRadioButton.setColorForeground(color(120));
  profileRadioButton.setColorActive(color(255));
  profileRadioButton.setColorLabel(color(255));
  profileRadioButton.setItemsPerRow(1);
  profileRadioButton.setSpacingColumn(75);
  addToRadioButton(profileRadioButton, "Profile 1", 0);
  addToRadioButton(profileRadioButton, "Profile 2", 1);
  addToRadioButton(profileRadioButton, "Profile 3", 2);
  profileRadioButton.getItem(0).setState(true);
  
  ProfButton = controlP5.addButton("SendProfileName", 0.0, configLeft, configTop + configH + 95, 160, 20);
  ProfButton.setCaptionLabel("Upload Profile");

  int profStatTop = configTop + 490;
  ProfCmd = controlP5.addButton("Run_Profile", 0.0, configLeft, profStatTop - 40, 160, 20);
  ProfCmd.setCaptionLabel("Run Profile");
  for (int i = 0; i < 6; i++)
  { 
    controlP5.addTextlabel("profstat" + i, "", configLeft, profStatTop + 12 * i + 5);
    controlP5.controller("profstat" + i).moveTo("Tab4");
  }
  controlP5.addTextlabel("profstatus", "Status", configLeft + 5, profStatTop - 8);
  controlP5.controller("profstatus").moveTo("Tab4");
 
  for (int i = 0; i < profs.length; i++) 
    LBPref.addItem(profs[i].Name, i);
  profSelLabel = controlP5.addTextlabel("spec5",(profs.length == 0) ? "N/A" : profs[0].Name, configLeft + 100, configTop + 10 + 15 * profs.length); 
 
  LBPref.moveTo("Tab4");
  profSelLabel.moveTo("Tab4");
  ProfButton.moveTo("Tab4");
  ProfCmd.moveTo("Tab4");
  profLabel.moveTo("Tab4");
  profileRadioButton.moveTo("Tab4");
  controlP5.controller("spec4").moveTo("Tab4");
}

void addToRadioButton(RadioButton theRadioButton, String theName, int theValue ) 
{
  RadioButton t = theRadioButton.addItem(theName, theValue);
  t.captionLabel().setColorBackground(color(80));
  t.captionLabel().style().movePadding(2, 0, -1, 2);
  t.captionLabel().style().moveMargin(-2, 0, 0, -3);
  t.captionLabel().style().backgroundWidth = 100;
}

