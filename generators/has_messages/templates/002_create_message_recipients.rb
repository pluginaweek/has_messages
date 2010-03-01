class CreateMessageRecipients < ActiveRecord::Migration
  def self.up
    create_table :message_recipients do |t|
      t.references :message, :null => false
      t.references :receiver, :polymorphic => true, :null => false
      t.string :kind, :null => false
      t.integer :position
      t.string :state, :null => false
      t.datetime :hidden_at
    end
    add_index :message_recipients, [:message_id, :kind, :position], :unique => true
  end
  
  def self.down
    drop_table :message_recipients
  end
end
