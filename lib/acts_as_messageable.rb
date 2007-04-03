# acts
require 'acts_as_state_machine'

# validations
require 'validates_xor_presence_of'

module PluginAWeek #:nodoc:
  module Acts #:nodoc:
    module Messageable
      def self.included(base) #:nodoc:
        base.extend(MacroMethods)
      end
      
      module MacroMethods
        # 
        def acts_as_messageable(*args)
          assoc_name = args.first.is_a?(Symbol) ? args.first.to_s : 'message'
          assoc_names = assoc_name.pluralize
          
          # Add received message
          default_options = {
            :as => 'recipient_type',
            :foreign_key => 'recipient_id',
            :class_name => 'Message',
            :extend => Message::StateExtension
          }
          received_messages = "received_#{assoc_names}"
          create_acts_association(received_messages, default_options, *(args.dup)) do
            # Set recipient value on build
            def build(attributes = {})
              if attributes.is_a?(Array)
                attributes.collect { |attr| build(attr) }
              else
                record = @reflection.klass.new(attributes)
                set_belongs_to_association_for(record)
                
                @target ||= [] unless loaded?
                @target << record
                
                record.recipient ||= @owner
                record
              end
            end
          end
          
          # Add sent messages
          default_options = {
            :as => 'from_type',
            :foreign_key => 'from_id',
            :class_name => 'Message',
            :extend => Message::StateExtension
          }
          sent_messages = "sent_#{assoc_names}"
          create_acts_association(sent_messages, default_options, *args) do
            # Set from value on build
            def build(attributes = {})
              if attributes.is_a?(Array)
                attributes.collect { |attr| build(attr) }
              else
                record = @reflection.klass.new(attributes)
                set_belongs_to_association_for(record)
                
                @target ||= [] unless loaded?
                @target << record
                
                record.from ||= @owner
                record
              end
            end
          end
          
          # Create access to a mailbox that contains the received and sent
          # messages.
          module_eval <<-end_eval
            def #{assoc_name}_box
              @#{assoc_name}_box ||= MessageBox.new(#{received_messages}, #{sent_messages})
            end
          end_eval
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include PluginAWeek::Acts::Messageable
end