module Factory
  # Build actions for the model
  def self.build(model, &block)
    name = model.to_s.underscore
    
    define_method("#{name}_attributes", block)
    define_method("valid_#{name}_attributes") {|*args| valid_attributes_for(model, *args)}
    define_method("new_#{name}")              {|*args| new_record(model, *args)}
    define_method("create_#{name}")           {|*args| create_record(model, *args)}
  end
  
  # Get valid attributes for the model
  def valid_attributes_for(model, attributes = {})
    name = model.to_s.underscore
    send("#{name}_attributes", attributes)
    attributes
  end
  
  # Build an unsaved record
  def new_record(model, *args)
    model.new(valid_attributes_for(model, *args))
  end
  
  # Build and save/reload a record
  def create_record(model, *args)
    record = new_record(model, *args)
    record.save!
    record.reload
    record
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
