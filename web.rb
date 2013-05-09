# coding: utf-8
require 'sinatra'
require 'RMagick'
require 'uri'
require 'net/http'
require 'json'
require 'dalli'
require 'set'

use Rack::Static, :urls => ['/favicon.ico', '/robots.txt', '/css', '/js'], :root => 'public'
IMAGE_NUM_MAX = 15

get '/' do
    begin
        dc = Dalli::Client.new(
            ENV['MEMCACHIER_SERVERS'],
            {:username => ENV['MEMCACHIER_USERNAME'], :password => ENV['MEMCACHIER_PASSWORD']}
        )
        imageSet = dc.get('set')
    rescue => e
        logger.warn e.to_s
    end
    unless imageSet
        imageSet = Set.new
    end
    erb :index, :locals => {:images => imageSet}
end

get '/readme' do
    erb :readme
end

get '/make' do
    erb :make
end

get '/proxy' do
    unless params.has_key?('url')
        halt 400, 'bad parameter'
    end

    begin
        uri = URI.parse(params['url'])
        response = Net::HTTP.start(uri.host, uri.port) {|http|
            http.get(uri.path)
        }
    rescue => e
        logger.error e.to_s
        halt 500, 'url error'
    end

    content_type response.content_type
    #同ドメインになるのでつけなくてもいいけど
    headers['Access-Control-Allow-Origin'] = '*'
    response.body
end

get '/image/v1/*/*' do |command, url|
    begin
        commandHash = JSON.parse(command)
    rescue => e
        logger.error e.to_s
        halt 400, 'command error'
    end

    begin
        unless url.index('://') then
            url = url.sub(':/', '://')
        end
        uri = URI.parse(url)
        response = Net::HTTP.start(uri.host, uri.port) {|http|
            http.get(uri.path)
        }
        image = Magick::Image.from_blob(response.body).shift
    rescue => e
        logger.info url
        logger.error e.to_s
        halt 500, 'url error'
    end

    begin
        if commandHash.key?('rectangle') then
            args = commandHash['rectangle']
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

        if commandHash.key?('annotate') then
            args = commandHash['annotate']
            if args.instance_of?(Hash) then
                args = [args]
            end
            for arg in args do
                fontSize = arg.fetch('size', 30).to_i
                draw = Magick::Draw.new
                draw.annotate(image, image.columns, image.rows, arg.fetch('x', 0).to_i, arg.fetch('y', 0).to_i + fontSize, arg['text']) do
                    self.font = 'fonts/ipaexg.ttf'
                    self.fill = arg.fetch('color', '#000000')
                    self.pointsize = fontSize
                end
            end
        end

        if commandHash.key?('tategaki') then
            args = commandHash['tategaki']
            if args.instance_of?(Hash) then
                args = [args]
            end
            for arg in args do
                if arg.key?('text') then
                    fontSize = arg.fetch('size', 30).to_i
                    draw = Magick::Draw.new
                    i = 0
                    while i < arg['text'].size
                        draw.annotate(image, image.columns, image.rows, arg.fetch('x', 0).to_i + fontSize, arg.fetch('y', 0).to_i + fontSize * (i + 1), arg['text'][i]) do
                            self.font = 'fonts/ipaexg.ttf'
                            self.align = Magick::CenterAlign
                            self.fill = arg.fetch('color', '#000000')
                            self.pointsize = fontSize
                        end
                        i += 1
                    end
                end
            end
        end
    rescue => e
        logger.error e.to_s
        halt 500, 'image error'
    end

    begin
        dc = Dalli::Client.new(
            ENV['MEMCACHIER_SERVERS'],
            {:username => ENV['MEMCACHIER_USERNAME'], :password => ENV['MEMCACHIER_PASSWORD']}
        )
        imageSet = dc.get('set')
        unless imageSet
            imageSet = Set.new
        end
        if imageSet.length > IMAGE_NUM_MAX
            tmp = imageSet.to_a.shift
            tmp.push("/image/v1/#{URI.encode(command)}/#{URI.encode(url)}")
            imageSet = Set.new(tmp)
        else
            imageSet.add("/image/v1/#{URI.encode(command)}/#{URI.encode(url)}")
        end
        dc.set('set', imageSet)
    rescue => e
        logger.warn e.to_s
    end

    headers['Access-Control-Allow-Origin'] = '*'
    content_type response.content_type
    cache_control :public
    image.to_blob
end
