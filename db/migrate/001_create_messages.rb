class CreateMessages < ActiveRecord::Migration
  class Message < ActiveRecord::Base
    acts_as_state_machine :initial => :dummy
  end
  
  def self.up
    create_table :messages do |t|
      t.column :from_id,              :integer,   :unsigned => true, :references => nil
      t.column :recipient_id,         :integer,   :unsigned => true, :references => nil
      t.column :reference_message_id, :integer,   :unsigned => true, :references => :messages
      t.column :subject,              :text,      :null => false
      t.column :body,                 :text,      :null => false
      t.column :created_at,           :datetime,  :null => false
      t.column :type,                 :string,    :null => false
    end
    
    Message::State.migrate_up
  end

  def self.down
    Message::State.migrate_down
    
    drop_table :messages
  end
  
  def self.bootstrap
    [
      Message::State,
      Message::Event,
      Message,
      Message::StateChange
    ]
  end
end