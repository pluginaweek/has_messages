# A mesage which has been received from somewhere else
class ReceivedMessage
  delegate  :sent_at,
            :sender,
            :sender_id,
            :sender_type,
            :subject,
            :body,
            :to,
            :to_receivers,
            :cc,
            :cc_receivers,
            :bcc,
            :bcc_receivers,
            :all_recipients,
            :all_receivers,
              :to => '@message'
  
  def initialize(message_recipient) #:nodoc:
    @recipient = message_recipient
    @message = message_recipient.message
  end
  
  def respond_to?(symbol, include_priv = false) #:nodoc:
    super || @recipient.respond_to?(symbol, include_priv)
  end
  
  # Forwards the message
  def forward
    message = @message.class.new(:subject => subject, :body => body)
    message.sender = @recipient.receiver
    message
  end
  
  # Replies to the message
  def reply
    message = @message.class.new(:subject => subject, :body => body)
    message.sender = @recipient.receiver
    message.to << @message.sender
    message
  end
  
  # Replies to all recipients on the message, including the original sender
  def reply_to_all
    message = reply
    [:to, :cc, :bcc].each do |recipient_type|
      send(recipient_type).each do |recipient|
        message.send(recipient_type) << recipient.receiver unless recipient.receiver == self.receiver
      end
    end
    
    message
  end
  
  private
  def method_missing(method, *args, &block) #:nodoc:
    @recipient.send(method, *args, &block) if @recipient
  end
end
