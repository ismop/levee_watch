require_relative './config.rb'

require 'faraday'
require 'json'

class MeasurementFetcher

  def initialize
    @conn = Faraday.new(url: DAP_BASE_URL, ssl:{verify: false})
  end

  def devices(ids)
    devices_resp = @conn.get(
        "/api/v1/devices?device_aggregation_id=#{da_id}",
        { private_token: private_token }
    ).body
    JSON.parse(devices_resp)['devices']
  end

  def get(ctx_id, profile_id, from, to)
    device_aggregations = device_aggregations_for_profile(profile_id)
    device_aggregations.each do |da|
      devices = devices(da['device_ids'])
      parameter_ids = devices.collect { |d| d['parameter_ids'] }.flatten
      parameters = parameters(parameter_ids)

      temp_param_id = parameters.select do |p|
        p['measurement_type_name'] == 'Temperatura'
      end.first['id']

      press_param_id = parameters.select do |p|
        p['measurement_type_name'] == 'Ciśnienie porowe'
      end.first['id']

      temp_tl_id = timeline(ctx_id, temp_param_id)['id']

      press_tl_id = timeline(ctx_id, press_param_id)['id']

      temp_measurements = temperature_measurements(temp_tl_id, from, to)

      press_measurements = pressure_measurements(press_tl_id, from, to)

      puts "Temperature measurements:\n #{temp_measurements}"
      puts "Pressure measurements:\n #{press_measurements}"
    end
  end

  def parameters(parameter_ids)
    parameters_resp = @conn.get(
        "/api/v1/parameters?id=#{parameter_ids.join(',')}",
        {private_token: private_token}
    ).body
    JSON.parse(parameters_resp)['parameters']
  end

  def timeline(ctx_id, parameter_id)
    pt_resp = @conn.get(
        "/api/v1/timelines?parameter_id=#{parameter_id}&context_id=#{ctx_id}",
        {private_token: private_token}
    ).body
    JSON.parse(pt_resp)['timelines'].first
  end

  def temperature_measurements(timeline_id, from, to)
    temp_measurements_resp = @conn.get(
        "/api/v1/measurements?timeline_id=#{timeline_id}"\
        "&time_from=#{from}&time_to=#{to}",
        {private_token: private_token}
    ).body
    JSON.parse(temp_measurements_resp)['measurements']
  end

  def pressure_measurements(timeline_id, from, to)
    press_measurements_resp = @conn.get(
        "/api/v1/measurements?timeline_id=#{timeline_id}"\
        "&time_from=#{from}&time_to=#{to}",
        {private_token: private_token}
    ).body
    JSON.parse(press_measurements_resp)['measurements']
  end

  def device_aggregations_for_profile(profile_id)
    da_resp = @conn.get(
      "/api/v1/device_aggregations?profile_id=#{profile_id}",
      { private_token: private_token }
    ).body
    das = JSON.parse(da_resp)['device_aggregations']
    puts "Device aggregations:\n#{das}"
  end

  private
  def private_token
    ENV['PRIVATE_TOKEN'] || PRIVATE_TOKEN
  end

end



fetcher = MeasurementFetcher.new
#time_from = '2015-10-03 9:40:40 +0200'
#time_to = '2015-10-03 9:45:40 +0200'
#fetcher.get(1, 'UT7', time_from, time_to)
fetcher.device_aggregations_for_profile(8)