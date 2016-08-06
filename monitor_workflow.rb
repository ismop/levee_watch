require_relative './config.rb'

require 'resque-scheduler'
require 'faraday'
require 'time'

QUERY_RESULT_LIMIT = 10
#allow for one hour of inactivity
MAXIMUM_INACTIVITY_PERIOD = 60*60*60


class MonitorWorkflow
  @queue = :job

  def self.perform
    $log.info 'Checking for recent workflow results'

    conn = Faraday.new(url: DAP_BASE_URL, ssl: {verify: false})
    resp = conn.get(
        '/api/v1/threat_assessment_runs',
        {
            private_token: PRIVATE_TOKEN,
            sort_by: :start_date,
            sort_order: :desc,
            status: :finished,
            limit: QUERY_RESULT_LIMIT
        }
    )
    # $log.info "Response status: #{resp.status}"
    # $log.info "Response body: #{resp.body}"
    threat_assessment_runs = JSON.parse(resp.body)['threat_assessment_runs']
    if not threat_assessment_runs.empty?
      last_threat_assessment_run = threat_assessment_runs.select { |x|
        not x.nil? and not x['end_date'].nil?
      }.sort { |x, y|
        Time.parse(x['end_date']) <=> Time.parse(y['end_date'])
      }.last
      last_end_date = Time.parse(last_threat_assessment_run['start_date'])
      if last_end_date < Time.now - MAXIMUM_INACTIVITY_PERIOD
        $log.warn "No threat assessment run was run since #{last_end_date}!"
      end
    else
      $log.warn 'No threat assessment assessments were run!'
    end

    $log.info 'Done checking for recent workflow results'
  end
end
