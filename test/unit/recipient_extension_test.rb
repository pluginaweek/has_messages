require File.dirname(__FILE__) + '/../test_helper'

class RecipientExtensionTest < Test::Unit::TestCase
  fixtures :users, :messages, :message_recipients
  
  def setup
    @message = messages(:unsent_from_bob)
  end
  
  def test_should_input_receiver
    @message.to << users(:bob)
    assert_equal [users(:john), users(:bob)], @message.to_receivers
  end
  
  def test_should_input_message_recipients
    @message.to << MessageRecipient.new(:receiver => users(:bob), :kind => 'to')
    assert_equal [users(:john), users(:bob)], @message.to_receivers
  end
  
  def test_should_push_receiver
    @message.to.push(users(:bob))
    assert_equal [users(:john), users(:bob)], @message.to_receivers
  end
  
  def test_should_push_message_recipients
    @message.to.push(MessageRecipient.new(:receiver => users(:bob), :kind => 'to'))
    assert_equal [users(:john), users(:bob)], @message.to_receivers
  end
  
  def test_should_concat_receiver
    @message.to.concat([users(:bob)])
    assert_equal [users(:john), users(:bob)], @message.to_receivers
  end
  
  def test_should_concat_message_recipients
    @message.to.concat([MessageRecipient.new(:receiver => users(:bob), :kind => 'to')])
    assert_equal [users(:john), users(:bob)], @message.to_receivers
  end
  
  def test_should_delete_receiver
    @message.to.delete(users(:john))
    assert_equal [], @message.to_receivers
  end
  
  def test_should_delete_message_recipients
    @message.to.delete(@message.to.first)
    assert_equal [], @message.to
  end
  
  def test_should_should_replace_receiver
    @message.to.replace([users(:bob)])
    assert_equal [users(:bob)], @message.to_receivers
  end
  
  def test_should_replace_message_recipients
    @message.to.replace([])
    assert_equal [], @message.to_receivers
  end
  
  def test_should_set_kind_for_to_recipients
    @message.to << users(:bob)
    assert_equal 'to', @message.to.last.kind
  end
  
  def test_should_set_kind_for_cc_recipients
    @message.cc << users(:bob)
    assert_equal 'cc', @message.cc.last.kind
  end
  
  def test_should_set_kind_for_bcc_recipients
    @message.bcc << users(:bob)
    assert_equal 'bcc', @message.bcc.last.kind
  end
end
