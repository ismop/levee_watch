require_relative './config.rb'

require 'fileutils'
require 'faraday'
require 'json'
require 'date'

class MeasurementFetcher

  def initialize
    @conn = Faraday.new(url: DAP_BASE_URL, ssl:{verify: false})
  end

  def get(ctx_id, scenario_id, profile_id, from, to, file_name_prefix = '', working_dir = '/tmp/')
    devices = devices_for_profile(profile_id)
    devices.each do |dev|
      parameter_ids = dev['parameter_ids']
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

      temp_tl = timeline(ctx_id, scenario_id, temp_param_id)
      next unless temp_tl
      temp_tl_id = temp_tl['id']

      press_tl = timeline(ctx_id, scenario_id, press_param_id)
      next unless press_tl
      press_tl_id = press_tl['id']

      temp_measurements = temperature_measurements(temp_tl_id, from, to)
      next unless temp_measurements

      press_measurements = pressure_measurements(press_tl_id, from, to)
      next unless press_measurements

      next if (temp_measurements.size == 0 || press_measurements.size == 0)
      next if temp_measurements.size != press_measurements.size

      working_dir << '/' unless working_dir.end_with? '/'

      scenario = !scenario_id.nil?

      write_measurements(
          dev, press_measurements, temp_measurements,
          file_name_prefix, working_dir, scenario
      )
    end
  end

  private

  def write_measurements(dev, p_measurements, t_measurements, fname_prefix, working_dir, scenario)
    unless Dir.exist?(working_dir)
      FileUtils.mkpath(working_dir)
    end
    file_name = "#{working_dir}#{fname_prefix}#{dev['custom_id']}.csv"
    puts "Writing file #{file_name}"
    File.open(file_name, 'w') do |file|
      t_measurements.each_index do |i|
        # data in scenario and measurement files have columns in different order
        row = "0,0,0,"\
            "#{"0," unless scenario}"\
            "#{t_measurements[i]['value']},"\
            "#{p_measurements[i]['value']},"\
            "#{timestamp(t_measurements[i]['timestamp'])},"\
             "#{"0," if scenario}"\
            "#{dev['custom_id']}\n"
        file.write(row)
      end
    end
  end

  def timestamp(date_str)
    DateTime.parse(date_str).to_time.to_i
  end

  def devices_for_profile(profile_id)
    devices_resp = @conn.get(
        "/api/v1/devices?profile_id=#{profile_id}",
        { private_token: private_token }
    ).body
    JSON.parse(devices_resp)['devices']
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

  def timeline(ctx_id, scenario_id, parameter_id)
    pt_resp = @conn.get(
        "/api/v1/timelines?parameter_id=#{parameter_id}"\
        "&context_id=#{ctx_id}"\
        "#{"&scenario_id=#{scenario_id}" if scenario_id}",
        {private_token: private_token}
    ).body
    JSON.parse(pt_resp)['timelines'].first
  end

  def temperature_measurements(timeline_id, from, to)
    temp_measurements_resp = @conn.get(
        "/api/v1/measurements?timeline_id=#{timeline_id}"\
        "#{"&time_from=#{from}" if from}"\
        "#{"&time_to=#{to}" if to}",
        {private_token: private_token}
    ).body
    JSON.parse(temp_measurements_resp)['measurements']
  end

  def pressure_measurements(timeline_id, from, to)
    press_measurements_resp = @conn.get(
        "/api/v1/measurements?timeline_id=#{timeline_id}"\
        "#{"&time_from=#{from}" if from}"\
        "#{"&time_to=#{to}" if to}",
        {private_token: private_token}
    ).body
    JSON.parse(press_measurements_resp)['measurements']
  end

  def private_token
    ENV['PRIVATE_TOKEN'] || PRIVATE_TOKEN
  end

end


fetcher = MeasurementFetcher.new
# context 1 Obwałowanie eksperymentalne - sensory Budokop
# context 2 Scenariusze

puts '----- Getting scenarios data -----'
context_id = 2
scenario_id = 26 # for now we have 25 scenarios, check their ids in DAP

# nil from and to means all available data
time_from = nil # nil # scenario starts at '1970-01-01 0:00:00 +0200'
time_to = nil # '1970-01-01 8:00:00 +0200'

# time_from = '1970-01-01 0:00:00 +0200'
# time_to = '1970-01-01 8:00:00 +0200'

# scenarios are not available for all profiles
# there is some data available for profile with id = 2
[1, 2, 3, 4, 5, 6, 7, 8, 9, 10].each do |profile_id|
  puts "---Getting scenario data for profile with id #{profile_id}---"
  fetcher.get(context_id, scenario_id, profile_id, time_from, time_to,
              "scenario_#{scenario_id}_", '/tmp/scenarios')
  puts '============================================================'
end

puts '----- Got available scenarios data -----'

puts '----- Getting measurements data -----'
context_id = 1
scenario_id = nil

time_from = '2015-10-01 0:00:00 +0200'
time_to = '2015-10-01 8:00:00 +0200'

[1, 2, 3, 4, 5, 6, 7, 8, 9, 10].each do |profile_id|
  puts "---Getting measurements for profile with id #{profile_id}---"
  fetcher.get(context_id, scenario_id, profile_id, time_from, time_to,
              nil, '/tmp/measurements')
  puts '============================================================'
end

puts '----- Got available measurements data -----'

puts '===== FINISHED ====='