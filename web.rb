# coding: utf-8
require 'sinatra'
require 'RMagick'
require 'uri'
require 'net/http'
require 'json'
require 'dalli'
require 'set'
require 'rack/contrib'
require 'punycode'

use Rack::Deflater
use Rack::StaticCache, :urls => ['/favicon.ico', '/robots.txt', '/css', '/js', '/img'], :root => 'public'
IMAGE_NUM_MAX = 15

def selectFont(fontFamily)
    case fontFamily
    when 'ipag'
        return fontFamily
    when 'ipagp'
        return fontFamily
    when 'ipam'
        return fontFamily
    when 'ipamp'
        return fontFamily
    else
        return 'ipag'
    end
end

def editImage(command_hash, image)
    begin
        if command_hash.key?('rectangle') then
            args = command_hash['rectangle']
            if args.instance_of?(Hash) then
                args = [args]
            end
            for arg in args do
                draw = Magick::Draw.new
                draw.fill = arg.fetch('color', '#FFFFFF')
                draw.rectangle(arg.fetch('x1', 0).to_i, arg.fetch('y1', 0).to_i, arg.fetch('x2', 0).to_i, arg.fetch('y2', 0).to_i)
                draw.draw(image)
            end
        end

        if command_hash.key?('annotate') then
            args = command_hash['annotate']
            if args.instance_of?(Hash) then
                args = [args]
            end
            for arg in args do
                if arg.key?('text') then
                    x = arg.fetch('x', 0).to_i
                    y = arg.fetch('y', 0).to_i
                    fontSize = arg.fetch('size', 30).to_i
                    fontFamily = selectFont(arg.fetch('font', 'ipag'))
                    lines = arg['text'].split
                    j = 1
                    for line in lines do
                        draw = Magick::Draw.new
                        draw.annotate(image, image.columns, image.rows, x, y + fontSize * j, line) do
                            self.font = "fonts/#{fontFamily}.ttf"
                            self.fill = arg.fetch('color', '#000000')
                            self.pointsize = fontSize
                        end
                        j += 1
                    end
                end
            end
        end

        if command_hash.key?('tategaki') then
            args = command_hash['tategaki']
            if args.instance_of?(Hash) then
                args = [args]
            end
            for arg in args do
                if arg.key?('text') then
                    x = arg.fetch('x', 0).to_i
                    y = arg.fetch('y', 0).to_i
                    fontSize = arg.fetch('size', 30).to_i
                    fontFamily = selectFont(arg.fetch('font', 'ipag'))
                    lines = arg['text'].split
                    j = 0
                    for line in lines do
                        draw = Magick::Draw.new
                        i = 0
                        while i < line.size
                            draw.annotate(image, image.columns, image.rows, x - fontSize * j, y + fontSize * (i + 1), line[i]) do
                                self.font = "fonts/#{fontFamily}.ttf"
                                self.align = Magick::CenterAlign
                                self.fill = arg.fetch('color', '#000000')
                                self.pointsize = fontSize
                            end
                            i += 1
                        end
                        j += 1
                    end
                end
            end
        end
    rescue Exception => e
        logger.error e.to_s
        halt 500, 'image edit error'
    end
end

def saveRecentUrl(command, url)
    begin
        dc = Dalli::Client.new(
            ENV['MEMCACHIER_SERVERS'],
            {:username => ENV['MEMCACHIER_USERNAME'], :password => ENV['MEMCACHIER_PASSWORD']}
        )
        image_set = dc.get('set')
        unless image_set
            image_set = Set.new
        end
        if image_set.length > IMAGE_NUM_MAX
            tmp = image_set.to_a.shift
            tmp.push("/image/v1/#{URI.encode(command, /[^\w\d]/)}/#{URI.encode(url, /[^\w\d]/)}")
            image_set = Set.new(tmp)
        else
            image_set.add("/image/v1/#{URI.encode(command, /[^\w\d]/)}/#{URI.encode(url, /[^\w\d]/)}")
        end
        dc.set('set', image_set)
    rescue Exception => e
        logger.warn e.to_s
    end
