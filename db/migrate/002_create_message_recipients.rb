class CreateMessageRecipients < ActiveRecord::Migration
  def self.up
    create_table :message_recipients do |t|
      t.column :messageable_id, :integer, :unsigned => true, :references => nil
      t.column :message_id,     :integer, :null => false, :unsigned => true
      t.column :kind,           :string,  :null => false, :default => 'to'
      t.column :position,       :integer, :null => false
      t.column :type,           :string,  :null => false
    end
    add_index :message_recipients, [:message_id, :messageable_id, :type], :unique => true, :name => 'index_message_recipients_on_message_and_messageable_and_type'
    add_index :message_recipients, [:message_id, :kind, :position], :unique => true
  end
  
  def self.down
    drop_table :message_recipients
  end
end