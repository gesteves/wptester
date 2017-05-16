require 'sinatra'
require_relative 'wpt'

configure do
  # Disable output buffering
  $stdout.sync = true
end

get '/' do
  body 'Hello world'
  status '200'
end

get '/log/:source' do
  if params[:id].nil? || params[:source].nil?
    body 'Bad Request'
    status 400
  else
    wpt = WPT.new
    wpt.get_test(params[:id], params[:source])
    body 'OK'
    status 200
  end
end
