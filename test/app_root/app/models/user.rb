class User < ActiveRecord::Base
  has_messages
  has_messages :notes
end
