require 'httparty'
require 'librato/metrics'

class WPT
  def self.request_test
    location = ENV['LOCATION'] || 'Dulles:Chrome'
    runs = ENV['RUNS'] || 5
    width = ENV['WIDTH'] || 1280
    height = ENV['HEIGHT'] || 800
    pingback_url = "https://#{ENV['HEROKU_APP_NAME']}.herokuapp.com/log/#{ENV['TOKEN']}/#{ENV['SOURCE']}"
    url = "http://www.webpagetest.org/runtest.php?url=#{ENV['SITE_URL']}&location=#{location}&k=#{ENV['WPT_API_KEY']}&f=json&runs=#{runs}&fvonly=1&browser_width=#{width}&browser_height=#{height}&pingback=#{pingback_url}"
    request = HTTParty.get(url)
    response = JSON.parse(request.body)
    if response['statusCode'] == 200
      puts "WPT test requested"
      puts "HTML: #{response['data']['userUrl']}"
      puts "JSON: #{response['data']['jsonUrl']}"
    end
  end

  def self.get_test(test_id, source)
    request = HTTParty.get("http://www.webpagetest.org/jsonResult.php?test=#{test_id}")
    if request.code == 200
      json = JSON.parse(request.body)
      self.log_test_results(json, source)
    end
  end

  def self.log_test_results(json, source)
    Librato::Metrics.authenticate ENV['LIBRATO_USER'], ENV['LIBRATO_TOKEN']

    queue = Librato::Metrics::Queue.new
    unless json['data']['median']['firstView'].nil?
      first_view = json['data']['median']['firstView']
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
    Librato::Metrics.annotate :wpt, json['data']['id'], source: source, description: json['data']['from'].gsub(/<\/?b>/, ''), links: [{ label: 'View test results', href: json['data']['summary'], rel: 'wpt' }]
  end
end
