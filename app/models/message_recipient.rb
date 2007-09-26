# Represents a recipient of a message.  The kind of recipient (to, cc, or bcc) is
# stored in the +kind+ attribute.
# 
# == States
#
# Recipients can be in 1 of 4 states:
# * +unsent+ - The message has yet to be sent to this recipient.  This is the *initial* state.
# * +unread+ - The message has been sent, but not yet read by the recipient
# * +read+ - The message has been read by the recipient
# * +deleted+ - The message has been deleted by the recipient
class MessageRecipient < ActiveRecord::Base
  acts_as_list :scope => 'message_id = #{message_id} AND kind = #{quote_value(kind)}'
  
  belongs_to  :message
  belongs_to  :receiver,
                :polymorphic => true
  has_states  :initial => :unsent
  
  validates_presence_of :message_id,
                        :kind,
                        :state_id
  validates_presence_of :receiver_id,
                        :receiver_type,
                          :if => :model_participant?
  
  state :unsent,
        :unread,
        :read,
        :deleted
  
  alias_method :sent_at, :unread_at
  
  # Delivers the message
  event :deliver do
    transition_to :unread, :from => :unsent
  end
  
  # Indicates that the message has been viewed by the receiver
  event :view do
    transition_to :read, :from => :unread
  end
  
  # Deletes the message
  event :delete, :after => :destroy do
    transition_to :deleted, :from => [:unread, :read]
  end
  
  private
  # Must the receiver be a model?
  def model_participant?
    true
  end
end
