# coding: utf-8
require 'sinatra'
require 'RMagick'
require 'uri'
require 'net/http'
require 'json'
require 'gd2'

get '/font_list' do
    font_list = []
    Magick.fonts.each do |font|
        font_list.push font.name
    end
    font_list.join '<br>'
end

get '/image/v1/*/*' do |command, url|

    commandHash = JSON.parse(command)

    url = url.sub(':/', '://')
    uri = URI.parse(url)
    response = Net::HTTP.start(uri.host, uri.port) {|http|
        http.get(uri.path)
    }
    #logger.error args['text']
    #image = Magick::Image.from_blob(response.body).shift

    image = GD2::Image.load(response.body)
=begin
    if commandHash.key?('rectangle') then
        args = commandHash['rectangle']

        draw = Magick::Draw.new
        draw.fill = '#FFFFFF'
        draw.rectangle(args.fetch('x1', 0).to_i, args.fetch('y1', 0).to_i, args.fetch('x2', 0).to_i, args.fetch('y2', 0).to_i)
        draw.draw(image)
    end

    if commandHash.key?('annotate') then
        args = commandHash['annotate']
        fontSize = args.fetch('size', 30).to_i

        draw = Magick::Draw.new
        draw.annotate(image, args.fetch('w', 0).to_i, args.fetch('h', 0).to_i, args.fetch('x', 0).to_i, args.fetch('y', 0).to_i + fontSize, args['text']) do
            #self.font = File.expand_path('.fonts/ipaexg.ttf')
            self.font = '.fonts/ipaexg.ttf'
            self.fill = args.fetch('color', '#000000')
            self.pointsize = fontSize
            self.rotation = 90
        end
    end
=end
    content_type response.content_type
    image.to_blob
end

get '/pic1' do
  blob = create_pic
  content_type 'image/png'
  blob
end

def create_pic
  img = Magick::Image.new(400, 300) { self.background_color = '#336699' }
  img.format = 'png'
  draw = Magick::Draw.new
  draw.annotate(img, 0, 0, 50, 100 + 30, 'Hello, World') do
    self.font = 'Verdana-Bold'
    self.fill = '#FFFFFF'
    self.align = Magick::LeftAlign
    self.stroke = 'transparent'
    self.pointsize = 30
    self.text_antialias = true
    self.kerning = 1
  end
  img.to_blob
end

get '/' do
    'Hello, world'
end
