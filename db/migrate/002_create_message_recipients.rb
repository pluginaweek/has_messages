class CreateMessageRecipients < ActiveRecord::Migration
  def self.up
    create_table :message_recipients do |t|
      t.column :message_id,       :integer, :null => false, :unsigned => true
      t.column :messageable_id,   :integer, :null => false, :unsigned => true, :references => nil
      t.column :messageable_type, :string,  :null => false
      t.column :kind,             :string,  :null => false, :default => 'to'
      t.column :position,         :integer, :null => false
    end
    add_index :message_recipients, [:message_id, :messageable_id, :messageable_type], :unique => true, :name => 'index_message_recipients_on_message_id_and_messageable'
    add_index :message_recipients, [:message_id, :kind, :position], :unique => true
  end
  
  def self.down
    drop_table :message_recipients
  end
end