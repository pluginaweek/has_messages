# 
class Message < ActiveRecord::Base
  has_states :initial => :deleted
  
  state :deleted
  
  validates_presence_of :owner_id,
                        :state_id
  
  # Support getting all of the messageables of the message's recipients
  [:to, :cc, :bcc].each do |method|
    eval <<-end_eval
      def #{method}_receivers
        #{method}.collect {|recipient| recipient.messageable}
      end
    end_eval
  end
  
  # 
  def all_receivers
    all_recipients.collect {|recipient| recipient.messageable}
  end
  
  # 
  def number_of_recipients
    all_recipients.size
  end
  
  # 
  def reply_to_all
    message = reply
    [:cc, :bcc].each do |recipient_type|
      send(recipient_type).each do |recipient|
        message.send(recipient_type) << recipient.messageable
      end
    end
    
    message
  end
end
