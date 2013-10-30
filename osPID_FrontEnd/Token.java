// dictionary of queries and commands
// to be sent to microcontroller over serial link
public enum Token
{
  NULL(' ', false, 0),
  AUTO_TUNE_ON('A', true, 1),
  AUTO_TUNE_PARAMETERS('a', true, 3),
  CALIBRATION('B', true, 1),
  PROFILE_CANCEL('C', false, 0),
  //SERIAL_SPEED('c', true, 1),
  KD('d', true, 1),
  PROFILE_EXECUTE_BY_NAME('E', false, 1),
  PROFILE_EXECUTE_BY_NUMBER('e', false, 1),
  INPUT('I', true, 1),
  KI('i', true, 1),
  //SET_VALUE_INDEX('J', true, 1),
  ALARM_ON('L', true, 1),
  ALARM_MIN('l', true, 1),
  AUTO_CONTROL('M', true, 1),
  AUTO_TUNE_METHOD('m', true, 1),
  PROFILE_NAME('N', false, 1),
  OUTPUT('O', true, 1),
  POWER_ON('o', true, 1),
  PROFILE_STEP('P', false, 3),
  KP('p', true, 1),
  QUERY('Q', false, 0),
  REVERSE_ACTION('R', true, 1),
  SET_VALUE('S', true, 1),
  SENSOR('s', true, 1),
  ALARM_STATUS('T', true, 0),
  ALARM_AUTO_RESET('t', true, 1),
  ALARM_MAX('u', true, 1),
  PROFILE_SAVE('V', false, 1),
  OUTPUT_CYCLE('W', true, 1),
  EXAMINE_SETTINGS('X', false, 0),
  EXAMINE_PROFILE_BY_NUMBER('x', false, 1),
  IDENTIFY('Y', false, 0);
  
  public final char symbol;
  public final boolean queryable;
  public final int argNum;
  
  private Token(char c, boolean q, int a)
  {
    this.symbol = c;
    this.queryable = q;
    this.argNum = a;
  }
}
