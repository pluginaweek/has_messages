require File.dirname(__FILE__) + '/../test_helper'

class ReceivedMessageTest < Test::Unit::TestCase
  fixtures :users, :messages, :message_recipients
  
  def setup
    @message = ReceivedMessage.new(message_recipients(:bob_to_john))
  end
  
  def test_should_delegate_sent_at_to_message
    assert_equal messages(:sent_from_bob).sent_at, @message.sent_at
  end
  
  def test_should_delegate_sender_to_message
    assert_equal messages(:sent_from_bob).sender, @message.sender
  end
  
  def test_should_delegate_sender_id_to_message
    assert_equal messages(:sent_from_bob).sender_id, @message.sender_id
  end
  
  def test_should_delegate_sender_type_to_message
    assert_equal messages(:sent_from_bob).sender_type, @message.sender_type
  end
  
  def test_should_delegate_subject_to_message
    assert_equal messages(:sent_from_bob).subject, @message.subject
  end
  
  def test_should_delegate_body_to_message
    assert_equal messages(:sent_from_bob).body, @message.body
  end
  
  def test_should_delegate_to_message
    assert_equal messages(:sent_from_bob).to, @message.to
  end
  
  def test_should_delegate_to_receivers_to_message
    assert_equal messages(:sent_from_bob).to_receivers, @message.to_receivers
  end
  
  def test_should_delegate_cc_to_message
    assert_equal messages(:sent_from_bob).cc, @message.cc
  end
  
  def test_should_delegate_cc_receivers_to_message
    assert_equal messages(:sent_from_bob).cc_receivers, @message.cc_receivers
  end
  
  def test_should_delegate_bcc_to_message
    assert_equal messages(:sent_from_bob).bcc, @message.bcc
  end
  
  def test_should_delegate_bcc_receivers_to_message
    assert_equal messages(:sent_from_bob).bcc_receivers, @message.bcc_receivers
  end
  
  def test_should_delegate_all_recipients_to_message
    assert_equal messages(:sent_from_bob).all_recipients, @message.all_recipients
  end
  
  def test_should_delegate_all_receivers_to_message
    assert_equal messages(:sent_from_bob).all_receivers, @message.all_receivers
  end
  
  def test_should_access_recipient_receiver
    assert_equal message_recipients(:bob_to_john).receiver, @message.receiver
  end
  
  def test_should_access_recipient_message
    assert_equal message_recipients(:bob_to_john).message, @message.message
  end
  
  def test_should_access_recipients_events
    message = ReceivedMessage.new(message_recipients(:bob_to_mary))
    assert message.view!
    assert message_recipients(:bob_to_mary).read?
  end
  
  def test_should_access_recipient_states
    assert @message.read?
    assert message_recipients(:bob_to_john).read?
  end
  
  def test_reply_should_generate_clone_of_message
    reply = @message.reply
    
    assert_equal @message.subject, reply.subject
    assert_equal @message.body, reply.body
    assert_equal [@message.sender], reply.to_receivers
  end
  
  def test_reply_to_all_should_generate_clone_of_message_with_all_recipients_except_self
    reply = @message.reply_to_all
    
    assert_equal @message.subject, reply.subject
    assert_equal @message.body, reply.body
    assert_equal [@message.sender] + @message.to_receivers - [@message.receiver], reply.to_receivers
    assert_equal @message.cc_receivers, reply.cc_receivers
    assert_equal @message.bcc_receivers, reply.bcc_receivers
  end
  
  def test_forward_should_generate_clone_of_message_without_recipients
    forward = @message.forward
    
    assert_equal @message.subject, forward.subject
    assert_equal @message.body, forward.body
    assert forward.to.empty?
    assert forward.cc.empty?
    assert forward.bcc.empty?
  end
end
