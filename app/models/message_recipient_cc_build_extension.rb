# 
module MessageRecipientCcBuildExtension
  include MessageRecipientBuildExtension
  
  def kind #:nodoc:
    'cc'
  end
end