end

get '/' do
    begin
        dc = Dalli::Client.new(
            ENV['MEMCACHIER_SERVERS'],
            {:username => ENV['MEMCACHIER_USERNAME'], :password => ENV['MEMCACHIER_PASSWORD']}
        )
        image_set = dc.get('set')
    rescue Exception => e
        logger.warn e.to_s
    end
    unless image_set
        image_set = Set.new
    end

    expires 60, :public, :must_revalidate
    erb :index, :locals => {:images => image_set}
end

get '/readme' do
    expires 100, :public, :must_revalidate
    erb :readme
end

get '/make' do
    expires 100, :public, :must_revalidate
    erb :make
end

get '/proxy' do
    unless params.has_key?('url')
        halt 400, 'bad parameter'
    end

    begin
        params['url'].sub!(/:\/\/([^\/]+)/) {|match|
            words = $1.split('.')
            words.each_with_index {|word, i|
                next if word =~ /[0-9a-z\-]/
                words[i] = "xn--#{Punycode.encode(word)}"
            }
            "://#{words.join('.')}"
        }
        is_html = false
        if /^https?:\/\/tiqav\.com\/([a-zA-Z0-9]+)$/ =~ params['url']
            uri = URI.parse("http://api.tiqav.com/images/#{Regexp.last_match(-1)}.json")
            res = Net::HTTP.start(uri.host, uri.port) {|http|
                http.get(uri.path)
            }
            tiqav_hash = JSON.parse(res.body)
            uri = URI.parse('http://img.tiqav.com/' + tiqav_hash['id'] + '.' + tiqav_hash['ext'])
        else
            uri = URI.parse(params['url'])
            if /^https?:\/\/gazoreply\.jp\/\d+\/[a-zA-Z\.0-9]+$/ =~ params['url']
                is_html = true
            else
                if /^(.+)\.jpg\.to$/ =~ uri.host
                    is_html = true
                end
            end
        end
        res = Net::HTTP.start(uri.host, uri.port) {|http|
            http.get(uri.path)
        }
        if is_html then
            if /<img.+src="([^"]+)".+>/ =~ res.body
                uri = URI.parse(Regexp.last_match(1))
                res = Net::HTTP.start(uri.host, uri.port) {|http|
                    http.get(uri.path)
                }
            end
        end
    rescue Exception => e
        logger.error e.to_s
        halt 500, 'url error'
    end

    content_type res.content_type
    #同ドメインになるのでつけなくてもいいけど
    headers['Access-Control-Allow-Origin'] = '*'
    res.body
end

get '/image/v1' do
    command = params['command']
    url = params['url']
    unless url then
        halt 400, 'no url parameter'
    end

    command_hash = nil
    if command then
        begin
            command_hash = JSON.parse(command)
        rescue Exception => e
            logger.error e.to_s
            halt 400, 'command error'
        end
    end

    begin
        unless /^http/ =~ url
            url = 'http://' + url
        else
            unless url.index('://') then
                url.sub!(':/', '://')
            end
        end
        url.sub!(/:\/\/([^\/]+)/) {|match|
            words = $1.split('.')
            words.each_with_index {|word, i|
                next if word =~ /[0-9a-z\-]/
                words[i] = "xn--#{Punycode.encode(word)}"
            }
            "://#{words.join('.')}"
        }
        uri = URI.parse(url)
        is_html = false
        if /^https?:\/\/gazoreply\.jp\/\d+\/[a-zA-Z\.0-9]+$/ =~ url
            is_html = true
        else
            if /^(.+)\.jpg\.to$/ =~ uri.host
                is_html = true
            end
        end
        res = Net::HTTP.start(uri.host, uri.port) {|http|
            http.get(uri.path)
        }
        if is_html then
            if /<img.+src="([^"]+)".+>/ =~ res.body
                uri = URI.parse(Regexp.last_match(1))
                res = Net::HTTP.start(uri.host, uri.port) {|http|
                    http.get(uri.path)
                }
            end
        end
        image = Magick::Image.from_blob(res.body).shift
    rescue Exception => e
        logger.info url
        logger.error e.to_s
        halt 500, 'url error'
    end

    editImage(command_hash, image)
    if command_hash then
        saveRecentUrl(command, url)
    end

    headers['Access-Control-Allow-Origin'] = '*'
    content_type res.content_type
    expires 259200, :public
    image.to_blob
