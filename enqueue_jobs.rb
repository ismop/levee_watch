require 'resque-scheduler'

require_relative './generate.rb'
require_relative './monitor.rb'

Resque::Scheduler.dynamic = true

def schedule_measurements_generation
  name = 'generate'
  config = {}
  config[:class] = 'Generate'
  config[:every] = ['1m', {first_in: '15s'}]
  config[:persist] = false
  config[:queue] = :job
  Resque.set_schedule(name, config)
end

def schedule_monitoring
  name = 'monitor'
  config = {}
  config[:class] = 'Monitor'
  config[:every] = ['1m', {first_in: '30s'}]
  config[:persist] = false
  config[:queue] = :job
  Resque.set_schedule(name, config)
end

$log.info "Scheduling measurements generation"
schedule_measurements_generation

$log.info "Scheduling monitoring"
schedule_monitoring

$log.info "Levee watch scheduled."