require_relative './config.rb'

require 'resque-scheduler'

class CheckThreatAssessment
  @queue = :job

  def self.perform(params)
    $log.info "Checking threat assessment #{params}"
    conn = Faraday.new(url: DAP_BASE_URL, ssl:{verify: false})
    resp = conn.get(
        "/api/v1/threat_assessments/#{params['threat_assessment_id']}",
        {private_token: PRIVATE_TOKEN}
    )
    $log.info "Response status: #{resp.status}"
    $log.info "Response body: #{resp.body}"
  end
end