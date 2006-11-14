class Message < ActiveRecord::Base #:nodoc:
  #
  #
  module EasyBuildRecipientExtension
    # Add +records+ to this association.  The records can either be instances
    # of Message::Recipient or the owner (such as User).
    def <<(*records)
      result = true
      load_target
      
      # added
      records = convert_records(flatten_deeper(records))
      
      @owner.transaction do
        flatten_deeper(records).each do |record|
          raise_on_type_mismatch(record)
          callback(:before_add, record)
          result &&= insert_record(record) unless @owner.new_record?
          @target << record
          callback(:after_add, record)
        end
      end
      
      result && self
    end
    alias_method :push, :<<
    alias_method :concat, :<<
    
    # Remove +records+ from this association.  The records can either be
    # instances of Message:Recipient or the owner (such as User)
    def delete(*records)
      # added
      records = flatten_deeper(records).inject([]) do |recipients, record|
        recipient = find_recipient(record, @target)
        recipients << recipient if recipient
        recipients
      end
      
      records = flatten_deeper(records)
      records.each { |record| raise_on_type_mismatch(record) }
      records.reject! { |record| @target.delete(record) if record.new_record? }
      return if records.empty?
      
      @owner.transaction do
        records.each { |record| callback(:before_remove, record) }
        delete_records(records)
        records.each do |record|
          @target.delete(record)
          callback(:after_remove, record)
        end
      end
    end
    
    # Replace this collection with +other_array+.  Insances of Message::Recipient
    # in +other_array+ can replace instances of the owner class (such as User)
    # if the Recipient's messageable is equal to the owner.  This works both
    # ways.
    def replace(other_array)
      other_array.each { |val| raise_on_type_mismatch(val) }
      
      load_target
      other   = other_array.size < 100 ? other_array : other_array.to_set
      current = @target.size < 100 ? @target : @target.to_set
      
      @owner.transaction do
        delete(@target.select { |v| find_record(v, other).nil? }) # modified
        concat(other_array.select { |v| find_recipient(v, current).nil? }) # modified
      end
    end
    
    # Converts all of the records to instances of the Recipient class
    def convert_records(records) #:nodoc:
      records.collect do |record|
        if recipient_class = get_recipient_class(record)
          recipient = recipient_class.new
          recipient.messageable = record
          record = recipient
        end
        
        record
      end
    end
    
    # Determines whether or not the Recipient is equal to the specified record
    def is_recipient_equal?(recipient, record) #:nodoc:
      recipient.messageable == record
    end
    
    # Finds the +recipient+ in the +collection+, using the recipient's
    # messageable for determining equality
    def find_record(recipient, collection) #:nodoc:
      collection.find {|record| is_recipient_equal?(recipient, record)}
    end
    
    # Finds the +record+ in the +collection, using the recipients in the
    # collection to determine equality with the record
    def find_recipient(record, collection) #:nodoc:
      if !(Message::Recipient === record)
        record = collection.find {|recipient| is_recipient_equal?(recipient, record)}
      end
      
      record
    end
    
    # Gets the Recipient class for the record
    def get_recipient_class(record) #:nodoc:
      if !(Message::Recipient === record)
        message_class_name = @owner.class.name.demodulize
        begin
          "#{record.class}::#{message_class_name}::Recipient".constantize
        rescue NameError
          raise ArgumentError, "Recipients must be instances of a class that acts_as_messageable: #{record.class}"
        end
      end
    end
    
    def raise_on_type_mismatch(record) #:nodoc:
      unless record.is_a?(@reflection.klass) || get_recipient_class(record) # modified
        raise ActiveRecord::AssociationTypeMismatch, "#{@reflection.class_name} expected, got #{record.class}"
      end
    end
  end
end