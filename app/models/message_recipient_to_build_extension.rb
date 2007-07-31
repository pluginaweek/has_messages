# 
module MessageRecipientToBuildExtension
  include MessageRecipientBuildExtension
  
  def kind #:nodoc:
    'to'
  end
end