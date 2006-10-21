# 
#
class MessageBox
  attr_reader :inbox, :sent
  
  def initialize(inbox, sent)
    @inbox, @sent = inbox, sent
  end
end