# A message which has been sent to one ore more recipients
class SenderMessage < Message
  self.initial_state = :unsent
  
  belongs_to  :owner,
                :polymorphic => true
  
  # Add associations for different types of recipients:
  # * to - Your direct recipients
  # * cc - Carbon copies
  # * bcc - Blind carbon copies
  with_options(
    :class_name => 'MessageRecipient',
    :foreign_key => 'message_id',
    :order => 'position ASC',
    :dependent => true
  ) do |m|
    m.has_many  :to,
                  :conditions => ['kind = ?', 'to'],
                  :extend => [MessageRecipient::EasyBuildToExtension]
    m.has_many  :cc,
                  :conditions => ['kind = ?', 'cc'],
                  :extend => [MessageRecipient::EasyBuildCcExtension]
    m.has_many  :bcc,
                  :conditions => ['kind = ?', 'bcc'],
                  :extend => [MessageRecipient::EasyBuildBccExtension]
    m.has_many  :all_recipients,
                  :order => 'kind DESC, position ASC'
  end
  
  has_many    :sent_messages,
                :through => :all_recipients,
                :class_name => 'ReceiverMessage',
                :source => :receiver_messages
  
  validates_presence_of :owner_type
  
  state :unsent,
        :sent
  
  # Queues the message so that it is sent in a separate process
  event :queue do
    transition_to :sent, :from => :unsent,
                    :if => Proc.new {|message| message.number_of_recipients > 0}
  end
  
  # Sends the message to all of the recipients as long as at least one
  # recipient has been aded
  event :deliver do
    transition_to :sent, :from => :unsent,
                    :if => Proc.new {|message| message.number_of_recipients > 0}
  end
  
  # Deletes the message
  event :delete do
    transition_to :deleted, :from => [:unsent, :sent]
  end
  
  # 
  def forward
    message = SenderMessage.new(:subject => subject, :body => body)
    message.owner = owner
    message
  end
  
  # 
  def reply
    message = SenderMessage.new(:subject => subject, :body => body)
    message.owner = owner
    message.to.concat(to_receivers)
    
    message
  end
  
  # Delivers the message to all recipients
  def deliver
    all_recipients.each do |recipient|
      recipient.deliver!
    end
  end
  
  # Destroys the message only if there are no sent messages depending on this
  # one
  def after_delete
    destroy if sent_messages.empty?
  end
end