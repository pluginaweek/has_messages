module Factory
  # Build actions for the class
  def self.build(klass, &block)
    name = klass.to_s.underscore
    define_method("#{name}_attributes", block)
    
    module_eval <<-end_eval
      def valid_#{name}_attributes(attributes = {})
        #{name}_attributes(attributes)
        attributes
      end
      
      def new_#{name}(attributes = {})
        #{klass}.new(valid_#{name}_attributes(attributes))
      end
      
      def create_#{name}(*args)
        record = new_#{name}(*args)
        record.save!
        record.reload
        record
      end
    end_eval
  end
  
  build Message do |attributes|
    attributes[:sender] = create_user unless attributes.include?(:sender)
    attributes.reverse_merge!(
      :subject => 'New features',
      :body => 'Lots of new things to talk about... come to the meeting tonight to find out!'
    )
  end
  
  build MessageRecipient do |attributes|
    attributes[:message] = create_message unless attributes.include?(:message)
    attributes[:receiver] = create_user(:login => 'me') unless attributes.include?(:receiver)
    attributes.reverse_merge!(
      :kind => 'to'
    )
  end
  
  build User do |attributes|
    attributes.reverse_merge!(
      :login => 'admin'
    )
  end
end
