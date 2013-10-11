public enum ProfileStep
{
  RAMP_TO_SETPOINT(      (byte) 0x00),
  SOAK_AT_VALUE(         (byte) 0x01),
  JUMP_TO_SETPOINT(      (byte) 0x02),
  WAIT_TO_CROSS(         (byte) 0x03),

  LAST_VALID_STEP(       (byte) 0x03),         // = WAIT_TO_CROSS
  FLAG_BUZZER(           (byte) 0x40),        
  //EEPROM_SWIZZLE(0x80),
  INVALID(               (byte) 0x7F),
  CONTENT_MASK(          (byte) 0x7F),
  TYPE_MASK(             (byte) 0x3F);
  
  public final byte code;
  
  private ProfileStep(byte c)
  {
    this.code = c;
  }
};
