require_relative './config.rb'

require 'resque-scheduler'

class MonitorWorkflow
  @queue = :job

  def self.perform
    $log.info 'Monitoring workflow'
    $log.info 'MP will implement me'
  end
end