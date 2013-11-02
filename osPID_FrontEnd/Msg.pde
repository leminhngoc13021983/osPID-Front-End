// Msg class for messages in a MsgQueue
 

String[] NO_ARGS = {};
String[] QUERY = {"?"};
int EXPIRY = 1000; // give the microcontroller 1 second to respond
int WHENEVER = -1;
int IGNORE = -1;
int QUEUED = 0;
int MARKED_READY_TO_SEND = 1;
int SENT = 2;

public class Msg
{
  private String cmd = "";
  private Token token = Token.NULL;
  private String[] arguments = NO_ARGS;
  private int status = IGNORE;
  private int expireTime= WHENEVER;
  private boolean resend = true;
  
  private boolean isQuery()
  {
    return (
      (arguments == QUERY)       || 
      (token == Token.QUERY)     || 
      (token == Token.IDENTIFY)  || 
      (token == Token.EXAMINE_PROFILE_BY_NUMBER)
    );
  }
  
  public Msg(Token t, String[] a, boolean r)
  {
    token = t;
    arguments = a;
    resend = r;
    status = IGNORE;
    expireTime = WHENEVER;
    cmd = String.valueOf(t.symbol);
    
    if ((arguments == NO_ARGS) && (t.argNum == 0))
      return;
    else if ((arguments == QUERY) && t.queryable)
    {
      cmd = cmd + "?";
      return;
    }
    else if (arguments.length == t.argNum)
    {
      cmd = cmd + " " + join(args, " ");
      return;
    }
    // otherwise null
    cmd = "";
    token = Token.NULL;
    arguments = NO_ARGS;
  }
  
  public Token getToken()
  {
    return token;
  }
  
  public String[] getArgs()
  {
    return arguments;
  }
  
  public boolean resendable()
  {
    return resend;
  }
  
  public boolean queued() 
  {
    return (status == QUEUED);
  }
  
  public boolean markedReadyToSend() 
  {
    return (status == MARKED_READY_TO_SEND);
  }
  
  public boolean sent() 
  {
    return (status == SENT);
  }
  
  public boolean expired()
  {
    return (millis() > expireTime);
  }
  
  public void updateStatus(int newStatus)
  {
    status = newStatus;
    expireTime = millis() + EXPIRY;
  }
  
  public void send(Serial myPort)
  {
    String cmd = String.valueOf(token.symbol);
    if (arguments == NO_ARGS)
      cmd = cmd + "\n";
    else if (arguments == QUERY)
      cmd = cmd + "?\n";
    else 
      cmd = cmd + " " + join(arguments, " ") + '\n';
    if (debug)
    {
      print("sending:" + cmd); 
    }
    try
    {
      myPort.write(cmd);
    }
    catch (NullPointerException Ex)
    {
      println("Serial port not open");
    }
    this.updateStatus(SENT);
  }
  
