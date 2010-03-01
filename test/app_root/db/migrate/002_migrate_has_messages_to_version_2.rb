class MigrateHasMessagesToVersion2 < ActiveRecord::Migration
  def self.up
    ActiveRecord::Migrator.new(:up, "#{Rails.root}/../../generators/has_messages/templates", 0).migrations.each do |migration|
      migration.migrate(:up)
    end
  end
  
  def self.down
    ActiveRecord::Migrator.new(:down, "#{Rails.root}/../../generators/has_messages/templates", 0).migrations.each do |migration|
      migration.migrate(:down)
    end
  end
end
