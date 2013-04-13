# coding: utf-8
require 'sinatra'
require 'RMagick'
require 'uri'
require 'net/http'
require 'json'

get '/image/v1/*/*' do |command, url|
    begin
        commandHash = JSON.parse(command)
    rescue
        halt 400, 'command error'
    end

    begin
        url = url.sub(':/', '://')
        uri = URI.parse(url)
        response = Net::HTTP.start(uri.host, uri.port) {|http|
            http.get(uri.path)
        }
        image = Magick::Image.from_blob(response.body).shift
    rescue
        halt 500, 'url error'
    end

    begin
        if commandHash.key?('rectangle') then
            args = commandHash['rectangle']
            draw = Magick::Draw.new
            draw.fill = args.fetch('color', '#FFFFFF')
            draw.rectangle(args.fetch('x1', 0).to_i, args.fetch('y1', 0).to_i, args.fetch('x2', 0).to_i, args.fetch('y2', 0).to_i)
            draw.draw(image)
        end

        if commandHash.key?('annotate') then
            args = commandHash['annotate']
            fontSize = args.fetch('size', 30).to_i
            draw = Magick::Draw.new
            draw.annotate(image, image.columns, image.rows, args.fetch('x', 0).to_i, args.fetch('y', 0).to_i + fontSize, args['text']) do
                self.font = '.fonts/ipaexg.ttf'
                self.fill = args.fetch('color', '#000000')
                self.pointsize = fontSize
            end
        end

        if commandHash.key?('tategaki') then
            args = commandHash['tategaki']
            if args.key?('text') then
                fontSize = args.fetch('size', 30).to_i
                draw = Magick::Draw.new
                i = 0
                while i < args['text'].size
                    draw.annotate(image, image.columns, image.rows, args.fetch('x', 0).to_i + fontSize, args.fetch('y', 0).to_i + fontSize * (i + 1), args['text'][i]) do
                        self.font = '.fonts/ipaexg.ttf'
                        self.align = Magick::CenterAlign
                        self.fill = args.fetch('color', '#000000')
                        self.pointsize = fontSize
                    end
                    i += 1
                end
            end
        end
    rescue
        halt 500, 'image error'
    end

    content_type response.content_type
    image.to_blob
end

get '/' do
    'Hello, world'
end

