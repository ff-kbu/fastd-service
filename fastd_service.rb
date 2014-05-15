require 'rubygems'
require 'sinatra/base'
require 'fileutils'
require 'netaddr'
require "csv"
require "json"
require './lib_node.rb'
require './lib_service.rb'
require 'uri'
require 'net/http'
require "sinatra/multi_route"
require 'sinatra/base'


@@service = LibService.new
class FastdService < Sinatra::Base
  set :method_override, true 
  register Sinatra::MultiRoute
  configure :production, :development do
    enable :logging
  end

  route :post,  ['/ath9k-crash/', '/fastd-upload/ath9-crash'] do
	@@service.process_ath9_crash(params)
  end

  route  :get,['/upload_key'], :post, ['/', '/fastd-upload/upload_key','/upload_key'] do
    begin
      @@service.process_key_upload(params,logger)
      status 200 #Created
      '<h1>200 Created</h1>'
    rescue Exception => e
      logger.error "Error while uploading key: #{$!} -- #{e.backtrace.join("\n\t")}"
      status 422 #Unprocessable Entity
      "<h1>422 Unprocessable Entity</h1><br />#{e}\n"
    end
  end

  route :get, ['/graph.png', '/fastd-upload/graph.png'] do
    @@service.render_graph()
  
    result = ""
    system "/usr/local/bin/batctl_vd_suid | fdp -T png > /tmp/graph.png"
    send_file '/tmp/graph.png'
  end

  get '/' do
<<EOD
<h1>Upload fastd-key</h1>

<form method="post" enctype="multipart/form-data">
  <label for="nodeid">Node-ID:</label> <br />
  <input type="text" size="13" name="nodeid">
  <p />
  <label for="key">Key:</label> <br />
  <input type="text" size="65" name="key">
  <p />
  <input name="commit" type="submit" value="Submit" />
  </p>
   
</form>
EOD
  end
end
