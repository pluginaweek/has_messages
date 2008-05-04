class MigrateHasMessagesToVersion2 < ActiveRecord::Migration
  def self.up
    Rails::Plugin.find(:has_messages).migrate(2)
  end
  
  def self.down
    Rails::Plugin.find(:has_messages).migrate(0)
  end
end
