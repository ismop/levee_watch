require 'resque-scheduler'

require_relative './config.rb'

Resque::Scheduler.dynamic = true

def run_workflow
  name = 'run_workflow'
  config = {
      class: 'RunWorkflow',
      every: [WORKFLOW_RUN_PERIOD, {first_in: FIRST_WORKFLOW_RUN_DELAY}],
      persist: false,
      args: {a1: 'A', a2: 'B'},
      queue: :job
  }
  Resque.set_schedule name, config
end

def check_threat_assessment
  name = 'check_threat_assessment'
  config = {
      class: 'CheckThreatAssessment',
      every: [
          CHECK_THREAT_ASSESSMENT_PERIOD,
          {first_in: FIRST_CHECK_THREAT_ASSESSMENT_DELAY}
      ],
      persist: false,
      queue: :job
  }
  Resque.set_schedule name, config
end

def monitor_workflow
  name = 'monitor_workflow'
  config = {
      class: 'MonitorWorkflow',
      every: [
          WORKFLOW_MONITORING_PERIOD,
          {first_in: FIRST_WORKFLOW_MONITORING_DELAY}
      ],
      persist: false,
      queue: :job
  }
  Resque.set_schedule name, config
end

$log.info 'Starting Levee watch'
$log.info 'Scheduling Hypgen workflow'
run_workflow
$log.info 'Workflow scheduled'
check_threat_assessment
$log.info 'Checking threat assessment scheduled'
$log.info 'Scheduling workflow monitoring'
monitor_workflow
$log.info 'Scheduled workflow monitoring'
$log.info 'Work done.'
