require 'httparty'
require 'redis'
require 'dotenv'
require 'librato/metrics'

class WPT
  def initialize(url, key)
    Dotenv.load
    @url = url
    @key = key
    uri = URI.parse(ENV['REDIS_URL'])
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
      url = "http://www.webpagetest.org/runtest.php?url=#{@url}&location=#{ENV['WPT_LOCATION']}&k=#{@key}&f=json&runs=#{ENV['WPT_RUNS']}&fvonly=1&browser_width=1280&browser_height=800"
      request = HTTParty.get(url)
      response = JSON.parse(request.body)
      if response['statusCode'] == 200
        puts "WPT test requested"
        puts "HTML: #{response['data']['userUrl']}"
        puts "JSON: #{response['data']['jsonUrl']}"
        @redis.set('wpt:test_url', response['data']['jsonUrl'])
      end
    end
  end

  def get_latest_result
    latest_test = latest_test_url
    request = HTTParty.get(latest_test)
    JSON.parse(request.body)
  end

  def latest_test_url
    @redis.get('wpt:test_url')
  end

  def log_results
    if active_test? && test_complete?

      wpt = get_latest_result

      Librato::Metrics.authenticate ENV['LIBRATO_USER'], ENV['LIBRATO_TOKEN']

      queue = Librato::Metrics::Queue.new
      source = ENV['LIBRATO_SOURCE']

      unless wpt['data']['median']['firstView'].nil?
        first_view = wpt['data']['median']['firstView']
        queue.add "wpt.first_view.speedindex" => { source: source, value: first_view['SpeedIndex']}
        queue.add "wpt.first_view.timings.ttfb" => { source: source, value: first_view['TTFB']}
        queue.add "wpt.first_view.timings.doc_complete" => { source: source, value: first_view['docTime']}
        queue.add "wpt.first_view.timings.fully_loaded" => { source: source, value: first_view['fullyLoaded']}
        queue.add "wpt.first_view.timings.visually_complete" => { source: source, value: first_view['visualComplete']}
        queue.add "wpt.first_view.timings.visually_complete_85" => { source: source, value: first_view['visualComplete85']}
        queue.add "wpt.first_view.timings.visually_complete_90" => { source: source, value: first_view['visualComplete90']}
        queue.add "wpt.first_view.timings.visually_complete_95" => { source: source, value: first_view['visualComplete95']}
        queue.add "wpt.first_view.timings.visually_complete_99" => { source: source, value: first_view['visualComplete99']}
        queue.add "wpt.first_view.timings.render_start" => { source: source, value: first_view['render']}
        queue.add "wpt.first_view.timings.first_paint" => { source: source, value: first_view['firstPaint']}
        queue.add "wpt.first_view.bytes.in" => { source: source, value: first_view['bytesIn']}
        queue.add "wpt.first_view.bytes.in_doc" => { source: source, value: first_view['bytesInDoc']}
        queue.add "wpt.first_view.bytes.out" => { source: source, value: first_view['bytesOut']}
        queue.add "wpt.first_view.bytes.out_doc" => { source: source, value: first_view['bytesOutDoc']}
        queue.add "wpt.first_view.bytes.gzip" => { source: source, value: first_view['gzip_total']}
        queue.add "wpt.first_view.dom_elements" => { source: source, value: first_view['domElements']}
        queue.add "wpt.first_view.responses.200" => { source: source, value: first_view['responses_200']}
        queue.add "wpt.first_view.responses.404" => { source: source, value: first_view['responses_404']}
        queue.add "wpt.first_view.responses.other" => { source: source, value: first_view['responses_other']}
        queue.add "wpt.first_view.requests.full" => { source: source, value: first_view['requestsFull']}
        queue.add "wpt.first_view.requests.doc" => { source: source, value: first_view['requestsDoc']}
        queue.add "wpt.first_view.images.bytes" => { source: source, value: first_view['breakdown']['image']['bytes']}
        queue.add "wpt.first_view.images.bytes_uncompressed" => { source: source, value: first_view['breakdown']['image']['bytesUncompressed']}
        queue.add "wpt.first_view.images.requests" => { source: source, value: first_view['breakdown']['image']['requests']}
        queue.add "wpt.first_view.html.bytes" => { source: source, value: first_view['breakdown']['html']['bytes']}
        queue.add "wpt.first_view.html.bytes_uncompressed" => { source: source, value: first_view['breakdown']['html']['bytesUncompressed']}
        queue.add "wpt.first_view.html.requests" => { source: source, value: first_view['breakdown']['html']['requests']}
        queue.add "wpt.first_view.js.bytes" => { source: source, value: first_view['breakdown']['js']['bytes']}
        queue.add "wpt.first_view.js.bytes_uncompressed" => { source: source, value: first_view['breakdown']['js']['bytesUncompressed']}
        queue.add "wpt.first_view.js.requests" => { source: source, value: first_view['breakdown']['js']['requests']}
        queue.add "wpt.first_view.css.bytes" => { source: source, value: first_view['breakdown']['css']['bytes']}
        queue.add "wpt.first_view.css.bytes_uncompressed" => { source: source, value: first_view['breakdown']['css']['bytesUncompressed']}
        queue.add "wpt.first_view.css.requests" => { source: source, value: first_view['breakdown']['css']['requests']}
        queue.add "wpt.first_view.flash.bytes" => { source: source, value: first_view['breakdown']['flash']['bytes']}
        queue.add "wpt.first_view.flash.bytes_uncompressed" => { source: source, value: first_view['breakdown']['flash']['bytesUncompressed']}
        queue.add "wpt.first_view.flash.requests" => { source: source, value: first_view['breakdown']['flash']['requests']}
        queue.add "wpt.first_view.fonts.bytes" => { source: source, value: first_view['breakdown']['font']['bytes']}
        queue.add "wpt.first_view.fonts.bytes_uncompressed" => { source: source, value: first_view['breakdown']['font']['bytesUncompressed']}
        queue.add "wpt.first_view.fonts.requests" => { source: source, value: first_view['breakdown']['font']['requests']}
        queue.add "wpt.first_view.other.bytes" => { source: source, value: first_view['breakdown']['other']['bytes']}
        queue.add "wpt.first_view.other.bytes_uncompressed" => { source: source, value: first_view['breakdown']['other']['bytesUncompressed']}
        queue.add "wpt.first_view.other.requests" => { source: source, value: first_view['breakdown']['other']['requests']}
      end


      queue.submit
    end
  end
end
