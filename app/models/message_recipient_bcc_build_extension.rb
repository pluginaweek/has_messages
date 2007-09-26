# Build support for +bcc+ recipients
module MessageRecipientBccBuildExtension
  include MessageRecipientBuildExtension
  
  def kind #:nodoc:
    'bcc'
  end
end
