class CreateMessageRecipients < ActiveRecord::Migration
  def self.up
    create_table :message_recipients do |t|
      t.column :message_id, :integer, :null => false
      t.column :receiver_id, :integer, :null => false, :references => nil
      t.column :receiver_type, :string, :null => false
      t.column :kind, :string, :null => false, :default => 'to'
      t.column :position, :integer, :null => false
      t.column :type, :string
    end
    add_index :message_recipients, [:message_id, :kind, :position], :unique => true
    
    PluginAWeek::Has::States.migrate_up(:message_recipients)
  end
  
  def self.down
    PluginAWeek::Has::States.migrate_down(:message_recipients)
    
    drop_table :message_recipients
  end
end
