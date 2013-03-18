require 'rubygems'
require 'sinatra'
require 'fileutils'
require 'netaddr'
require "csv"
require "json"
require './lib_node.rb'
require './lib_service.rb'
require 'uri'
require 'net/http'

@@service = LibService.new


post '/ath9k-crash/' do
	@@service.process_ath9_crash(params)
end

get '/ath9k-crash' do
  if params[:_method] = 'post'
	@@service.process_ath9_crash(params)
  end
end

get '/upload_key' do
  if(params[:_method] == 'post')
    begin
      @@service.process_key_upload(params)
      status 201 #Created
      '<h1>201 Created</h1>'
    rescue Exception => e
      status 422 #Unprocessable Entity
      "<h1>422 Unprocessable Entity</h1><br />#{e}\n"
    end
  end
end 


post '/' do
  begin
      @@service.process_key_upload(params)
      status 201 #Created
      '<h1>201 Created</h1>'
    rescue Exception => e
      status 422 #Unprocessable Entity
      "<h1>422 Unprocessable Entity</h1><br />#{e}\n"
  end
  
end

get '/graph.png' do
#  content_type 'image/png'
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

