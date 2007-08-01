require 'has_states'

module PluginAWeek #:nodoc:
  module Has #:nodoc:
    module Messages
      def self.included(base) #:nodoc:
        base.extend(MacroMethods)
      end
      
      module MacroMethods
        # 
        def has_messages(*args, &extension)
          options = extract_options_from_args!(args).symbolize_keys!
          options.assert_valid_keys(
            :message_class,
            :recipient_class
          )
          options.reverse_merge!(:message_class => 'Message')
          options[:recipient_class] ||= begin; "#{options[:message_class]}Recipient".constantize.to_s; rescue NameError; 'MessageRecipient'; end;
          
          assoc_names = args.first ? args.first.to_s : 'messages'
          assoc_name = assoc_names.singularize
          
          # Add recipients
          message_recipients = :"#{assoc_name}_recipients"
          has_many  message_recipients,
                      :as => :receiver,
                      :class_name => options[:recipient_class]
          
          received_messages = "received_#{assoc_names}"
          class_eval <<-end_eval
            def #{received_messages}
              #{message_recipients}.find_in_states(:all, :unread, :read).collect do |recipient|
                ReceivedMessage.new(recipient)
              end
            end
          end_eval
          
          # Add unsent messages
          unsent_messages = :"unsent_#{assoc_names}"
          has_many  unsent_messages,
                      :as => :sender,
                      :class_name => options[:message_class],
                      :extend => Message::StateExtension,
                      :conditions => ['messages.state_id = ?', Message.states.find_by_name('unsent')],
                      :order => 'messages.created_at ASC'
          
          # Add sent messages
          sent_messages = :"sent_#{assoc_names}"
          has_many  sent_messages,
                      :as => :sender,
                      :class_name => options[:message_class],
                      :extend => Message::StateExtension,
                      :conditions => ['messages.state_id = ?', Message.states.find_by_name('sent')],
                      :order => 'messages.created_at ASC'
          
          # Create access to a mailbox that contains the received and sent
          # messages.
          class_eval <<-end_eval
            def #{assoc_name}_box
              @#{assoc_name}_box ||= MessageBox.new(#{received_messages}, #{unsent_messages}, #{sent_messages})
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