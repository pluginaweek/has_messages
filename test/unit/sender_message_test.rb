require File.dirname(__FILE__) + '/../test_helper'

class SenderMessageTest < Test::Unit::TestCase
  fixtures :users, :messages, :message_recipients
  
  def test_should_require_owner_type
    assert_invalid messages(:sent_from_bob), :owner_type, nil
  end
  
  def test_owner_should_be_messageable_model
    assert_equal users(:bob), messages(:sent_from_bob).owner
    assert_equal users(:mary), messages(:sent_from_mary).owner
  end
  
  def test_to_should_only_contain_to_recipients
    assert_equal [message_recipients(:bob_to_john)], messages(:sent_from_bob).to
  end
  
  def test_cc_should_only_contain_cc_recipients
    assert_equal [message_recipients(:bob_to_mary)], messages(:sent_from_bob).cc
  end
  
  def test_bcc_should_only_contain_bcc_recipients
    assert_equal [], messages(:sent_from_bob).bcc
    assert_equal [message_recipients(:mary_to_john)], messages(:sent_from_mary).bcc
  end
  
  def test_all_recipients_should_contain_to_cc_and_bcc_recipients
    assert_equal [message_recipients(:bob_to_john), message_recipients(:bob_to_mary)], messages(:sent_from_bob).all_recipients
    assert_equal [message_recipients(:mary_to_john)], messages(:sent_from_mary).all_recipients
  end
  
  def test_sent_messages_should_be_empty_if_not_sent
    assert_equal [], messages(:unsent_from_bob).sent_messages
  end
  
  def test_sent_messages_should_include_to_cc_and_bcc_messages_if_sent
    assert_equal [messages(:bob_to_john), messages(:bob_to_mary)], messages(:sent_from_bob).sent_messages
  end
  
  def test_initial_state_should_be_unsent
    m = SenderMessage.new
    assert_equal :unsent, m.initial_state.to_sym
    
    m.owner = users(:bob)
    assert m.save!
    assert_equal :unsent, m.state.to_sym
  end
  
  def test_should_queue_if_unsent
    m = messages(:unsent_from_bob)
    m.to << users(:john)
    assert m.queue!
    assert m.sent?
    m.all_recipients.each do |recipient|
      assert recipient.unsent?
    end
  end
  
  def test_should_not_queue_if_there_are_no_recipients
    m = SenderMessage.new(:owner => users(:bob), :subject => 'test', :body => 'test')
    assert m.all_recipients.empty?
    assert m.save!
    assert !m.queue!
  end
  
  def test_should_not_queue_if_sent
    m = messages(:sent_from_bob)
    assert m.sent?
    assert !m.queue!
  end
  
  def test_should_not_queue_if_deleted
    m = messages(:unsent_from_bob)
    assert m.delete!
    assert m.deleted?
    assert !m.queue!
  end
  
  def test_should_deliver_if_unsent
    m = messages(:unsent_from_bob)
    assert m.deliver!
  end
  
  def test_should_not_deliver_if_there_are_no_recipients
    m = SenderMessage.new(:owner => users(:bob), :subject => 'test', :body => 'test')
    assert m.all_recipients.empty?
    assert m.save!
    assert !m.deliver!
  end
  
  def test_should_not_deliver_if_sent
    m = messages(:sent_from_bob)
    assert !m.deliver!
  end
  
  def test_should_not_deliver_if_deleted
    m = messages(:unsent_from_bob)
    assert m.delete!
    assert !m.deliver!
  end
  
  def test_should_delete_from_unsent
    m = messages(:unsent_from_bob)
    assert m.delete!
    assert m.deleted?
  end
  
  def test_should_delete_from_sent
    m = messages(:sent_from_bob)
    assert m.delete!
    assert m.deleted?
  end
  
  def test_should_not_delete_from_deleted
    m = messages(:sent_from_bob)
    m.delete!
    assert !m.delete!
  end
  
  def test_should_create_messages_for_each_recipient_when_sent
    m = messages(:unsent_from_bob)
    m.deliver!
    assert_equal 2, m.sent_messages.size
  end
  
  def test_should_not_create_messages_for_each_recipient_when_queued
    m = messages(:unsent_from_bob)
    m.queue!
    assert_equal 0, m.sent_messages.size
  end
  
  def test_should_not_destroy_if_sent_messages_still_exist
    m = messages(:sent_from_bob)
    m.delete!
    assert m.deleted?
    assert SenderMessage.exists?(m.id)
  end
  
  def test_should_destroy_if_not_sent_messages_still_exist
    messages(:bob_to_john).destroy
    messages(:bob_to_mary).destroy
    
    m = messages(:sent_from_bob)
    assert m.sent_messages.empty?
    m.delete!
    assert m.deleted?
    assert !SenderMessage.exists?(m.id)
  end
  
  def test_reply_should_generate_clone_of_message
    m = messages(:sent_from_bob)
    reply = m.reply
    
    assert_equal m.subject, reply.subject
    assert_equal m.body, reply.body
    assert_equal m.to_receivers, reply.to_receivers
    assert reply.cc.empty?
    assert reply.bcc.empty?
  end
  
  def test_reply_to_all_should_generate_clone_of_message_with_all_recipients
    m = messages(:sent_from_bob)
    reply = m.reply_to_all
    
    assert_equal m.subject, reply.subject
    assert_equal m.body, reply.body
    assert_equal m.to_receivers, reply.to_receivers
    assert_equal m.cc_receivers, reply.cc_receivers
    assert_equal m.bcc_receivers, reply.bcc_receivers
  end
  
  def test_forward_should_generate_clone_of_message_without_recipients
    m = messages(:sent_from_bob)
    forward = m.forward
    
    assert_equal m.subject, forward.subject
    assert_equal m.body, forward.body
    assert forward.to.empty?
    assert forward.cc.empty?
    assert forward.bcc.empty?
  end
end
