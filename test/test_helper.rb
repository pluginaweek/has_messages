# Load local repository plugin paths
$:.unshift("#{File.dirname(__FILE__)}/../../../associations/class_associations/lib")
$:.unshift("#{File.dirname(__FILE__)}/../../../has/has_association_helper/lib")
$:.unshift("#{File.dirname(__FILE__)}/../../../has/has_states/lib")
$:.unshift("#{File.dirname(__FILE__)}/../../../miscellaneous/dry_transaction_rollbacks/lib")
$:.unshift("#{File.dirname(__FILE__)}/../../../../ruby/object/eval_call/lib")

# Load the plugin testing framework
$:.unshift("#{File.dirname(__FILE__)}/../../../../test/plugin_test_helper/lib")
require 'rubygems'
require 'plugin_test_helper'

PluginAWeek::PluginMigrations.migrate('has_states')
PluginAWeek::PluginMigrations.migrate('has_messages')

# Run the migrations
ActiveRecord::Migrator.migrate("#{RAILS_ROOT}/db/migrate")

# Bootstrap the database
Dir.glob("#{File.dirname(__FILE__)}/../db/bootstrap/*.{yml,csv}").each do |fixture_file|
  Fixtures.create_fixtures('db/bootstrap', File.basename(fixture_file, '.*'))
end

class Test::Unit::TestCase #:nodoc:
  def self.require_fixture_classes(table_names=nil)
    # Don't allow fixture classes to be required because classes like Message are
    # going to throw an error since the states and events have not yet been
    # loaded
  end
end