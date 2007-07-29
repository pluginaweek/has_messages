class MessageRecipient < ActiveRecord::Base #:nodoc:
  # 
  module EasyBuildCcExtension
    include EasyBuildExtension
    
    def kind #:nodoc:
      'cc'
    end
  end
end