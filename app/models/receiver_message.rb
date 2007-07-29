# A mesage which has been received from somewhere else
class ReceiverMessage < Message
  self.initial_state = :unread
  
  belongs_to  :owner,
                :class_name => 'MessageRecipient',
                :foreign_key => 'owner_id'
  
  state :unread, :read
  
  delegate  :subject,
            :body,
            :to,
            :cc,
            :bcc,
            :all_recipients,
              :to => :reference_message
  
  # Indicates that the message has been viewed by the recipient of this
  # message
  event :view do
    transition_to :read, :from => :unread
  end
  
  # Deletes the message
  event :delete, :after => :destroy do
    transition_to :deleted, :from => [:unread, :read]
  end
  
  def reference_message
    owner.message
  end
  
  # This message is from the owner of the reference message (the person which
  # sent the message)
  def from
    reference_message.owner
  end
  
  # 
  def forward
    message = SenderMessage.new(:subject => subject, :body => body)
    message.owner = owner.messageable
    message
  end
  
  # 
  def reply
    message = SenderMessage.new(:subject => subject, :body => body)
    message.owner = owner.messageable
    message.to << from
    message
  end
  
  def reply_to_all
    message = super
    message.to.concat(to - [owner])
    
    message
  end
end
