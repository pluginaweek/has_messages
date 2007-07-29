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
            :sender_class,
            :recipient_class,
            :received_class
          )
          options.reverse_merge!(:message_class => 'Message')
          options[:sender_class] ||= (const_defined?("Sender#{options[:message_class]}") ? "Sender#{options[:message_class]}" : 'SenderMessage')
          options[:recipient_class] ||= (const_defined?("#{options[:message_class]}Recipient") ? "#{options[:message_class]}Recipient" : 'MessageRecipient')
          options[:receiver_class] ||= (const_defined?("Receiver#{options[:message_class]}") ? "Receiver#{options[:message_class]}" : 'ReceiverMessage')
          
          assoc_names = args.first ? args.first.to_s : 'messages'
          assoc_name = assoc_names.singularize
          
          # Add recipients
          message_recipients = :"#{assoc_name}_recipients"
          has_many  message_recipients,
                      :foreign_key => 'messageable_id',
                      :conditions => ['message_recipients.messageable_type = ?', self.to_s],
                      :class_name => options[:recipient_class]
          
          # Add received messages
          received_messages = :"received_#{assoc_names}"
          has_many  received_messages,
                      :through => message_recipients,
                      :source => :receiver_messages,
                      :class_name => options[:receiver_class],
                      :extend => Message::StateExtension,
                      :order => 'messages.created_at ASC'
          
          # Add unsent messages
          unsent_messages = :"unsent_#{assoc_names}"
          has_many  unsent_messages,
                      :as => :owner,
                      :class_name => options[:sender_class],
                      :extend => Message::StateExtension,
                      :conditions => ['messages.state_id = ?', SenderMessage.states.find_by_name('unsent')],
                      :order => 'messages.created_at ASC'
          
          # Add sent messages
          sent_messages = :"sent_#{assoc_names}"
          has_many  sent_messages,
                      :as => :owner,
                      :class_name => options[:sender_class],
                      :extend => Message::StateExtension,
                      :conditions => ['messages.state_id = ?', SenderMessage.states.find_by_name('sent')],
                      :order => 'messages.created_at ASC'
          
          # Create access to a mailbox that contains the received and sent
          # messages.
          module_eval <<-end_eval
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