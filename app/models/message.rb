# 
class Message < ActiveRecord::Base
  acts_as_state_machine :initial => Proc.new {|message| message.recipient ? :unread : :unsent}
  
  belongs_to    :from,
                  :polymorphic => true
  belongs_to    :recipient,
                  :polymorphic => true
  
  # Add associations for different types of recipients:
  # * to - Your direct recipients
  # * cc - Carbon copies
  # * bcc - Blind carbon copies
  with_options(
    :class_name => 'MessageRecipient',
    :foreign_key => 'message_id',
    :order => 'position ASC',
    :extend => Message::EasyBuildRecipientExtension
  ) do |w|
    w.has_many  :to,
                  :conditions => ['kind = ?', 'to']
    w.has_many  :cc,
                  :conditions => ['kind = ?', 'cc']
    w.has_many  :bcc,
                  :conditions => ['kind = ?', 'bcc']
  end
  
  # Support reading from, to, cc, and bcc from the reference message
  # if this message was forwarded
  [:from, :to, :cc, :bcc].each do |method|
    eval <<-end_eval
      def #{method}_with_reference_message
        recipient ? reference_message.#{method} : #{method}_without_reference_message
      end
      alias_method_chain :#{method}, :reference_message
    end_eval
  end
  
  # Reference messages are used for forwarding so that we don't duplicate data
  # and so we can track where it came from
  belongs_to    :reference_message,
                  :class_name => 'Message',
                  :foreign_key => 'reference_message_id'
  
  validates_xor_presence_of :from_id,
                            :recipient_id,
                              :if => :only_model_participants?
  
  state :unsent
  state :queued
  state :sent, :after_enter => :deliver
  state :unread
  state :read
  state :deleted
  
  # Queues the message so that it is sent in a separate process
  event :queue do
    transition_to :queued, :from => :unsent,
                    :if => Proc.new {|message| message.number_of_recipients > 0}
  end
  
  # Sends the message to all of the recipients as long as at least one
  # recipient has been aded
  event :send do
    transition_to :sent, :from => [:unsent, :queued],
                    :if => Proc.new {|message| message.number_of_recipients > 0}
  end
  
  # Indicates that the message has been viewed by the recipient of this
  # message
  event :view do
    transition_to :read, :from => :unread
  end
  
  # Deletes the message
  event :delete do
    transition_to :deleted, :from => [:unread, :read, :sent]
  end
  
  [:subject, :body].each do |method|
    class_eval <<-end_eval
      def #{method}
        from ? read_attribute(:#{method}) : reference_message.#{method}
      end
    end_eval
  end
  
  # Support getting all of the messageables of the message's
  # recipients regardless of whether cross-model messaging is being
  # allowed
  [:to, :cc, :bcc].each do |method|
    eval <<-end_eval
      def #{method}_recipients
        #{method}.collect {|recipient| recipient.messageable}
      end
    end_eval
  end
  
  # 
  def all_recipients
    to + cc + bcc
  end
  
  # 
  def number_of_recipients
    to.size + cc.size + bcc.size
  end
  
  # 
  def forward
    message = self.class.new
    message.reference_message = self
    message
  end
  
  private
  # Are only models allowed to be the from/recipient of this message?  Or can
  # other classes, like strings, be allowed?
  def only_model_participants?
    true
  end
  
  # Copies the current message to all recipients
  def copy_to_recipients
    received_messages = "received_#{self.class.name.underscore.pluralize}"
    
    (to + cc + bcc).each do |recipient|
      if recipient.messageable.respond_to?(received_messages)
        message = recipient.messageable.send(received_messages).build
      else
        message = self.class.new
        message.recipient = recipient.messageable
      end
      
      message.reference_message = self
      message.save
    end
  end
  alias_method :deliver, :copy_to_recipients
end
