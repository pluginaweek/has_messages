# Represents a recipient of a message
class MessageRecipient < ActiveRecord::Base
  acts_as_list :scope => 'message_id = #{message_id} AND kind = #{quote_value(kind)}'
  
  has_states  :initial => :unsent
  
  state :unsent,
        :sent
  
  event :deliver do
    transition_to :sent, :from => :unsent
  end
  
  belongs_to  :message,
                :class_name => 'SenderMessage',
                :foreign_key => 'message_id'
  belongs_to  :messageable,
                :polymorphic => true
  has_one     :receiver_message,
                :foreign_key => 'owner_id'
  has_many    :receiver_messages,
                :foreign_key => 'owner_id'
  
  validates_presence_of :message_id,
                        :kind,
                        :state_id
  validates_presence_of :messageable_id,
                        :messageable_type,
                          :if => :model_participant?
  
  # 
  def deliver
    message = build_receiver_message
    message.save!
  end
  
  private
  def model_participant?
    true
  end
end