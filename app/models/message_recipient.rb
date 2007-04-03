# Represents a recipient of a message
class MessageRecipient < ActiveRecord::Base
  acts_as_list          :scope => 'message_id = #{message_id} AND message_type = #{message_type} AND kind = #{quote_value(kind)}'
  
  belongs_to            :message
  belongs_to            :messageable,
                          :polymorphic => true
  
  validates_presence_of :message_id,
                        :message_type,
                        :kind
end