require_relative './config.rb'

require 'redis'
require 'json'
require 'date'

require 'resque-scheduler'

class Generate

  @queue = :job

  def self.perform
    generator = Random.new
    if File.exist? GENERATOR_TMP_FILENAME
      last_measurement = IO.read(GENERATOR_TMP_FILENAME).to_f.modulo MAX_MEASUREMENT_VALUE
      measurement = last_measurement + generator.rand(-1.0..1.0) * MAX_MEASUREMENT_DELTA
    else
      measurement = generator.rand(1.0) * MAX_MEASUREMENT_VALUE
    end
    IO.write(GENERATOR_TMP_FILENAME, measurement)
    redis = Redis.new(host: REDIS_HOST)
    measurement_event = {
      sensorId: SENSOR_ID,
      monitoringStationId: MONITORING_STATION_ID,
      value: measurement,
      timestamp: DateTime.now.strftime('%Q')
    }
    redis.publish REDIS_CHANNEL_NAME, measurement_event.to_json
    $log.info "Generated measurement: #{measurement_event}"
  end

end
