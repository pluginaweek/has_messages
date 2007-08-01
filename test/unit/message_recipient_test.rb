require File.dirname(__FILE__) + '/../test_helper'

class MessageRecipientTest < Test::Unit::TestCase
  fixtures :users, :messages, :message_recipients
  
  def test_should_require_message_id
    assert_invalid message_recipients(:bob_to_john), :message_id, nil
  end
  
  def test_should_require_kind
    assert_invalid message_recipients(:bob_to_john), :kind, nil
  end
  
  def test_should_require_receiver_id
    assert_invalid message_recipients(:bob_to_john), :receiver_id, nil
  end
  
  def test_should_require_receiver_type
    assert_invalid message_recipients(:bob_to_john), :receiver_type, nil
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
    recipient.receiver = users(:bob)
    recipient.kind = 'to'
    
    assert recipient.save!
    assert_equal 2, recipient.position
  end
  
  def test_should_set_position_based_on_number_of_recipients_in_cc
    recipient = MessageRecipient.new
    recipient.message = messages(:sent_from_bob)
    recipient.receiver = users(:bob)
    recipient.kind = 'cc'
    
    assert recipient.save!
    assert_equal 2, recipient.position
  end
  
  def test_should_set_position_based_on_number_of_recipients_in_bcc
    recipient = MessageRecipient.new
    recipient.message = messages(:sent_from_bob)
    recipient.receiver = users(:bob)
    recipient.kind = 'bcc'
    
    assert recipient.save!
    assert_equal 1, recipient.position
  end
  
  def test_should_have_message_association
    assert_equal messages(:sent_from_bob), message_recipients(:bob_to_john).message
  end
  
  def test_should_have_receiver_association
    assert_equal users(:john), message_recipients(:bob_to_john).receiver
  end
  
  def test_should_be_unsent_if_not_yet_sent
    assert message_recipients(:unsent_bob_to_john).unsent?
  end
  
  def test_should_deliver_if_unsent
    assert message_recipients(:unsent_bob_to_john).deliver!
  end
  
  def test_should_not_deliver_if_unread
    assert !message_recipients(:bob_to_mary).deliver!
  end
  
  def test_should_not_deliver_if_read
    assert !message_recipients(:bob_to_john).deliver!
  end
  
  def test_should_not_view_if_unsent
    assert !message_recipients(:unsent_bob_to_john).view!
  end
  
  def test_should_view_if_unread
    assert message_recipients(:bob_to_mary).view!
  end
  
  def test_should_not_view_if_read
    assert !message_recipients(:bob_to_john).view!
  end
  
  def test_should_delete_if_unread
    assert message_recipients(:bob_to_mary).delete!
  end
  
  def test_should_delete_if_read
    assert message_recipients(:bob_to_john).delete!
  end
end
