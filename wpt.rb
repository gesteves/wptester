require 'httparty'
require 'redis'
require 'dotenv'
require 'librato/metrics'

class WPT
  def initialize(url, key)
    Dotenv.load
    @url = url
    @key = key
    uri = URI.parse(ENV['REDISCLOUD_URL'])
    @redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
  end

  def test_complete?
    latest_test = @redis.get('wpt:test_url')
    request = HTTParty.get(latest_test)
    response = JSON.parse(request.body)
    puts "WPT status #{response['statusCode']}: #{response['statusText']}"
    @redis.del('wpt:test_url') if response['statusCode'] == 400
    response['statusCode'] == 200 && response['statusText'].downcase == 'test complete'
  end

  def active_test?
    @redis.exists('wpt:test_url')
  end

  def request_test
    if active_test? && !test_complete?
      puts 'WPT request skipped; last test not complete'
    else
      url = "http://www.webpagetest.org/runtest.php?url=#{@url}&location=#{ENV['WPT_LOCATION']}&k=#{@key}&f=json&runs=#{ENV['WPT_RUNS']}"
      request = HTTParty.get(url)
      response = JSON.parse(request.body)
      if response['statusCode'] == 200
        puts "WPT test requested: #{response['data']['userUrl']}"
        @redis.set('wpt:test_url', response['data']['jsonUrl'])
      end
    end
  end

  def get_latest_result
    latest_test = @redis.get('wpt:test_url')
    request = HTTParty.get(latest_test)
    JSON.parse(request.body)
  end

  def log_results
    if active_test? && test_complete?

      wpt = get_latest_result

      Librato::Metrics.authenticate ENV['LIBRATO_USER'], ENV['LIBRATO_TOKEN']

      queue = Librato::Metrics::Queue.new

      unless wpt['data']['median']['firstView'].nil?
        first_view = wpt['data']['median']['firstView']
        queue.add "#{ENV['PREFIX']}.wpt.first_view.speedindex" => first_view['SpeedIndex']
        queue.add "#{ENV['PREFIX']}.wpt.first_view.timings.ttfb" => first_view['TTFB']
        queue.add "#{ENV['PREFIX']}.wpt.first_view.timings.doc_complete" => first_view['docTime']
        queue.add "#{ENV['PREFIX']}.wpt.first_view.timings.fully_loaded" => first_view['fullyLoaded']
        queue.add "#{ENV['PREFIX']}.wpt.first_view.timings.visually_complete" => first_view['visualComplete']
        queue.add "#{ENV['PREFIX']}.wpt.first_view.timings.render_start" => first_view['render']
        queue.add "#{ENV['PREFIX']}.wpt.first_view.bytes.in" => first_view['bytesIn']
        queue.add "#{ENV['PREFIX']}.wpt.first_view.bytes.in_doc" => first_view['bytesInDoc']
        queue.add "#{ENV['PREFIX']}.wpt.first_view.dom_elements" => first_view['domElements']
        queue.add "#{ENV['PREFIX']}.wpt.first_view.responses.200" => first_view['responses_200']
        queue.add "#{ENV['PREFIX']}.wpt.first_view.responses.404" => first_view['responses_404']
        queue.add "#{ENV['PREFIX']}.wpt.first_view.responses.other" => first_view['responses_other']
      end

      unless wpt['data']['median']['repeatView'].nil?
        repeat_view = wpt['data']['median']['repeatView']
        queue.add "#{ENV['PREFIX']}.wpt.repeat_view.speedindex" => repeat_view['SpeedIndex']
        queue.add "#{ENV['PREFIX']}.wpt.repeat_view.timings.ttfb" => repeat_view['TTFB']
        queue.add "#{ENV['PREFIX']}.wpt.repeat_view.timings.doc_complete" => repeat_view['docTime']
        queue.add "#{ENV['PREFIX']}.wpt.repeat_view.timings.fully_loaded" => repeat_view['fullyLoaded']
        queue.add "#{ENV['PREFIX']}.wpt.repeat_view.timings.visually_complete" => repeat_view['visualComplete']
        queue.add "#{ENV['PREFIX']}.wpt.repeat_view.timings.render_start" => repeat_view['render']
        queue.add "#{ENV['PREFIX']}.wpt.repeat_view.bytes.in" => repeat_view['bytesIn']
        queue.add "#{ENV['PREFIX']}.wpt.repeat_view.bytes.in_doc" => repeat_view['bytesInDoc']
        queue.add "#{ENV['PREFIX']}.wpt.repeat_view.dom_elements" => repeat_view['domElements']
        queue.add "#{ENV['PREFIX']}.wpt.repeat_view.responses.200" => repeat_view['responses_200']
        queue.add "#{ENV['PREFIX']}.wpt.repeat_view.responses.404" => repeat_view['responses_404']
        queue.add "#{ENV['PREFIX']}.wpt.repeat_view.responses.other" => repeat_view['responses_other']
      end

      queue.submit
    end
  end
end
