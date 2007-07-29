class CreateMessages < ActiveRecord::Migration
  def self.up
    create_table :messages do |t|
      t.column :owner_id, :integer, :null => false, :references => nil
      t.column :owner_type, :string
      t.column :subject, :text
      t.column :body, :text
      t.column :created_at, :datetime, :null => false
      t.column :type, :string, :null => false
    end
    
    PluginAWeek::Has::States.migrate_up(:messages)
  end

  def self.down
    PluginAWeek::Has::States.migrate_down(:messages)
    
    drop_table :messages
  end
end