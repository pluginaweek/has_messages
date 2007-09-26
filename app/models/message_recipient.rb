# Represents a recipient of a message.  The kind of recipient (to, cc, or bcc) is
# stored in the +kind+ attribute.
# 
# == States
#
# Recipients can be in 1 of 4 states:
# * +unread+ - The message has been sent, but not yet read by the recipient.  This is the *initial* state.
# * +read+ - The message has been read by the recipient
# * +deleted+ - The message has been deleted by the recipient
class MessageRecipient < ActiveRecord::Base
  has_finder :active, :conditions => {:deleted_at => nil}
  
  acts_as_list :scope => 'message_id = #{message_id} AND kind = #{quote_value(kind)}'
  
  belongs_to  :message
  belongs_to  :receiver,
                :polymorphic => true
  has_states  :initial => :unread
  
  validates_presence_of :message_id,
                        :kind,
                        :state_id
  validates_presence_of :receiver_id,
                        :receiver_type,
                          :if => :model_participant?
  
  state :unread,
        :read
  
  alias_method :sent_at, :unread_at
  
  # Indicates that the message has been viewed by the receiver
  event :view do
    transition_to :read, :from => :unread, :if => :message_sent?
  end
  
  # Is this recipient *not* yet deleted and still visible to the receiver?
  def active?
    deleted_at.nil?
  end
  
  # True if this message has been deleted and is no longer active
  def deleted?
    !active?
  end
  
  # Actually destroys the message if every recipient has destroyed their copy
  def destroy_with_recipient_check
    if message.deleted? && (message.all_recipients - [self]).all? {|recipient| recipient.deleted?}
      if active?
        update_attribute :deleted_at, Time.now
        message.all_recipients(true) # Reload the recipients
        message.destroy
      else
        destroy_without_recipient_check
      end
    else
      update_attribute :deleted_at, Time.now
    end
  end
  alias_method_chain :destroy, :recipient_check
  
  private
  # Has the message this recipient is on been sent?
  def message_sent?
    message.sent?
  end
  
  # Must the receiver be a model?
  def model_participant?
    true
  end
end
