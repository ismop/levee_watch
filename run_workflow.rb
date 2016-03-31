require_relative './config.rb'

require 'resque-scheduler'

class RunWorkflow
  @queue = :job

  def self.perform(parameters)
    $log.info "Parameters for running workflow: #{parameters}"
    $log.info 'TB will implement me and I will call HypGen REST API with given parameters'
  end
end