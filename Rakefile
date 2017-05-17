require 'dotenv/tasks'
require_relative 'wpt'

namespace :wpt do
  desc 'Requests a new WebPageTest test'
  task :request => [:dotenv] do
    begin
      if ENV['SITE_URL'].nil?
        puts "You need to specify the `SITE_URL` to be tested"
      elsif ENV['SOURCE'].nil?
        puts "You need to enter a Librato `SOURCE`"
      elsif ENV['HEROKU_APP_NAME'].nil?
        puts "Make sure dyno metadata is enabled: `heroku labs:enable runtime-dyno-metadata`"
      else
        WPT.request_test
      end
    rescue => e
      abort "Failed to request WPT test: #{e}"
    end
  end
end
