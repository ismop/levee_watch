require_relative './config.rb'

require 'faraday'
require 'json'

class MeasurementFetcher

  def initialize
    @conn = Faraday.new(url: DAP_BASE_URL, ssl:{verify: false})
  end

  def get(ctx_id, device_aggregation_custom_id, from, to)
    da_resp = @conn.get(
      "/api/v1/device_aggregations?custom_id=#{device_aggregation_custom_id}",
      { private_token: PRIVATE_TOKEN }
    ).body
    da = JSON.parse(da_resp)
    da_id = da['device_aggregations'].first['id']
    devices_resp = @conn.get(
      "/api/v1/devices?device_aggregation_id=#{da_id}",
      { private_token: PRIVATE_TOKEN }
    ).body
    devices = JSON.parse(devices_resp)['devices']
    parameter_ids = devices.collect { |d| d['parameter_ids'] }.flatten
    parameters_resp = @conn.get(
      "/api/v1/parameters?id=#{parameter_ids.join(',')}",
      { private_token: PRIVATE_TOKEN }
    ).body
    parameters = JSON.parse(parameters_resp)['parameters']
    temp_param_id = parameters.select do |p|
      p['measurement_type_name'] == 'Temperatura'
    end.first['id']

    press_param_id = parameters.select do |p|
      p['measurement_type_name'] == 'Ciśnienie porowe'
    end.first['id']

    tt_resp = @conn.get(
      "/api/v1/timelines?parameter_id=#{temp_param_id}&context_id=#{ctx_id}",
      { private_token: PRIVATE_TOKEN }
    ).body
    temp_tl_id = JSON.parse(tt_resp)['timelines'].first['id']

    pt_resp = @conn.get(
      "/api/v1/timelines?parameter_id=#{press_param_id}&context_id=#{ctx_id}",
      { private_token: PRIVATE_TOKEN }
    ).body
    press_tl_id = JSON.parse(pt_resp)['timelines'].first['id']

    temp_measurements_resp = @conn.get(
        "/api/v1/measurements?timeline_id=#{temp_tl_id}"\
        "&time_from=#{from}&time_to=#{to}",
        { private_token: PRIVATE_TOKEN }
    ).body
    temp_measurements = JSON.parse(temp_measurements_resp)['measurements']

    press_measurements_resp = @conn.get(
        "/api/v1/measurements?timeline_id=#{press_tl_id}"\
        "&time_from=#{from}&time_to=#{to}",
        { private_token: PRIVATE_TOKEN }
    ).body
    press_measurements = JSON.parse(press_measurements_resp)['measurements']

    puts "Temperature measurements:\n #{temp_measurements}"
    puts "Pressure measurements:\n #{press_measurements}"
  end

  def device_aggregations_for_profile(profile_id)
    da_resp = @conn.get(
      "/api/v1/device_aggregations?profile_id=#{profile_id}",
      { private_token: PRIVATE_TOKEN }
    ).body
    das = JSON.parse(da_resp)['device_aggregations']
    puts "Device aggregations:\n#{das}"
  end

end



fetcher = MeasurementFetcher.new
time_from='2015-10-03 9:40:40 +0200'
time_to='2015-10-03 9:45:40 +0200'
#fetcher.get(1, 'UT7', time_from, time_to)
fetcher.device_aggregations_for_profile(8)