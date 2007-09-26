# Build support for +to+ recipients
module MessageRecipientToBuildExtension
  include MessageRecipientBuildExtension
  
  def kind #:nodoc:
    'to'
  end
end
