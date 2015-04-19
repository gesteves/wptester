require 'dotenv/tasks'
require_relative 'wpt'

namespace :wpt do
  desc 'Requests a new WebPageTest test'
  task :request => [:dotenv] do
    begin
      puts '== Requesting new WPT test'
      start_time = Time.now
      wpt = WPT.new(ENV['SITE_URL'], ENV['WPT_API_KEY'])
      wpt.request_test
      puts "Completed in #{Time.now - start_time} seconds"
    rescue => e
      abort "Failed to request WPT test: #{e}"
    end
  end

  desc 'Logs results of last WebPageTest test'
  task :log => [:dotenv] do
    begin
      puts '== Logging latest WPT test'
      start_time = Time.now
      wpt = WPT.new(ENV['SITE_URL'], ENV['WPT_API_KEY'])
      wpt.log_results
      puts "Completed in #{Time.now - start_time} seconds"
    rescue => e
      abort "Failed to log WPT test: #{e}"
    end
  end
end

