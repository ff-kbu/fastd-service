#require 'rubygems'
#require 'sinatra'
require './fastd_service.rb'

log = File.new("logs/sinatra.log", "a")
STDERR.reopen(log)

run FastdService
