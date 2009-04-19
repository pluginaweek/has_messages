# Represents a recipient on a message.  The kind of recipient (to, cc, or bcc) is
# determined by the +kind+ attribute.
# 
# == States
#
# Recipients can be in 1 of 2 states:
# * +unread+ - The message has been sent, but not yet read by the recipient.  This is the *initial* state.
# * +read+ - The message has been read by the recipient
# 
# == Interacting with the message
# 
# In order to perform actions on the message, such as viewing, you should always
# use the associated event action:
# * +view+ - Marks the message as read by the recipient
# 
# == Hiding messages
# 
# Although you can delete a recipient, it will also delete it from everyone else's
# message, meaning that no one will know that person was ever a recipient of the
# message.  Instead, you can change the *visibility* of the message.  Messages
# have 1 of 2 states that define its visibility:
# * +visible+ - The message is visible to the recipient
# * +hidden+ - The message is hidden from the recipient
# 
# The visibility of a message can be changed by running the associated action:
# * +hide+ -Hides the message from the recipient
# * +unhide+ - Makes the message visible again
class MessageRecipient < ActiveRecord::Base
  belongs_to  :message
  belongs_to  :receiver, :polymorphic => true
  
  validates_presence_of :message_id, :kind, :state, :receiver_id, :receiver_type
  
  attr_protected :state, :position, :hidden_at
  
  before_create :set_position
  before_destroy :reorder_positions
  
  # Make this class look like the actual message
  delegate  :sender, :subject, :body, :recipients, :to, :cc, :bcc, :created_at,
              :to => :message
  
  named_scope :visible, :conditions => {:hidden_at => nil}
  
  # Defines actions for the recipient
  state_machine :state, :initial => :unread do
    # Indicates that the message has been viewed by the receiver
    event :view do
      transition :unread => :read, :if => :message_sent?
    end
  end
  
  # Defines actions for the visibility of the message to the recipient
  state_machine :hidden_at, :initial => :visible do
    # Hides the message from the recipient's inbox
    event :hide do
      transition all => :hidden
    end
    
    # Makes the message visible in the recipient's inbox
    event :unhide do
      transition all => :visible
    end
    
    state :visible, :value => nil
    state :hidden, :value => lambda {Time.now}, :if => lambda {|value| value}
  end
  
  # Forwards this message, including the original subject and body in the new
  # message
  def forward
    message = self.message.class.new(:subject => subject, :body => body)
    message.sender = receiver
    message
  end
  
  # Replies to this message, including the original subject and body in the new
  # message.  Only the original direct receivers are added to the reply.
  def reply
    message = self.message.class.new(:subject => subject, :body => body)
    message.sender = receiver
    message.to(sender)
    message
  end
  
  # Replies to all recipients on this message, including the original subject
  # and body in the new message.  All receivers (sender, direct, cc, and bcc) are
  # added to the reply.
  def reply_to_all
    message = reply
    message.to(to - [receiver] + [sender])
    message.cc(cc - [receiver])
    message.bcc(bcc - [receiver])
    message
  end
  
  private
    # Has the message this recipient is on been sent?
    def message_sent?
      message.sent?
    end
    
    # Sets the position of the current recipient based on existing recipients
    def set_position
      if last_recipient = message.recipients.find(:first, :conditions => {:kind => kind}, :order => 'position DESC')
        self.position = last_recipient.position + 1
      else
        self.position = 1
      end
    end
    
    # Reorders the positions of the message's recipients
    def reorder_positions
      if position
        position = self.position
        update_attribute(:position, nil)
        self.class.update_all('position = (position - 1)', ['message_id = ? AND kind = ? AND position > ?', message_id, kind, position])
      end
    end
end
