require File.dirname(__FILE__) + '/../test_helper'

class HasMessagesTest < Test::Unit::TestCase
  fixtures :users, :messages, :message_recipients
  
  def test_should_generate_received_association
    assert_equal [messages(:sent_from_bob), messages(:sent_from_mary)], users(:john).received_messages.map(&:message)
  end
  
  def test_should_generate_received_association_for_custom_names
    assert_equal [messages(:sent_from_bob), messages(:sent_from_mary)], users(:john).received_notes.map(&:message)
  end
  
  def test_should_generate_unsent_association
    assert_equal [messages(:unsent_from_bob)], users(:bob).unsent_messages
  end
  
  def test_should_generate_unsent_association_for_custom_names
    assert_equal [messages(:unsent_from_bob)], users(:bob).unsent_notes
  end
  
  def test_should_generate_sent_association
    assert_equal [messages(:sent_from_bob), messages(:queued_from_bob)], users(:bob).sent_messages
  end
  
  def test_should_generate_sent_association_for_custom_names
    assert_equal [messages(:sent_from_bob), messages(:queued_from_bob)], users(:bob).sent_notes
  end
  
  def test_should_generate_inbox
    assert_instance_of MessageBox, users(:bob).message_box
  end
  
  def test_should_generate_inbox_for_custom_names
    assert_instance_of MessageBox, users(:bob).note_box
  end
  
  def test_inbox_should_contain_received_messages
    u = users(:bob)
    assert_equal u.received_messages, u.message_box.inbox
  end
  
  def test_inbox_should_contain_unsent_messages
    u = users(:bob)
    assert_equal u.unsent_messages, u.message_box.unsent
  end
  
  def test_inbox_should_contain_sent_messages
    u = users(:bob)
    assert_equal u.sent_messages, u.message_box.sent
  end
end
