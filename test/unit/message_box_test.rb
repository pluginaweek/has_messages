require File.dirname(__FILE__) + '/../test_helper'

class MessageBoxTest < Test::Unit::TestCase
  def test_should_store_inbox
    box = MessageBox.new([1], [2], [3])
    assert_equal [1], box.inbox
  end
  
  def test_should_store_unsent
    box = MessageBox.new([1], [2], [3])
    assert_equal [2], box.unsent
  end
  
  def test_should_store_sent
    box = MessageBox.new([1], [2], [3])
    assert_equal [3], box.sent
  end
end
