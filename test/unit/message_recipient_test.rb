require File.dirname(__FILE__) + '/../test_helper'

class MessageRecipientTest < Test::Unit::TestCase
  fixtures :users, :messages, :message_recipients, :state_changes
  
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
  
  def test_initial_state_should_be_unread
    assert_equal :unread, MessageRecipient.new.initial_state.to_sym
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
  
  def test_should_not_view_if_unsent
    assert !message_recipients(:unsent_bob_to_john).view!
  end
  
  def test_should_view_if_unread
    assert message_recipients(:bob_to_mary).view!
  end
  
  def test_should_not_view_if_read
    assert !message_recipients(:bob_to_john).view!
  end
  
  def test_should_be_active_if_not_yet_deleted
    assert message_recipients(:bob_to_john).active?
  end
  
  def test_should_not_be_active_if_deleted
    m = message_recipients(:bob_to_john)
    m.destroy
    assert !m.active?
  end
  
  def test_should_be_deleted_if_deleted
    m = message_recipients(:bob_to_john)
    m.destroy
    assert m.deleted?
  end
  
  def test_should_not_be_deleted_if_not_deleted
    assert !message_recipients(:bob_to_john).deleted?
  end
  
  def test_should_destroy_but_not_delete_if_message_and_sent_messages_still_exist
    m = message_recipients(:bob_to_john)
    assert m.destroy
    m.reload
    assert m.deleted_at?
    assert MessageRecipient.exists?(m.id)
  end
  
  def test_should_destroy_and_delete_if_sent_messages_destroyed
    messages(:sent_from_bob).destroy
    message_recipients(:bob_to_mary).destroy
    
    m = message_recipients(:bob_to_john)
    m.destroy
    assert !MessageRecipient.exists?(m.id)
  end
end
