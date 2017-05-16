require 'sinatra'
require_relative 'wpt'

configure do
  # Disable output buffering
  $stdout.sync = true
end

get '/log/:token' do
  if params[:id].nil? || params[:token] != ENV['TOKEN']
    body 'Bad Request'
    status 400
  else
    wpt = WPT.new
    wpt.get_test(params[:id])
    body 'OK'
    status 200
  end
end
