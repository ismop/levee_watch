require_relative './config.rb'

require 'resque-scheduler'

class CheckThreatAssessment
  @queue = :job

  def self.perform
    $log.info 'Checking threat assessment'
    $log.info 'TB will implement me and I will check similarity in DAP and reschedule running wf if necessary'
  end
end