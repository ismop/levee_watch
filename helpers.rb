require_relative './config.rb'

def run_wf_job_every_setting(threat_level)
  [
    if threat_level > 0
      WF_RUN_PERIOD_EMERGENCY_MODE
    else
      WF_RUN_PERIOD_NORMAL_MODE
    end,
    {first_in: FIRST_WORKFLOW_RUN_DELAY}
  ]
end

def wf_job_conf(wf_name, section_ids, threat_level)
  hypgen_params = {
    threat_assessment:
      {
        name: wf_name,
        section_ids: section_ids
      }
  }
  {
    class: 'RunWorkflow',
    every: run_wf_job_every_setting(threat_level),
    persist: false,
    args: {hypgen_params: hypgen_params},
    queue: :job
  }
end