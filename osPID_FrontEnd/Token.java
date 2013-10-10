// dictionary of queries and commands
// to be sent to microcontroller over serial link
public enum Token
{
  NULL(' ', false, 0),
  AUTO_TUNE_ON('A', true, 1),
  AUTO_TUNE_PARAMETERS('a', true, 3),
  CALIBRATION('B', true, 1),
  KD('d', true, 1),
  KI('i', true, 1),
  SENSOR('I', true, 1),
  ALARM_ON('L', true, 1),
  ALARM_MIN('l', true, 1),
  AUTO_CONTROL('M', true, 1),
  OUTPUT('O', true, 1),
  KP('p', true, 1),
  REVERSE_ACTION('R', true, 1),
  SET_VALUE('S', true, 1),
  ALARM_STATUS('T', true, 0),
  ALARM_AUTO_RESET('t', true, 1),
  ALARM_MAX('u', true, 1),
  OUTPUT_CYCLE('W', true, 1),
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
