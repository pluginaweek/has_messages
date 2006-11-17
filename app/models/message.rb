# 
#
class Message < ActiveRecord::Base
  acts_as_state_machine     :initial => Proc.new {|message| message.recipient ? :unread : :unsent}
  
  validates_xor_presence_of :from_id,
                            :recipient_id,
                              :if => :only_model_participants?
  
  state :unsent
  state :queued
  state :sent, :enter => :deliver
  state :unread
  state :read
  state :deleted
  
  # Queues the message so that it is sent in a separate process
  event :queue do
    transition_to :queued, :from => :unsent,
                    :guard => Proc.new {|message| message.number_of_recipients > 0}
  end
  
  # Sends the message to all of the recipients as long as at least one
  # recipient has been aded
  event :send do
    transition_to :sent, :from => [:unsent, :queued],
                    :guard => Proc.new {|message| message.number_of_recipients > 0}
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
  
  #
  #
  def all_recipients
    to + cc + bcc
  end
  
  #
  #
  def number_of_recipients
    to.size + cc.size + bcc.size
  end
  
  #
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
  def copy_to_recipients(assoc_names = self.class.name.underscore.pluralize)
    (to + cc + bcc).each do |recipient|
      if recipient.messageable.respond_to?(:"received_#{assoc_names}")
        message = recipient.messageable.send(:"received_#{assoc_names}").build
      else
        message = self.class.new
        message.recipient = recipient.messageable
      end
      
      message.reference_message = self
      message.save
    end
  end
end
