require File.dirname(__FILE__) + '/../test_helper'

class MessageRecipientTest < Test::Unit::TestCase
  fixtures :users, :messages, :message_recipients
  
  def test_should_require_message_id
    assert_invalid message_recipients(:bob_to_john), :message_id, nil
  end
  
  def test_should_require_kind
    assert_invalid message_recipients(:bob_to_john), :kind, nil
  end
  
  def test_should_require_messageable_id
    assert_invalid message_recipients(:bob_to_john), :messageable_id, nil
  end
  
  def test_should_require_messageable_type
    assert_invalid message_recipients(:bob_to_john), :messageable_type, nil
  end
  
  def test_should_require_state_id
    assert_invalid message_recipients(:bob_to_john), :state_id, nil
  end
  
  def test_initial_state_should_be_unsent
    assert_equal :unsent, MessageRecipient.new.initial_state.to_sym
  end
  
  def test_should_set_position_based_on_number_of_recipients_in_to
    recipient = MessageRecipient.new
    recipient.message = messages(:sent_from_bob)
    recipient.messageable = users(:bob)
    recipient.kind = 'to'
    
    assert recipient.save!
    assert_equal 2, recipient.position
  end
  
  def test_should_set_position_based_on_number_of_recipients_in_cc
    recipient = MessageRecipient.new
    recipient.message = messages(:sent_from_bob)
    recipient.messageable = users(:bob)
    recipient.kind = 'cc'
    
    assert recipient.save!
    assert_equal 2, recipient.position
  end
  
  def test_should_set_position_based_on_number_of_recipients_in_bcc
    recipient = MessageRecipient.new
    recipient.message = messages(:sent_from_bob)
    recipient.messageable = users(:bob)
    recipient.kind = 'bcc'
    
    assert recipient.save!
    assert_equal 1, recipient.position
  end
  
  def test_should_have_message_association
    assert_equal messages(:sent_from_bob), message_recipients(:bob_to_john).message
  end
  
  def test_message_should_only_be_sender_message
    recipient = MessageRecipient.new
    message = recipient.build_message
    
    assert_instance_of SenderMessage, message
  end
  
  def test_should_have_messageable_association
    assert_equal users(:john), message_recipients(:bob_to_john).messageable
  end
  
  def test_should_have_receiver_message_association_if_sent
    assert_equal messages(:bob_to_john), message_recipients(:bob_to_john).receiver_message
  end
  
  def test_should_not_have_receiver_message_association_if_not_sent
    assert_nil message_recipients(:unsent_bob_to_john).receiver_message
  end
  
  def test_should_be_sent_if_already_sent
    assert message_recipients(:bob_to_john).sent?
  end
  
  def test_should_be_unsent_if_not_yet_sent
    assert message_recipients(:unsent_bob_to_john).unsent?
  end
  
  def test_should_deliver_if_unsent
    assert message_recipients(:unsent_bob_to_john).deliver!
  end
  
  def test_should_not_deliver_if_sent
    assert !message_recipients(:bob_to_john).deliver!
  end
  
  def test_should_create_receiver_message_when_delivered
    recipient = message_recipients(:unsent_bob_to_john)
    recipient.deliver!
    
    assert_not_nil recipient.receiver_message
  end
end
