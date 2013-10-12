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
    return arguments == QUERY;
  }
  
  public Msg(Token t, String[] a, boolean r)
  {
    token = t;
    arguments = a;
    resend = r;
    status = IGNORE;
    expireTime = WHENEVER;
    cmd = String.valueOf(t.symbol);
    if ((args == NO_ARGS) && (t.argNum == 0))
      return;
    else if ((args == QUERY) && t.queryable)
    {
      cmd = cmd + "?";
      return;
    }
    else if (args.length == t.argNum)
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
    if (arguments == QUERY)
      cmd = cmd + "?";
    else
      cmd = cmd + " " + join(arguments, " ");
    //myPort.write(cmd);
    println(cmd); //debug
    this.updateStatus(SENT);
  }
  
  // enter message into queue
  public boolean queue(LinkedList<Msg> msgQueue)
  {
    // remove expired messages
    while (removeExpired(msgQueue));
    if (this == null)
      return false;
      
    //debug
    /*
    String cmd = String.valueOf(token.symbol);
    if (arguments == QUERY)
      cmd = cmd + "?";
    else
      cmd = cmd + " " + join(arguments, " ");
    println(cmd); 
    */
      
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
  return true;
}

// send messages that are marked for sending
void sendAll(LinkedList<Msg> msgQueue, Serial myPort)
{
  ListIterator m = msgQueue.listIterator();
  Msg nextMsg;
  while (m.hasNext())
  {
    nextMsg = (Msg)m.next();
    if (nextMsg.markedReadyToSend())
    {
      nextMsg.send(myPort);
    }
  }
}
  
  
  
