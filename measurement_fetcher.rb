require_relative './config.rb'

require 'faraday'
require 'json'
require 'date'

class MeasurementFetcher

  def initialize
    @conn = Faraday.new(url: DAP_BASE_URL, ssl:{verify: false})
  end

  def get(ctx_id, profile_id, from, to, working_dir = '/tmp/')
    device_aggregations = device_aggregations_for_profile(profile_id)
    device_aggregations.each do |da|
      devices = devices(da['device_ids'])
      parameter_ids = devices.collect { |d| d['parameter_ids'] }.flatten
      next if parameter_ids.size == 0
      parameters = parameters(parameter_ids)

      temp_param = select_param_of_type(parameters, 'Temperatura')
      next unless temp_param
      temp_param_id = temp_param['id']

      press_param = select_param_of_type(
          parameters,
          'Ciśnienie porowe'
      )
      next unless press_param
      press_param_id = press_param['id']

      temp_tl = timeline(ctx_id, temp_param_id)
      next unless temp_tl
      temp_tl_id = temp_tl['id']

      press_tl = timeline(ctx_id, press_param_id)
      next unless press_tl
      press_tl_id = press_tl['id']

      temp_measurements = temperature_measurements(temp_tl_id, from, to)

      press_measurements = pressure_measurements(press_tl_id, from, to)

      next if (temp_measurements.size == 0 || press_measurements.size == 0)
      next if temp_measurements.size != press_measurements.size

      working_dir << '/' unless working_dir.end_with? '/'
      file_name = "#{working_dir}#{da['custom_id']}.csv"
      puts "Writing file #{file_name}"
      File.open(file_name, 'w') do |file|
        temp_measurements.each_index do |i|
          file.write(
            "0,0,0,0,#{temp_measurements[i]['value']},"\
            "#{press_measurements[i]['value']},"\
            "#{timestamp(temp_measurements[i]['timestamp'])},"\
            "#{da['custom_id']}\n"
          )
        end
      end
    end
  end

  def timestamp(date_str)
    DateTime.parse(date_str).to_time.to_i
  end

  def devices(ids)
    devices_resp = @conn.get(
        "/api/v1/devices?device_aggregation_id=#{ids.join(',')}",
        { private_token: private_token }
    ).body
    JSON.parse(devices_resp)['devices']
  end

  def select_param_of_type(parameters, param_type)
    parameters.select do |p|
      p['measurement_type_name'] == param_type
    end.first
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
    JSON.parse(da_resp)['device_aggregations']
  end

  private
  def private_token
    ENV['PRIVATE_TOKEN'] || PRIVATE_TOKEN
  end

end

fetcher = MeasurementFetcher.new
context_id = 1
time_from = '2015-10-03 9:40:40 +0200'
time_to = '2015-10-03 9:45:40 +0200'

# ids of profiles in DAP production
#[9, 10, 3, 6, 7, 1, 2, 4, 5, 8].each do |profile_id|
# only for profile_id 9 there are some data
[9].each do |profile_id|
  puts "---Getting measurements for profile with id #{profile_id}---"
  fetcher.get(context_id, profile_id, time_from, time_to)
  puts '============================================================'
end