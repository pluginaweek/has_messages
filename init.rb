# acts
require_plugin 'acts_as_state_machine'

# validations
require_plugin 'validates_xor_presence_of'

# miscellaneous
require_plugin 'kind_associations'

require 'acts_as_messageable'

ActiveRecord::Base.class_eval do
  include PluginAWeek::Acts::Messageable
end
