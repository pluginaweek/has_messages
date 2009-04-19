require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class UserByDefaultTest < ActiveSupport::TestCase
  def setup
    @user = create_user
  end
  
  def test_should_not_have_any_messages
    assert @user.messages.empty?
  end
  
  def test_should_not_have_any_unsent_messages
    assert @user.unsent_messages.empty?
  end
  
  def test_should_not_have_any_sent_messages
    assert @user.sent_messages.empty?
  end
  
  def test_should_not_have_any_received_messages
    assert @user.received_messages.empty?
  end
end

class UserTest < ActiveSupport::TestCase
  def setup
    @user = create_user
  end
  
  def test_should_be_able_to_create_new_messages
    message = @user.messages.build
    assert_instance_of Message, message
    assert_equal @user, message.sender
  end
  
  def test_should_be_able_to_send_new_messages
    message = @user.messages.build
    message.to create_user(:login => 'John')
    assert message.deliver
  end
end

class UserWithUnsentMessages < ActiveSupport::TestCase
  def setup
    @user = create_user
    @sent_message = create_message(:sender => @user, :to => create_user(:login => 'you'))
    @sent_message.deliver
    @first_draft = create_message(:sender => @user)
    @second_draft = create_message(:sender => @user)
  end
  
  def test_should_have_unsent_messages
    assert_equal [@first_draft, @second_draft], @user.unsent_messages
  end
  
  def test_should_include_unsent_messages_in_messages
    assert_equal [@sent_message, @first_draft, @second_draft], @user.messages
  end
end

class UserWithSentMessages < ActiveSupport::TestCase
  def setup
    @user = create_user
    @to = create_user(:login => 'you')
    @draft = create_message(:sender => @user)
    
    @first_sent_message = create_message(:sender => @user, :to => @to)
    @first_sent_message.deliver
    
    @second_sent_message = create_message(:sender => @user, :to => @to)
    @second_sent_message.deliver
  end
  
  def test_should_have_sent_messages
    assert_equal [@first_sent_message, @second_sent_message], @user.sent_messages
  end
  
  def test_should_include_sent_messages_in_messages
    assert_equal [@draft, @first_sent_message, @second_sent_message], @user.messages
  end
end

class UserWithReceivedMessages < ActiveSupport::TestCase
  def setup
    @sender = create_user
    @user = create_user(:login => 'me')
    
    @unsent_message = create_message(:sender => @sender, :to => @user)
    
    @first_sent_message = create_message(:sender => @sender, :to => @user)
    @first_sent_message.deliver
    
    @second_sent_message = create_message(:sender => @sender, :to => @user)
    @second_sent_message.deliver
  end
  
  def test_should_have_received_messages
    assert_equal [@first_sent_message, @second_sent_message], @user.received_messages.map(&:message)
  end
end

class UserWithHiddenMessagesTest < ActiveSupport::TestCase
  def setup
    @user = create_user
    @friend = create_user(:login => 'you')
    
    hidden_unsent_message = create_message(:sender => @user)
    hidden_unsent_message.hide
    @unsent_message = create_message(:sender => @user)
    
    hidden_sent_message = create_message(:sender => @user, :to => @friend)
    hidden_sent_message.deliver
    hidden_sent_message.hide
    @sent_message = create_message(:sender => @user, :to => @friend)
    @sent_message.deliver
    
    hidden_received_message = create_message(:sender => @friend, :to => @user)
    hidden_received_message.deliver
    hidden_received_message.recipients.first.hide
    @received_message = create_message(:sender => @friend, :to => @user)
    @received_message.deliver
  end
  
  def test_should_not_include_hidden_messages_in_messages
    assert_equal [@unsent_message, @sent_message], @user.messages
  end
  
  def test_should_not_include_hidden_messages_in_unsent_messages
    assert_equal [@unsent_message], @user.unsent_messages
  end
  
  def test_should_not_include_hidden_messages_in_sent_messages
    assert_equal [@sent_message], @user.sent_messages
  end
  
  def test_should_not_include_hidden_messages_in_received_messages
    assert_equal [@received_message], @user.received_messages.map(&:message)
  end
end
