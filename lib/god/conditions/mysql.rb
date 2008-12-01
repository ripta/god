
begin
  require "mysqlplus"
rescue LoadError
  require "mysql"
end

module God
  module Conditions
    module Mysql
      
      # pass
      
    end
  end
end

require "god/conditions/mysql/connection"

require "god/conditions/mysql/performance"
require "god/conditions/mysql/replication"
