require 'sinatra'
require_relative 'wpt'
require 'dotenv'

configure do
  # Disable output buffering
  $stdout.sync = true
  Dotenv.load
end

get '/' do
  body 'Hello world'
  status '200'
end

get '/log/:token/:source' do
  if params[:id].nil? || params[:token].nil? || params[:source].nil?
    body 'Bad Request'
    status 400
  elsif params[:token] != ENV['TOKEN']
    body 'Unauthorized'
    status 401
  else
    WPT.get_test(params[:id], params[:source])
    body 'OK'
    status 200
  end
end
