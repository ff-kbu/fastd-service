require 'yaml'
class LibService
  
  @@conf =  @@collectd_conf ||= YAML::load_file("./conf.yml")
  
  
  # Service (singleton) used by sinatra
  def process_ath9_crash(params)
    url = @@conf['register_url']
    crash_dump_path = @@conf['crash_dump_path']
  	nodeid = params[:nodeid]
  	tstmp = Time.at params[:tstmp].to_i
  	dmesg = params[:dmesg]
  	now = Time.now.to_i

  	File.open("#{crash_dump_path}/#{now}.log","w") do |f|
  		f.puts "Node: #{nodeid} - at: #{tstmp}\n"
  		f.puts dmesg
  	end
  	Net::HTTP.post_form URI("#{url}/watchdog_bites"), 
      		{ "node_id" => nodeid, "dmesg" => dmesg, "tstmp" => params[:tstmp], 'submission_stmp' => now }
  end
  
  def process_key_upload(params,logger)
    fastd_dir = @@conf['fastd_peer_dir']
    reload_cmd = @@conf['fastd_reload_cmd']
    url = @@conf['register_url']
    
    nodeid = params[:nodeid]
    key = params[:key]
    fw_version = params[:fw_version]
    
    #Service calls can be error-prone, check everything
    raise "No key given" if key.nil?
    raise "No nodeid given" if nodeid.nil?
    raise "Invalid node-ID #{nodeid}" unless nodeid.match(/^[0-9a-f]{12}$/i)
    raise "Invalid key #{key}" unless key.match(/^[0-9a-f]+$/i)

    file_name = "#{fastd_dir}/#{nodeid}_#{key}"
    return if File.exists?(file_name)

    
    #Submit key
    resp = nil
    begin
      resp = Net::HTTP.post_form URI("#{url}/fastds"), { "mac" => nodeid, "key" => key, "fw_version" => fw_version }
    rescue Exception => e
      logger.warn "Unable to query register - #{$!} -- #{e.backtrace.join("\n\t")}"
      # Register is inavailble, ignore
    end
    
    # In principle, it might should be possible for register to reject certain key (eg in times of attacks / faults)
    # if so, the respone will be HTTP-Net::HTTPServiceUnavailable
    if resp && resp.code == 423 #HTTP-Locked
      raise "Denied by policy"
    end
    # Ignore other errors - Register-Problems should not harm fastd-Services

    #We'll be save, then
    File.open(file_name, 'w') do |f| 
      f.write("key \"#{key}\";\n") 
    end
    system reload_cmd    
  end
end
