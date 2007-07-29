class MessageRecipient < ActiveRecord::Base #:nodoc:
  # 
  module EasyBuildToExtension
    include EasyBuildExtension
    
    def kind #:nodoc:
      'to'
    end
  end
end