require File.dirname(__FILE__) + '/../test_helper'

class MessageTest < Test::Unit::TestCase
  class TestMessage < Message
    def to
      [1, 2, 3].collect {|r| TestRecipient.new(r)}
    end
    
    def cc
      [4, 5, 6].collect {|r| TestRecipient.new(r)}
    end
    
    def bcc
      [7, 8, 9].collect {|r| TestRecipient.new(r)}
    end
    
    def all_recipients
      to + cc + bcc
    end
  end
  
  class TestRecipient
    attr_reader :messageable
    
    def initialize(messageable)
      @messageable = messageable
    end
  end
  
  fixtures :users, :messages
  
  def test_should_require_owner_id
    assert_invalid messages(:sent_from_bob), :owner_id, nil
  end
  
  def test_should_require_state_id
    assert_invalid messages(:sent_from_bob), :state_id, nil
  end
  
  def test_to_receivers_should_return_messageables
    message = TestMessage.new
    assert_equal [1, 2, 3], message.to_receivers
  end
  
  def test_cc_receivers_should_return_messageables
    message = TestMessage.new
    assert_equal [4, 5, 6], message.cc_receivers
  end
  
  def test_bcc_receivers_should_return_messageables
    message = TestMessage.new
    assert_equal [7, 8, 9], message.bcc_receivers
  end
  
  def test_all_receivers_should_combine_to_cc_and_bcc
    message = TestMessage.new
    assert_equal [1, 2, 3, 4, 5, 6, 7, 8, 9], message.all_receivers
  end
  
  def test_number_of_recipients_should_combine_sizes_of_to_cc_and_bcc
    message = TestMessage.new
    assert_equal 9, message.number_of_recipients
  end
end
