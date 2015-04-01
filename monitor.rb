require_relative './config.rb'

require 'faraday'

class Monitor

  @queue = :job

  def self.perform
    conn = Faraday.new(url: DAP_BASE_URL, ssl:{verify: false})
    measurements = conn.get('/api/v1/measurements', {private_token: PRIVATE_TOKEN, sensor_id: SENSOR_ID}).body

    $log.info "Measurements: #{measurements}"
  end

end
