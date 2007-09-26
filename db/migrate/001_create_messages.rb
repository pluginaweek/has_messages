class CreateMessages < ActiveRecord::Migration
  def self.up
    create_table :messages do |t|
      t.column :sender_id, :integer, :null => false, :references => nil
      t.column :sender_type, :string, :null => false
      t.column :subject, :text
      t.column :body, :text
      t.column :created_at, :datetime, :null => false
      t.column :deleted_at, :datetime
      t.column :type, :string
    end
    
    PluginAWeek::Has::States.migrate_up(:messages)
  end

  def self.down
    PluginAWeek::Has::States.migrate_down(:messages)
    
    drop_table :messages
  end
end
