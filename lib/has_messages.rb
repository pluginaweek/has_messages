require 'has_states'
require 'has_finder'

module PluginAWeek #:nodoc:
  module Has #:nodoc:
    # Adds support for messaging capabilities between models
    module Messages
      def self.included(base) #:nodoc:
        base.extend(MacroMethods)
      end
      
      module MacroMethods
        # Adds messaging support between this instances of the current model
        # class.
        # 
        # Configuration options:
        # * +message_class+ - The name of the class holding information about the message.  Default value is "Message".
        # * +recipient_class+ - The name of the class for creating recipients of messages.  Default value is "MessageRecipient".
        # 
        # == Generated associations
        # 
        # The following +has_many+ associations are created for models that support
        # messaging:
        # * +message+ - A collection of all Messages initiated by the sender (unsent or sent)
        # * +message_recipients+ - A collection of MessageRecipients in which this record is a receiver
        # 
        # == Generated instance methods
        # 
        # In addition to the above associations, the following instance methods
        # are created for models that support messaging:
        # * +received_messages+ - A collection of ReceivedMessages (wraps around the +message_recipients+ association)
        # * +unsent_messages+ - A collection of Messages which have not yet been sent
        # * +sent_messages+ - A collection of Messages which have already been sent
        # * +message_box+ - An instance of MessageBox, which contains received, unsent, and sent messages
        def has_messages(*args, &extension)
          options = extract_options_from_args!(args).symbolize_keys!
          options.assert_valid_keys(
            :message_class,
            :recipient_class
          )
          options.reverse_merge!(:message_class => 'Message')
          options[:recipient_class] ||= begin; "#{options[:message_class]}Recipient".constantize.to_s; rescue NameError; 'MessageRecipient'; end;
          
          messages = args.first ? args.first.to_s : 'messages'
          message = messages.singularize
          
          # Add messages
          has_many  messages.to_sym,
                      :as => :sender,
                      :class_name => options[:message_class],
                      :order => 'messages.created_at ASC'
          
          # Add recipients
          message_recipients = :"#{message}_recipients"
          has_many  message_recipients,
                      :as => :receiver,
                      :class_name => options[:recipient_class]
          
          received_messages = "received_#{messages}"
          unsent_messages = "unsent_#{messages}"
          sent_messages = "sent_#{messages}"
          
          # Create received, unsent, and sent messages; message box
          class_eval <<-end_eval
            def #{received_messages}
              #{message_recipients}.active.find_in_states(:all, :unread, :read, :include => :message, :conditions => ['messages.state_id = ?', Message.states.find_by_name('sent').id]).collect do |recipient|
                ReceivedMessage.new(recipient)
              end
            end
            
            def #{unsent_messages}(*args)
              #{messages}.active.unsent(*args)
            end
            
            def #{sent_messages}(*args)
              #{messages}.active.find_in_states(:all, :queued, :sent, *args)
            end
            
            def #{message}_box
              @#{message}_box ||= MessageBox.new(#{received_messages}, #{unsent_messages}, #{sent_messages})
            end
          end_eval
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include PluginAWeek::Has::Messages
end
