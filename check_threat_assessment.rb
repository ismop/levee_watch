require_relative './config.rb'
require_relative './helpers.rb'

require 'resque-scheduler'
require 'faraday'

Resque::Scheduler.dynamic = true

class CheckThreatAssessment
  @queue = :job

  def self.perform(params)
    $log.info "Checking threat assessment #{params}"
    conn = Faraday.new(url: DAP_BASE_URL, ssl:{verify: false})
    resp = conn.get(
        "/api/v1/threat_assessments/#{params['threat_assessment_id']}",
        {private_token: PRIVATE_TOKEN}
    )
    results = results(resp)
    wf_schedule = Resque.all_schedules['run_workflow']
    wf_schedule['every'] =
        run_wf_job_every_setting(assess_threat_level(results))
    Resque.set_schedule 'run_workflow', wf_schedule
    $log.info "Rescheduled running WF (every #{wf_schedule['every']})"
  end

  private
  def self.results(dap_resp)
    JSON.parse(dap_resp.body)['threat_assessment']['results']
  end

  # Returns:
  # - 0 if there is no result with similarity > 0.5
  # - 1 otherwise
  def self.assess_threat_level(results)
    count = results.count {|r| r['similarity']> SIMILARITY_THRESHOLD}
    count > 0 ? 1 : 0
  end
end