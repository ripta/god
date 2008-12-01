
module God::Conditions::Mysql
  
  class Connection < PollCondition
    
    attr_accessor :host, :password, :port, :socket, :ssl, :username
    attr_accessor :timeout, :times
    
    attr_reader :connection
    
    def initialize
      super
      self.port = 3306
      self.times = [1, 1]
      self.timeout = 60.seconds
      @reconnect = true
      @timeline = nil
    end
    
    def prepare
      self.times = [self.times, self.times] if self.times.is_a?(Numeric)
      @timeline = Timeline.new(self.times.last)
    end
    
    def reset
      @timeline.clear
    end
    
    def settings(options = { })
      options.each_pair do |key, value|
        self.send("#{key}=", value)
      end
    end
    
    def perform_query(sql)
      if @connection.respond_to?(:async_query)
        @connection.async_query(sql)
      elsif @connection.respond_to?(:query)
        @connection.query(sql)
      elsif @connection.respond_to?(:execute)
        @connection.execute(sql)
      else
        nil
      end
    end
    
    def reconnect
      @connection.close rescue nil
      @connection = Mysql.init
      @connection.ssl_set(@ssl[:key], @ssl[:cert], @ssl[:ca], @ssl[:ca_path], @ssl[:cipher]) if @ssl
      @connection.real_connect(@host, @username, @password, nil, @port, @socket)
    end
    
    def test
      result = begin
        self.reconnect if @reconnect
        test_routine
      rescue Mysql::Error
        if @reconnect
          nil
        else
          @reconnect = true
          retry
        end
      end
      @timeline << result
      fail_count = @timeline.select { |pt| pt.nil? }.size
      if fail_count <= self.times.first
        self.info = "MySQL connection OK"
        @reconnect = false
      end
      !@reconnect
    end
    
    def test_routine
      if @connection.respond_to?(:stat)
        @connection.stat
        @connection.respond_to?(:errno) && @connection.errno.zero?
      elsif @connection.respond_to?(:ping)
        @connection.ping
      elsif query_result = self.perform_query('SELECT 1')
        !!query_result
      else
        self.info = "Current MySQL driver is unsupported; driver must support one of stat, ping, async_query, query, or execute"
        false
      end
    end
    
    def valid?
      valid = true
      valid &= complain("Attribute 'username' must be specified", self) if self.username.nil?
      valid &= complain("Attribute 'port' must be an integer", self) unless self.port.is_a?(Integer)
      if self.host.nil? && self.socket.nil?
        valid &= complain("Either attributes 'host' and 'port', or 'socket' must be specified", self)
      end
      unless self.ssl.nil?
        valid &= complain("SSL settings must be a hash", self) unless self.ssl.is_a?(Hash)
      end
      valid
    end
    
  end
  
end