  // enter message into queue
  public boolean queue(LinkedList<Msg> msgQueue)
  {
    if (debug)
    {
      String cmd = String.valueOf(token.symbol);
      if (arguments == QUERY)
        cmd = cmd + "?";
      else if (arguments != NO_ARGS)
        cmd = cmd + " " + join(arguments, " ");
      print("queuing:");
      println(cmd);
    }
    
    // remove expired messages
    while (removeExpired(msgQueue));
    if (this.token == Token.NULL)
      return false;
      
    // check for similar messages yet to expire
    ListIterator m = msgQueue.listIterator();
    Msg nextMsg;
    boolean existsCommandAwaitingAcknowledgment = false;
    while (m.hasNext())
    {
      nextMsg = (Msg)m.next();
      if (this.getToken().symbol == nextMsg.getToken().symbol)
      {
        // there is a similar message already in the queue
        if (this.isQuery() && nextMsg.isQuery())
        {
          // if both messages are queries
          // update expireTime of previous query
          this.updateStatus(SENT);
          m.remove();
          msgQueue.addLast(this);
          if (debug)
            updateDashQueue();
          return true;
        }
        else if (this.isQuery()) 
        {
          // otherwise we don't queue queries
          return false;
        }
        else if (!nextMsg.sent())
        {
          // if this is a command and the previous command is unsent 
          // i.e. queued or marked ready to send
          // override the unsent message
          m.remove();
          msgQueue.addLast(this);
          
          if (!existsCommandAwaitingAcknowledgment)
          {
            // if there is no previous command awaiting acknowledgment
            // then mark the message ready to send, overriding the unsent message
            this.updateStatus(MARKED_READY_TO_SEND);
          }
          else
          {
            // otherwise queue the message, overriding the unsent message
            this.updateStatus(QUEUED);
            // unless there is a previous command already queued, in which case override it, see above
          }
          if (debug)
            updateDashQueue();
          return true;
        } 
        else if (!nextMsg.isQuery())
        {
          // if this is a command and the previous command awaits acknowledgment  
          if (existsCommandAwaitingAcknowledgment)
          {
            // if there is a previous similar command already sent then we have a problem
            throw new UnsupportedOperationException("Overlapping messages");
          }
          existsCommandAwaitingAcknowledgment = true;
          // we will continue through the list check to see if there are previous commands already queued
        }
        // otherwise this is a command and the previous command is a query
        // carry on through the list
      }
    }
    
    if (existsCommandAwaitingAcknowledgment)
    {
      // there is a previous command awaiting acknowledgment
      // queue the command
      this.updateStatus(QUEUED);
    }
    else
    {
      //  otherwise mark the message ready to send
      this.updateStatus(MARKED_READY_TO_SEND);
    }
    msgQueue.addLast(this);
    
    if (debug)
      updateDashQueue();
    return true;
  }
}

 
// check front of queue for expired message
boolean removeExpired(LinkedList<Msg> msgQueue)
{  
  // check if first message has expired
  ListIterator m = msgQueue.listIterator();
  if (!m.hasNext())
    return false;   
  Msg firstMsg = (Msg)m.next();
  if (!firstMsg.expired())
    return false;  
    
  // get rid of expired queries
  if (firstMsg.isQuery())
  {
    msgQueue.removeFirst();
    // check next message
    if (debug)
      updateDashQueue();
    return true;
  }
  
  // if expired command
  // check for similar messages
  Msg nextMsg;
  while (m.hasNext())
  {
    nextMsg = (Msg)m.next();
    if (firstMsg.token.symbol == nextMsg.token.symbol)
    {
      // there is a similar command already in the queue
      if (!nextMsg.isQuery())
      { 
        // if sent already, raise exception
        if (nextMsg.sent())
          throw new UnsupportedOperationException("Overlapping messages");
        // otherwise mark message ready to send 
        nextMsg.updateStatus(MARKED_READY_TO_SEND);
        // remove unsent message from previous position in queue
        m.remove();
        // add to back of queue
        msgQueue.addLast(nextMsg);
        // remove expired message from previous position in queue
        msgQueue.removeFirst();
        // check next message
        if (debug)
          updateDashQueue();
        return true;
      }
      // otherwise this is a command and the previous command is a query
      // carry on through the list
    }
  }
  
  // there is no similar commands in the queue
  if (firstMsg.resendable())
  {
    // mark expired message ready to send and add to end of queue
    firstMsg.updateStatus(MARKED_READY_TO_SEND);
    m.add(firstMsg);  
  }  
  // remove expired message from previous position in queue
  msgQueue.removeFirst();
  // check next message
  if (debug)
    updateDashQueue();
  return true;
}

// send messages that are marked for sending
void sendAll(LinkedList<Msg> msgQueue, Serial myPort)
{
  for (byte i = 0; i < msgQueue.size(); i++)
  {
    if (msgQueue.get(i).markedReadyToSend())
    {
      msgQueue.get(i).send(myPort);
    }
  }
}

// removed acknowledged command or replied-to query from queue
boolean removeAcknowledged(LinkedList<Msg> Queue, String[] cmd)
{
  if (debug)
    println("Remove " + join(cmd, '+'));
  ListIterator m = msgQueue.listIterator();
  Msg nextMsg;
  while (m.hasNext())
  {
    nextMsg = (Msg)m.next();
    if (
      nextMsg.sent() &&
     (nextMsg.token.symbol == cmd[0].charAt(0)) 
    )
    {
      if (
        (nextMsg.isQuery() && (cmd[0].length() > 1) && (cmd[0].charAt(1) == '?')) ||
        (nextMsg.token == Token.QUERY) || 
        (nextMsg.token == Token.IDENTIFY) ||
        (nextMsg.token == Token.EXAMINE_SETTINGS)
      )
      {
        // remove matched query
        m.remove();
        if (debug)
          updateDashQueue();
        return true;
      }
      if (!nextMsg.isQuery())
      {
        String[] args = nextMsg.getArgs();
        for (byte i = 0; i < nextMsg.arguments.length; i++)
        {
          if ((cmd.length < i + 1) || (args[i] != cmd[i + 1]))
            continue;
        }
        // remove matched command
        m.remove();
        if (debug)
          updateDashQueue();
        return true;
      }
    }
  }
  return false;
}       

// debug queue
void updateDashQueue()
{
  ListIterator m = msgQueue.listIterator();
  String c;
  int i = 0;
  while (m.hasNext() && (i < 6))
  {
    Msg nextMsg = (Msg)m.next();
    c = nextMsg.getToken().symbol + " " + join(nextMsg.getArgs(), " ");
    if (nextMsg.sent())
      c = c + "s";
    else if (nextMsg.markedReadyToSend())
      c = c + "r";
    else  if (nextMsg.queued())
      c = c + "q";
    ((controlP5.Textlabel)controlP5.controller("dashstat" + i)).setStringValue(c);
    i++;
  }
  for (int i2 = i; i2 < 6; i2++)
  {
   ((controlP5.Textlabel)controlP5.controller("dashstat" + i2)).setStringValue("");
  } 
}
  
  
  
