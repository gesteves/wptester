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
        source = "#{ENV['LIBRATO_SOURCE']}.first_view"
        queue.add "wpt.speedindex" => { source: source, value: first_view['SpeedIndex']}
        queue.add "wpt.timings.ttfb" => { source: source, value: first_view['TTFB']}
        queue.add "wpt.timings.doc_complete" => { source: source, value: first_view['docTime']}
        queue.add "wpt.timings.fully_loaded" => { source: source, value: first_view['fullyLoaded']}
        queue.add "wpt.timings.visually_complete" => { source: source, value: first_view['visualComplete']}
        queue.add "wpt.timings.render_start" => { source: source, value: first_view['render']}
        queue.add "wpt.bytes.in" => { source: source, value: first_view['bytesIn']}
        queue.add "wpt.bytes.in_doc" => { source: source, value: first_view['bytesInDoc']}
        queue.add "wpt.dom_elements" => { source: source, value: first_view['domElements']}
        queue.add "wpt.responses.200" => { source: source, value: first_view['responses_200']}
        queue.add "wpt.responses.404" => { source: source, value: first_view['responses_404']}
        queue.add "wpt.responses.other" => { source: source, value: first_view['responses_other']}
      end

      unless wpt['data']['median']['repeatView'].nil?
        repeat_view = wpt['data']['median']['repeatView']
        source = "#{ENV['LIBRATO_SOURCE']}.repeat_view"
        queue.add "wpt.speedindex" => { source: source, value: repeat_view['SpeedIndex']}
        queue.add "wpt.timings.ttfb" => { source: source, value: repeat_view['TTFB']}
        queue.add "wpt.timings.doc_complete" => { source: source, value: repeat_view['docTime']}
        queue.add "wpt.timings.fully_loaded" => { source: source, value: repeat_view['fullyLoaded']}
        queue.add "wpt.timings.visually_complete" => { source: source, value: repeat_view['visualComplete']}
        queue.add "wpt.timings.render_start" => { source: source, value: repeat_view['render']}
        queue.add "wpt.bytes.in" => { source: source, value: repeat_view['bytesIn']}
        queue.add "wpt.bytes.in_doc" => { source: source, value: repeat_view['bytesInDoc']}
        queue.add "wpt.dom_elements" => { source: source, value: repeat_view['domElements']}
        queue.add "wpt.responses.200" => { source: source, value: repeat_view['responses_200']}
        queue.add "wpt.responses.404" => { source: source, value: repeat_view['responses_404']}
        queue.add "wpt.responses.other" => { source: source, value: repeat_view['responses_other']}
      end

      queue.submit
    end
  end
end
