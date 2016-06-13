require_relative './config.rb'

require 'resque-scheduler'
require 'faraday'

class RunWorkflow
  @queue = :job

  def self.perform(parameters)
    $log.info "Schedulling workflow run with parameters #{parameters}"
    parameters['hypgen_params']['threat_assessment']['start_date'] = (Time.now - ANALYSIS_PERIOD * 3600).to_s
    parameters['hypgen_params']['threat_assessment']['end_date'] = Time.now.to_s
    conn = Faraday.new(url: HYPGEN_URL, ssl:{verify: false})
    conn.basic_auth(HYPGEN_USERNAME, HYPGEN_PASSWORD)
    resp = conn.post do |req|
      req.url '/api/threat_assessments'
      req.headers['Content-Type'] = 'application/json'
      req.body = parameters['hypgen_params'].to_json
    end

    $log.info "Response status: #{resp.status}"
    $log.info "Response body: #{resp.body}"
    threat_assessment_id = JSON.parse(resp.body)['threat_assessment']['id']
    $log.info "Scheduling CheckThreatAssessment for id #{threat_assessment_id}"
    schedule_check_threat_assessment(threat_assessment_id)
  end

  def self.schedule_check_threat_assessment(threat_assessment_id)
    Resque.enqueue_in_with_queue(
              :job,
              CHECK_THREAT_ASSESSMENT_DELAY * 60,
              CheckThreatAssessment,
        threat_assessment_id: threat_assessment_id
    )
  end
end