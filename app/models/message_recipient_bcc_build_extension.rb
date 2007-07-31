# 
module MessageRecipientBccBuildExtension
  include MessageRecipientBuildExtension
  
  def kind #:nodoc:
    'bcc'
  end
end