require 'state_machine'

module PluginAWeek #:nodoc:
  # Adds a generic implementation for sending messages between users
  module HasMessages
    def self.included(base) #:nodoc:
      base.class_eval do
        extend PluginAWeek::HasMessages::MacroMethods
      end
    end
    
    module MacroMethods
      # Creates the following message associations:
      # * +messages+ - Messages that were composed and are visible to the owner.  Mesages may have been sent or unsent.
      # * +received_messages - Messages that have been received from others and are visible.  Messages may have been read or unread.
      # 
      # == Creating new messages
      # 
      # To create a new message, the +messages+ association should be used, for example:
      # 
      #   user = User.find(123)
      #   message = user.messages.build
      #   message.subject = 'Hello'
      #   message.body = 'How are you?'
      #   message.to User.find(456)
      #   message.save!
      #   message.deliver!
      # 
      # == Drafts
      # 
      # You can get the drafts for a particular user by using the +unsent_messages+
      # helper method.  This will find all messages in the "unsent" state.  For example,
      # 
      #   user = User.find(123)
      #   user.unsent_messages
      # 
      # You can also get at the messages that *have* been sent, using the +sent_messages+
      # helper method.  For example,
      # 
      #  user = User.find(123)
      #  user.sent_messages
      def has_messages
        has_many  :messages,
                    :as => :sender,
                    :class_name => 'Message',
                    :conditions => {:hidden_at => nil},
                    :order => 'messages.created_at ASC'
        has_many  :received_messages,
                    :as => :receiver,
                    :class_name => 'MessageRecipient',
                    :include => :message,
                    :conditions => ['message_recipients.hidden_at IS NULL AND messages.state = ?', 'sent'],
                    :order => 'messages.created_at ASC'
        
        include PluginAWeek::HasMessages::InstanceMethods
      end
    end
    
    module InstanceMethods
      # Composed messages that have not yet been sent
      def unsent_messages
        messages.with_state('unsent')
      end
      
      # Composed messages that have already been sent
      def sent_messages
        messages.with_states(%w(queued sent))
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include PluginAWeek::HasMessages
end
