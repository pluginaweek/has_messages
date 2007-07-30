require 'config/boot'

$:.unshift("#{RAILS_ROOT}/../../../../../rails/plugin_dependencies/lib")
begin
  require 'plugin_dependencies'
rescue
end

Rails::Initializer.run do |config|
  config.log_level = :debug
  config.cache_classes = false
  config.whiny_nils = true
  config.breakpoint_server = true
  config.load_paths << "#{RAILS_ROOT}/../../lib"
  
  config.plugin_paths.concat([
    "#{RAILS_ROOT}/../../..",
    "#{RAILS_ROOT}/../../../../migrations",
    "#{RAILS_ROOT}/../../../../../rails",
    "#{RAILS_ROOT}/../../../../../test",
    "#{RAILS_ROOT}/../../../../has"
  ])
  config.plugins = [
    File.basename(File.expand_path("#{RAILS_ROOT}/../..")),
    'appable_plugins',
    'plugin_migrations',
    'dry_validity_assertions',
    'has_states'
  ]
end

Dependencies.log_activity = true