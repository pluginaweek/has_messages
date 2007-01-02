class CreateMessages < ActiveRecord::Migration
  class State < ActiveRecord::Base; end
  class Event < ActiveRecord::Base; end
  class StateChange < ActiveRecord::Base; end
  
  class Message < ActiveRecord::Base
    class State < State; end
    class Event < Event; end
    class StateChange < StateChange; end
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
    
    PluginAWeek::Acts::StateMachine.migrate_up(Message)
  end

  def self.down
    PluginAWeek::Acts::StateMachine.migrate_down(Message)
    
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