end

get '/image/v1/*/*' do |command, url|
    begin
        command_hash = JSON.parse(command)
    rescue Exception => e
        logger.error e.to_s
        halt 400, 'command error'
    end

    begin
        unless /^http/ =~ url
            url = 'http://' + url
        else
            unless url.index('://') then
                url.sub!(':/', '://')
            end
        end
        url.sub!(/:\/\/([^\/]+)/) {|match|
            words = $1.split('.')
            words.each_with_index {|word, i|
                next if word =~ /[0-9a-z\-]/
                words[i] = "xn--#{Punycode.encode(word)}"
            }
            "://#{words.join('.')}"
        }
        uri = URI.parse(url)
        is_html = false
        if /^https?:\/\/gazoreply\.jp\/\d+\/[a-zA-Z\.0-9]+$/ =~ url
            is_html = true
        else
            if /^(.+)\.jpg\.to$/ =~ uri.host
                is_html = true
            end
        end
        res = Net::HTTP.start(uri.host, uri.port) {|http|
            http.get(uri.path)
        }
        if is_html then
            if /<img.+src="([^"]+)".+>/ =~ res.body
                uri = URI.parse(Regexp.last_match(1))
                res = Net::HTTP.start(uri.host, uri.port) {|http|
                    http.get(uri.path)
                }
            end
        end
        image = Magick::Image.from_blob(res.body).shift
    rescue Exception => e
        logger.info url
        logger.error e.to_s
        halt 500, 'url error'
    end

    editImage(command_hash, image)
    saveRecentUrl(command, url)

    headers['Access-Control-Allow-Origin'] = '*'
    content_type res.content_type
    expires 259200, :public
    image.to_blob
end

get '/tiqav/v1/*/*' do |command, id|
    begin
        command_hash = JSON.parse(command)
    rescue Exception => e
        logger.error e.to_s
        halt 400, 'command error'
    end

    begin
        unless id.index('.') then
            uri = URI.parse("http://api.tiqav.com/images/#{id}.json")
            res = Net::HTTP.start(uri.host, uri.port) {|http|
                http.get(uri.path)
            }
            tiqav_hash = JSON.parse(res.body)
            uri = URI.parse('http://img.tiqav.com/' + tiqav_hash['id'] + '.' + tiqav_hash['ext'])
        else
            uri = URI.parse("http://img.tiqav.com/#{id}")
        end
        res = Net::HTTP.start(uri.host, uri.port) {|http|
            http.get(uri.path)
        }
        image = Magick::Image.from_blob(res.body).shift
    rescue Exception => e
        logger.error e.to_s
        halt 500, 'url error'
    end

    editImage(command_hash, image)
    saveRecentUrl(command, uri.to_s)

    headers['Access-Control-Allow-Origin'] = '*'
    content_type res.content_type
    expires 259200, :public
    image.to_blob
end

get '/clear/mem' do
    begin
        dc = Dalli::Client.new(
            ENV['MEMCACHIER_SERVERS'],
            {:username => ENV['MEMCACHIER_USERNAME'], :password => ENV['MEMCACHIER_PASSWORD']}
        )
        dc.flush
    rescue Exception => e
        logger.error e.to_s
        halt 500, 'NG'
    end

    'OK'
end
