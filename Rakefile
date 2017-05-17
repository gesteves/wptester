require 'dotenv/tasks'
require_relative 'wpt'

namespace :wpt do
  desc 'Requests a new WebPageTest test'
  task :request => [:dotenv] do
    begin
      if ENV['SITE_URL'].nil?
        puts "You need to specify the `SITE_URL` to be tested"
      elsif ENV['PINGBACK_URL'].nil?
        puts "You need to specify the `PINGBACK_URL`"
      elsif ENV['WPT_API_KEY'].nil?
        puts "You need a `WPT_API_KEY`"
      else
        WPT.request_test
      end
    rescue => e
      abort "Failed to request WPT test: #{e}"
    end
  end
end
