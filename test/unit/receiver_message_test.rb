require File.dirname(__FILE__) + '/../test_helper'

class RecipientMessageTest < Test::Unit::TestCase
  fixtures :users, :messages, :message_recipients
  
  def test_should_not_require_owner_type
    assert_valid messages(:bob_to_john), :owner_type, nil
  end
  
  def test_should_not_require_subject
    assert_valid messages(:bob_to_john), :subject, nil
  end
  
  def test_should_not_require_body
    assert_valid messages(:bob_to_john), :body, nil
  end
  
  def test_owner_should_be_message_recipient
    assert_equal message_recipients(:bob_to_john), messages(:bob_to_john).owner
  end
  
  def test_should_delegate_subject_to_sender_message
    assert_equal messages(:sent_from_bob).subject, messages(:bob_to_john).subject
  end
  
  def test_should_delegate_body_to_sender_message
    assert_equal messages(:sent_from_bob).body, messages(:bob_to_john).body
  end
  
  def test_should_delegate_to_to_sender_message
    assert_equal messages(:sent_from_bob).to, messages(:bob_to_john).to
  end
  
  def test_should_delegate_cc_to_sender_message
    assert_equal messages(:sent_from_bob).cc, messages(:bob_to_john).cc
  end
  
  def test_should_delegate_bcc_to_sender_message
    assert_equal messages(:sent_from_bob).bcc, messages(:bob_to_john).bcc
  end
  
  def test_should_delegate_all_recipients_to_sender_message
    assert_equal messages(:sent_from_bob).all_recipients, messages(:bob_to_john).all_recipients
  end
  
  def test_reference_message_should_be_sender_message
    assert_equal messages(:sent_from_bob), messages(:bob_to_john).reference_message
  end
  
  def test_from_should_be_owner_of_sender_message
    assert_equal users(:bob), messages(:bob_to_john).from
  end
  
  def test_should_view_if_unread
    assert messages(:bob_to_mary).view!
  end
  
  def test_should_not_view_if_read
    assert !messages(:bob_to_john).view!
  end
  
  def test_should_delete_if_unread
    assert messages(:bob_to_mary).delete!
  end
  
  def test_should_delete_if_read
    assert messages(:bob_to_john).delete!
  end
  
  def test_should_destroy_on_delete
    m = messages(:bob_to_john)
    m.delete!
    
    assert !ReceiverMessage.exists?(m.id)
  end
  
  def test_reply_should_generate_clone_of_message
    m = messages(:bob_to_john)
    reply = m.reply
    
    assert_equal m.subject, reply.subject
    assert_equal m.body, reply.body
    assert_equal [m.from], reply.to_receivers
  end
  
  def test_reply_to_all_should_generate_clone_of_message_with_all_recipients_except_self
    m = messages(:bob_to_john)
    reply = m.reply_to_all
    
    assert_equal m.subject, reply.subject
    assert_equal m.body, reply.body
    assert_equal [m.from] + m.to_receivers - [m.owner.messageable], reply.to_receivers
    assert_equal m.cc_receivers, reply.cc_receivers
    assert_equal m.bcc_receivers, reply.bcc_receivers
  end
  
  def test_forward_should_generate_clone_of_message_without_recipients
    m = messages(:bob_to_john)
    forward = m.forward
    
    assert_equal m.subject, forward.subject
    assert_equal m.body, forward.body
    assert forward.to.empty?
    assert forward.cc.empty?
    assert forward.bcc.empty?
  end
end
