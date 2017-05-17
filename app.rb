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

get '/log/:token/:source' do
  if params[:id].nil? || params[:token].nil? || params[:source].nil?
    body 'Bad Request'
    status 400
  if params[:token] != ENV['TOKEN']
    body 'Unauthorized'
    status 401
  else
    wpt = WPT.new
    wpt.get_test(params[:id], params[:source])
    body 'OK'
    status 200
  end
end
