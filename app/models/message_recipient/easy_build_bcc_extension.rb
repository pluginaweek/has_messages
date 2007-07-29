class MessageRecipient < ActiveRecord::Base #:nodoc:
  # 
  module EasyBuildBccExtension
    include EasyBuildExtension
    
    def kind #:nodoc:
      'bcc'
    end
  end
end