# acts
require 'acts_as_state_machine'

# validations
require 'validates_xor_presence_of'

# miscellaneous
require 'kind_associations'

module PluginAWeek #:nodoc:
  module Acts #:nodoc:
    module Messageable
      def self.included(base) #:nodoc:
        base.extend(MacroMethods)
      end
      
      module MacroMethods
        # Configuration options:
        # * <tt>cross_model_messaging</tt> - 
        # * <tt>class_name</tt> - 
        # * <tt>association_name</tt> - 
        # * <tt>conditions</tt> - 
        # * <tt>order</tt> - 
        # * <tt>group</tt> - 
        # * <tt>extend</tt> - 
        # * <tt>include</tt> - 
        # * <tt>group</tt> - 
        # * <tt>limit</tt> - 
        # * <tt>offset</tt> - 
        # 
        def acts_as_messageable(options = {})
          options.symbolize_keys!.reverse_merge!(
            :cross_model_messaging => false,
            :class_name => 'Message'
          )
          options[:association_name] ||= options[:class_name].demodulize.downcase.underscore
          raise ArgumentError, 'acts_as_messageable can only be called once per message class' if const_defined?(options[:class_name])
          
          model_name = "::#{self.name}"
          model_assoc_name = model_name.demodulize.underscore
          
          allow_cross_model_messaging = options[:cross_model_message]
          
          # Options for name of the association
          assoc_name = options[:association_name]
          assoc_names = assoc_name.pluralize
          
          # Options for the name of the message class
          message_class_name = options[:class_name]
          message_class = "::#{message_class_name}".constantize
          recipient_class = message_class::Recipient
          
          allowed_message_class_name = "::#{message_class}"
          allowed_recipient_class_name = "::#{recipient_class}"
          
          # Change the types for association collections based on whether other
          # models that act as messageable are allowed to message us as well
          if !allow_cross_model_messaging
            allowed_message_class_name = model_name + allowed_message_class_name 
            allowed_recipient_class_name = model_name + allowed_recipient_class_name
          end
          
          # Create the inner message model
          inner_message_class = Class.new(message_class)
          const_set(message_class_name, inner_message_class).class_eval do
            belongs_to    :from,
                            :class_name => model_name,
                            :foreign_key => 'from_id',
                            :dependent => :destroy
            belongs_to    :recipient,
                            :class_name => model_name,
                            :foreign_key => 'recipient_id',
                            :dependent => :destroy
            
            # Add different types of recipients
            # to: Regular visible recipients
            # cc: Carbon-copy
            # bcc: Blind carbon-copy
            with_options(
              :class_name => allowed_recipient_class_name,
              :foreign_key => 'message_id',
              :order => 'position ASC',
              :extend => message_class::EasyBuildRecipientExtension
            ) do |w|
              w.has_many  :to,  :kind => 'to'
              w.has_many  :cc,  :kind => 'cc'
              w.has_many  :bcc, :kind => 'bcc'
            end
            
            belongs_to    :reference_message,
                            :class_name => allowed_message_class_name,
                            :foreign_key => 'reference_message_id'
            
            # If it's not a message model, then add aliases
            if assoc_name != 'message'
              alias_method  "reference_#{assoc_name}", :reference_message
              alias_attribute "reference_#{assoc_name}_id", :reference_message_id
            end
            
            [:from, :to, :cc, :bcc].each do |method|
              class_eval <<-end_eval
                def #{method}_with_reference_message
                  recipient ? reference_message.#{method} : #{method}_without_reference_message
                end
                alias_method_chain :#{method}, :reference_message
              end_eval
            end
            
            [:to, :cc, :bcc].each do |method|
              if allow_cross_model_messaging
                class_eval <<-end_eval
                  def #{method}_recipients
                    #{method}.collect {|recipient| recipient.messageable}
                  end
                end_eval
              else
                has_many  :"#{method}_recipients",
                            :through => method,
                            :source => :messageable
              end
            end
          end
          
          inner_message_class.class_eval <<-end_eval
            private
            def deliver
              (to + cc + bcc).each do |recipient|
                message = recipient.messageable.received_#{assoc_names}.build
                message.reference_message = self
                message.save
              end
            end
          end_eval
          
          inner_message_class_name = "::#{inner_message_class}"
          
          # Create the recipient model
          inner_message_class.const_set('Recipient', Class.new(message_class::Recipient)).class_eval do
            belongs_to    :messageable,
                            :class_name => model_name,
                            :foreign_key => 'messageable_id',
                            :dependent => :destroy
            alias_method    model_assoc_name, :messageable
            alias_attribute "#{model_assoc_name}_id", :messageable_id
            
            belongs_to    :message,
                            :class_name => inner_message_class_name,
                            :foreign_key => 'message_id'
            
            if assoc_name != 'message'
              alias_method    assoc_name, :message
              alias_attribute "#{assoc_name}_id", :message_id
            end
          end
          
          has_many_options = options.reject {|option, value| [:cross_model_messaging, :class_name, :association_name].include?(option)}
          if has_many_options[:extend]
            has_many_options[:extend] = [has_many_options[:extend], Message::StateExtension]
          else
            has_many_options[:extend] = Message::StateExtension
          end
          
          # Add received messages
          received_messages = "received_#{assoc_names}"
          has_many  received_messages.to_sym, {
                      :class_name => inner_message_class_name,
                      :foreign_key => 'recipient_id'
                    }.merge(has_many_options) do
            
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
          sent_messages = "sent_#{assoc_names}"
          has_many  sent_messages.to_sym, {
                      :class_name => inner_message_class_name,
                      :foreign_key => 'from_id'
                    }.merge(has_many_options) do
            
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