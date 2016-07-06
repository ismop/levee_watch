require 'resque-scheduler'

require_relative './config.rb'
require_relative './helpers.rb'

Resque::Scheduler.dynamic = true

def run_workflow
  config = wf_job_conf('testing levee watch', [1,2], 0)
  Resque.set_schedule 'run_workflow', config
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
$log.info 'Scheduling workflow monitoring'
monitor_workflow
$log.info 'Scheduled workflow monitoring'
$log.info 'Work done.'
