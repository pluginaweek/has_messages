# Contains the received and sent messages for a particular box
class MessageBox
  attr_reader :inbox,
              :unsent,
              :sent
  
  def initialize(inbox, unsent, sent)
    @inbox, @unsent, @sent = inbox, unsent, sent
  end
end