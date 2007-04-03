class CreateMessages < ActiveRecord::Migration
  class Message < ActiveRecord::Base; end
  class StateChange < ActiveRecord::Base; end
  class StateDeadline < ActiveRecord::Base; end
  
  class State < ActiveRecord::Base
    set_table_name 'states'
    
    has_many :messages, :class_name => Message.to_s, :dependent => :destroy
    has_many :from_changes, :class_name => StateChange.to_s, :foreign_key => 'from_state_id', :dependent => :destroy
    has_many :to_changes, :class_name => StateChange.to_s, :foreign_key => 'to_state_id', :dependent => :destroy
  end
  
  class Event < ActiveRecord::Base
    set_table_name 'events'
    
    has_many :state_changes, :class_name => StateChange.to_s, :foreign_key => 'event_id', :dependent => :destroy
    has_many :state_deadlines, :class_name => StateDeadline.to_s, :foreign_key => 'event_id', :dependent => :destroy
  end
  
  def self.up
    create_table :messages do |t|
      t.column :from_id,              :integer,   :null => false, :unsigned => true, :references => nil
      t.column :from_type,            :string,    :null => false
      t.column :recipient_id,         :integer,   :null => false, :unsigned => true, :references => nil
      t.column :recipient_type,       :string,    :null => false
      t.column :reference_message_id, :integer,   :unsigned => true, :references => :messages
      t.column :subject,              :text,      :null => false
      t.column :body,                 :text,      :null => false
      t.column :created_at,           :datetime,  :null => false
    end
    
    PluginAWeek::Acts::StateMachine.migrate_up(:messages)
  end

  def self.down
    PluginAWeek::Acts::StateMachine.migrate_down(:messages)
    
    drop_table :messages
  end
  
  def self.bootstrap
    {
      :states => {:class => State, :conditions => ['owner_type = ?', 'Message']},
      :events => {:class => Event, :conditions => ['owner_type = ?', 'Message']}
    }
  end
end