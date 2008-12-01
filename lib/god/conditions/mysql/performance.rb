
module God::Conditions::Mysql
  
  class Replication < Connection
    
    attr_accessor :innodb_buffer_pool_wait, :query_cache_hitrate, :table_cache_hitrate, :table_lock_contention, :temporary_tables, :thread_cache_hitrate
    
    def status_of(thing)
      result_set = self.perform_query("SHOW STATUS LIKE '#{thing}'")
      return nil unless result_set
      status = result_set.fetch_hash
      return nil unless status
      status['Value']
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