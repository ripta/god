
module God::Conditions::Mysql
  
  class Replication < Connection
    
    attr_accessor :check_slave_io, :check_slave_sql, :max_lag
    
    def initialize
      super
      self.check_slave_io = true
      self.check_slave_sql = true
      self.max_lag = 30.seconds
    end
    
    def test_routine
      result_set = self.perform_query('SHOW SLAVE STATUS')
      unless result_set
        self.info = "Cannot contact MySQL server"
        return false
      end
      slave_status = result_set.fetch_hash
      unless slave_status
        self.info = "MySQL server is not a slave"
        return true
      end
      self.info = [ ]
      if slave_status['Seconds_Behind_Master'].to_i > self.max_lag
        self.info << "Slave is lagging #{slave_status['Seconds_Behind_Master']} seconds behind the master"
      end
      if self.check_slave_io && status['Slave_IO_Running'] != 'Yes'
        self.info << "Slave IO thread is stopped"
      end
      if self.check_slave_sql && status['Slave_SQL_Running'] != 'Yes'
        self.info << "Slave SQL thread is stopped"
      end
      self.info.empty?
    end
    
    def valid?
      valid = super
      valid &= complain("At least either one of 'check_slave_io' or 'check_slave_sql' must be true", self) unless self.check_slave_io || self.check_slave_sql
      valid &= complain("Maximum allowed lag must be a non-negative number", self) if self.max_lag < 0
      valid
    end
    
  end
  
end