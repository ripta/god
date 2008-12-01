require File.dirname(__FILE__) + '/helper'

class TestConditionsMysqlConnection < Test::Unit::TestCase
  
  def test_invalid_without_host_or_socket
    c = Conditions::Mysql::Connection.new
    c.username = 'root'
    c.watch = stub(:name => 'mysql_connection')
    assert_equal false, c.valid?
  end
  
  def test_invalid_with_string_as_port
    c = Conditions::Mysql::Connection.new
    c.host = 'localhost'
    c.port = 'invalid'
    c.username = 'root'
    c.watch = stub(:name => 'mysql_connection')
    assert_equal false, c.valid?
  end
  
  def test_invalid_without_username
    c = Conditions::Mysql::Connection.new
    c.host = 'localhost'
    c.watch = stub(:name => 'mysql_connection')
    assert_equal false, c.valid?
  end
  
  def test_requires_supported_mysql_driver
    c = Conditions::Mysql::Connection.new
    c.watch = stub(:name => 'mysql_connection')
  end
  
  def test_works_with_query
    
  end
  
  def test_works_with_ping
    
  end
  
  def test_works_with_stat
    
  end
  
  def test_missing_pid_file_returns_opposite
    [true, false].each do |r|
      c = Conditions::ProcessRunning.new
      c.running = r
    
      c.stubs(:watch).returns(stub(:pid => 99999999, :name => 'foo'))
    
      # no_stdout do
        assert_equal !r, c.test
      # end
    end
  end
  
  def test_not_running_returns_opposite
    [true, false].each do |r|
      c = Conditions::ProcessRunning.new
      c.running = r
    
      File.stubs(:exist?).returns(true)
      c.stubs(:watch).returns(stub(:pid => 123))
      File.stubs(:read).returns('5')
      System::Process.any_instance.stubs(:exists?).returns(false)
    
      assert_equal !r, c.test
    end
  end
  
  def test_running_returns_same
    [true, false].each do |r|
      c = Conditions::ProcessRunning.new
      c.running = r
    
      File.stubs(:exist?).returns(true)
      c.stubs(:watch).returns(stub(:pid => 123))
      File.stubs(:read).returns('5')
      System::Process.any_instance.stubs(:exists?).returns(true)
    
      assert_equal r, c.test
    end
  end
end