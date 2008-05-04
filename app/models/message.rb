# Represents a message sent from one user to one or more others.
# 
# == States
# 
# Messages can be in 1 of 3 states:
# * +unsent+ - The message has not yet been sent.  This is the *initial* state.
# * +queued+ - The message has been queued for future delivery.
# * +sent+ - The message has been sent.
# 
# == Interacting with the message
# 
# In order to perform actions on the message, such as queueing or delivering,
# you should always use the associated event action:
# * +queue!+ - Queues the message so that you can send it in a separate process
# * +deliver!+ - Sends the message to all of the recipients
# 
# == Hiding messages
# 
# Although you can delete a message, it will also delete it from the inbox of all
# the message's recipients.  Instead, you can hide messages from users with the
# following actions:
# * +hide!+ -Hides the message from the sender's inbox
# * +unhide!+ - Makes the message visible again
class Message < ActiveRecord::Base
  belongs_to  :sender,
                :polymorphic => true
  has_many    :recipients,
                :class_name => 'MessageRecipient',
                :order => 'kind DESC, position ASC',
                :dependent => :destroy
  
  validates_presence_of :state,
                        :sender_id,
                        :sender_type
  
  after_save :update_recipients
  
  named_scope :visible,
                :conditions => {:hidden_at => nil}
  
  # Define actions for the message
  state_machine :state, :initial => 'unsent' do
    # Queues the message so that it's sent in a separate process
    event :queue do
      transition :to => 'queued', :from => 'unsent', :if => :has_recipients?
    end
    
    # Sends the message to all of the recipients as long as at least one
    # recipient has been added
    event :deliver do
      transition :to => 'sent', :from => %w(unsent queued), :if => :has_recipients?
    end
  end
  
  # Directly adds the receivers on the message (i.e. they are visible to all recipients)
  def to(*receivers)
    receivers(receivers, 'to')
  end
  alias_method :to=, :to
  
  # Carbon copies the receivers on the message
  def cc(*receivers)
    receivers(receivers, 'cc')
  end
  alias_method :cc=, :cc
  
  # Blind carbon copies the receivers on the message
  def bcc(*receivers)
    receivers(receivers, 'bcc')
  end
  alias_method :bcc=, :bcc
  
  # Forwards this message
  def forward
    message = self.class.new(:subject => subject, :body => body)
    message.sender = sender
    message
  end
  
  # Replies to this message
  def reply
    message = self.class.new(:subject => subject, :body => body)
    message.sender = sender
    message.to(to)
    message
  end
  
  # Replies to all recipients on this message
  def reply_to_all
    message = reply
    message.cc(cc)
    message.bcc(bcc)
    message
  end
  
  # Hides the message from the sender's inbox
  def hide!
    update_attribute(:hidden_at, Time.now)
  end
  
  # Makes the message visible in the sender's inbox
  def unhide!
    update_attribute(:hidden_at, nil)
  end
  
  # Is this message still hidden from the sender's inbox?
  def hidden?
    hidden_at?
  end
  
  private
    # Create/destroy any receivers that were added/removed
    def update_recipients
      if @receivers
        @receivers.each do |kind, receivers|
          kind_recipients = recipients.select {|recipient| recipient.kind == kind}
          new_receivers = receivers - kind_recipients.map(&:receiver)
          removed_recipients = kind_recipients.reject {|recipient| receivers.include?(recipient.receiver)}
          
          recipients.delete(*removed_recipients) if removed_recipients.any?
          new_receivers.each {|receiver| self.recipients.create!(:receiver => receiver, :kind => kind)}
        end
        
        @receivers = nil
      end
    end
    
    # Does this message have any recipients on it?
    def has_recipients?
      (to + cc + bcc).any?
    end
    
    # Creates new receivers or gets the current receivers for the given kind (to, cc, or bcc)
    def receivers(receivers, kind)
      if receivers.any?
        (@receivers ||= {})[kind] = receivers.flatten.compact
      else
        @receivers && @receivers[kind] || recipients.select {|recipient| recipient.kind == kind}.map(&:receiver)
      end
    end
end
