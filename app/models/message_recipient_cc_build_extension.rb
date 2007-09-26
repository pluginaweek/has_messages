# Build support for +cc+ recipients
module MessageRecipientCcBuildExtension
  include MessageRecipientBuildExtension
  
  def kind #:nodoc:
    'cc'
  end
end
