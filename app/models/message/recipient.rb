class Message < ActiveRecord::Base #:nodoc:
  # Represents a recipient of a message
  class Recipient < ActiveRecord::Base
    acts_as_list          :scope => 'message_id = #{message_id} AND kind = #{quote_value(kind)}'
    
    validates_presence_of :message_id,
                          :kind
    
    def validate_on_create #:nodoc:
      errors.add 'messageable_id', 'must be a class that acts_as_messagable' if messageable && !messageable.class.const_defined?('Message')
    end
  end
end