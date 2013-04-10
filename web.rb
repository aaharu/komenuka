# coding: utf-8
require 'sinatra'
require 'RMagick'
require 'uri'
require 'net/http'
require 'json'

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
    image = Magick::Image.from_blob(response.body).shift
    draw = Magick::Draw.new
    #logger.info File.expand_path('.fonts/ipaexg.ttf')
    #draw.font(File.expand_path('.fonts/ipaexg.ttf'))
    if commandHash.key?('annotate') then
        args = commandHash['annotate']
        #logger.error args['text']
        draw.annotate(image, args.fetch('w', 0), args.fetch('h', 0), args.fetch('x', 0), args.fetch('y', 0) + args.fetch('size', 30), args['text']) do
            self.font = File.expand_path('.fonts/ipaexg.ttf')
            self.fill = args.fetch('color', '#000000')
            self.pointsize = args.fetch('size', 30)
        end
    end

    content_type response.content_type
    #response.body
    #image.blur_image(0,2).to_blob
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
