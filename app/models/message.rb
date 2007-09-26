# Represents a message sent from one user to one or more others.
# 
# == States
# 
# Messages can be in 1 or 3 states:
# * +unsent+ - The message has not yet been sent.  This is the *initial* state.
# * +queued+ - The message has been queued for future delivery.
# * +sent+ - The message has been sent.
# 
# == Interacting with the message
# 
# In order to perform actions on the message, such as queueing, delivering, or
# deleting, you should always use the associated event message:
# * +queue!+ - Queues the message so that it is sent in a separate process
# * +deliver!+ - Sends the message to all of the recipients
# 
# == Deleting messages
# 
# If the sender attempts to delete the message after he has already sent it, the
# record will not be destroyed until all recipients have deleted their copy of the
# message as well.
class Message < ActiveRecord::Base
  has_finder :active, :conditions => {:deleted_at => nil}
  
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
    :dependent => :destroy
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
  end
  
  has_many  :all_recipients,
              :class_name => 'MessageRecipient',
              :foreign_key => 'message_id',
              :order => 'kind DESC, position ASC'
  
  validates_presence_of :state_id
  validates_presence_of :sender_id,
                        :sender_type,
                          :if => :model_participant?
  
  state :unsent,
        :queued,
        :sent
  
  # Queues the message so that it is sent in a separate process
  event :queue do
    transition_to :queued, :from => :unsent,
                    :if => Proc.new {|message| message.all_recipients.size > 0}
  end
  
  # Sends the message to all of the recipients as long as at least one
  # recipient has been aded
  event :deliver do
    transition_to :sent, :from => [:unsent, :queued],
                    :if => Proc.new {|message| message.all_recipients.size > 0}
  end
  
  # Adds a proxy to +sent_at+ to use the +queued_at+ value in case the message is
  # being processed by an external application
  def sent_at_with_queue(*args)
    queued_at(*args) || sent_at_without_queue(*args)
  end
  alias_method_chain :sent_at, :queue
  
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
  
  # Is this message *not* yet deleted and still visible to the sender?
  def active?
    deleted_at.nil?
  end
  
  # True if this message has been deleted and is no longer active
  def deleted?
    !active?
  end
  
  # Only destroys the message if every recipient has destroyed their copy,
  # otherwise sets the +deleted_at+ field
  def destroy_with_recipient_check
    if all_recipients.all? {|recipient| recipient.deleted?}
      destroy_without_recipient_check
    else
      update_attribute :deleted_at, Time.now
    end
  end
  alias_method_chain :destroy, :recipient_check
  
  private
  # Must the sender be a model?
  def model_participant?
    true
  end
end
