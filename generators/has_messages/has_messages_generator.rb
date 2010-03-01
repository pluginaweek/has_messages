class HasMessagesGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.migration_template '001_create_messages.rb', 'db/migrate', :migration_file_name => 'create_messages'
      m.sleep 1
      m.migration_template '002_create_message_recipients.rb', 'db/migrate', :migration_file_name => 'create_message_recipients'
    end
  end
end
