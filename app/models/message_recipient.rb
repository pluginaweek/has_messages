# Represents a recipient of a message
class MessageRecipient < ActiveRecord::Base
  acts_as_list          :scope => 'message_id = #{message_id} AND kind = #{quote_value(kind)}'
  
  belongs_to            :message
  belongs_to            :messageable,
                          :polymorphic => true
  
  validates_presence_of :message_id,
                        :kind
end