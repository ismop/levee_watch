require_relative './config.rb'

require 'resque-scheduler'

class MonitorWorkflow
  @queue = :job

  def self.perform
    puts "Monitoring workflow"
    $log.info 'Monitoring workflow'
    $log.info 'MP will implement me'
  end
end