# 
class Message < ActiveRecord::Base
  belongs_to  :sender,
                :polymorphic => true
  has_states  :initial => :unsent
  
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
                  :extend => [MessageRecipientToBuildExtension]
    m.has_many  :cc,
                  :conditions => ['kind = ?', 'cc'],
                  :extend => [MessageRecipientCcBuildExtension]
    m.has_many  :bcc,
                  :conditions => ['kind = ?', 'bcc'],
                  :extend => [MessageRecipientBccBuildExtension]
    m.has_many  :all_recipients,
                  :order => 'kind DESC, position ASC'
  end
  
  validates_presence_of :sender_id,
                        :sender_type,
                        :state_id
  
  state :unsent,
        :sent,
        :deleted
  
  # Queues the message so that it is sent in a separate process
  event :queue do
    transition_to :sent, :from => :unsent,
                    :if => Proc.new {|message| message.all_recipients.size > 0}
  end
  
  # Sends the message to all of the recipients as long as at least one
  # recipient has been aded
  event :deliver do
    transition_to :sent, :from => :unsent,
                    :if => Proc.new {|message| message.all_recipients.size > 0}
  end
  
  # Deletes the message
  event :delete do
    transition_to :deleted, :from => [:unsent, :sent]
  end
  
  # Support getting all the message's receivers
  [:to, :cc, :bcc].each do |method|
    eval <<-end_eval
      def #{method}_receivers
        #{method}.collect {|recipient| recipient.receiver}
      end
    end_eval
  end
  
  # To, cc, and bcc receivers
  def all_receivers
    all_recipients.map(&:receiver)
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
    destroy if all_recipients.all? {|recipient| recipient.deleted?}
  end
  
  # Forwards this message
  def forward
    message = Message.new(:subject => subject, :body => body)
    message.sender = sender
    message
  end
  
  # Replies to this message
  def reply
    message = Message.new(:subject => subject, :body => body)
    message.sender = sender
    message.to.concat(to_receivers)
    
    message
  end
  
  # Replies to all recipients on this message
  def reply_to_all
    message = reply
    [:cc, :bcc].each do |recipient_type|
      send(recipient_type).each do |recipient|
        message.send(recipient_type) << recipient.receiver
      end
    end
    
    message
  end
end
