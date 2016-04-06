require_relative './config.rb'

require 'resque-scheduler'
require 'faraday'

class RunWorkflow
  @queue = :job

  def self.perform(parameters)
    $log.info "Parameters for running workflow: #{parameters}"
    $log.info 'TB will implement me and I will call HypGen REST API with given parameters'

    # curl -k -H "Content-Type: application/json" \
    # -d '{"threat_assessment":{"name": "exp name", "section_ids":[1,2], "start_date": "2014-11-21T09:45:42.025Z", "end_date": "2014-11-22T09:45:42.025Z"}}' \
    # -u username:password http://hypgen.moc.ismop.edu.pl/api/threat_assessments

    hypgen_params = {
        threat_assessment:
            {
                name: 'testing levee watch',
                section_ids:[1,2],
                start_date: '2014-11-21T09:45:42.025Z',
                'end_date': '2014-11-22T09:45:42.025Z'
            }
    }
    conn = Faraday.new(url: HYPGEN_URL, ssl:{verify: false})
    conn.basic_auth(HYPGEN_USERNAME, HYPGEN_PASSWORD)
    resp = conn.post do |req|
      req.url '/api/threat_assessments'
      req.headers['Content-Type'] = 'application/json'
      req.body = hypgen_params.to_json
    end

    $log.info "Response status: #{resp.status}\nResponse body: #{resp.body}"
  end
end