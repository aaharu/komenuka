# coding: utf-8
# komenuka
# Copyright (c) 2013 aaharu
# https://raw.github.com/aaharu/komenuka/master/LICENSE
require 'RMagick'
require 'sinatra'
require 'sinatra/json'
require 'uri'
require 'net/https'
require 'json'
require 'set'
require 'rack/contrib'
require 'base64'
require 'iron_cache'
require './lib/komenuka'
configure :production do
    require 'newrelic_rpm'
end

use Rack::Deflater
use Rack::StaticCache, :urls => ['/favicon.ico', '/robots.txt', '/css', '/js', '/img', '/template'], :root => 'public'
ENV['MEMCACHE_SERVERS'] = ENV['MEMCACHIER_SERVERS']
ENV['MEMCACHE_USERNAME'] = ENV['MEMCACHIER_USERNAME']
ENV['MEMCACHE_PASSWORD'] = ENV['MEMCACHIER_PASSWORD']

get '/' do
    expires 100, :public, :must_revalidate
    erb :index, :locals => {:footer => erb(:footer), :ga => erb(:ga)}
end

get '/readme' do
    expires 100, :public, :must_revalidate
    erb :readme, :locals => {:footer => erb(:footer), :ga => erb(:ga)}
end

get '/make' do
    erb :make, :locals => {:footer => erb(:footer), :ga => erb(:ga)}
end

get '/api/images/recent' do
    image_set = nil
    begin
        image_set = Komenuka::RecentImages.get_recent_images
    rescue => e
        logger.warn e.to_s
    end
    image_set = Set.new unless image_set
    hash = {:images => image_set.to_a}

    expires 100, :public, :must_revalidate
    json hash
end

delete '/api/image' do
    Komenuka::RecentImages.delete_recent_image(params['url'])
    hash = {:result => 'OK'}

    json hash
end

get '/page/v1' do
    command = params['command']
    url = params['url']
    locals = {:image_path => "/v1/#{URI.encode(command, /[^\w\d]/)}/#{URI.encode(url, /[^\w\d]/)}", :origin => Komenuka::Util.build_url(url), :ga => erb(:ga)}
    uri = URI.parse(url)
    if /^(img\.)?tiqav\.com$/ =~ uri.host
        locals[:tiqav_path] = "/v1/#{URI.encode(command, /[^\w\d]/)}#{URI.encode(uri.path)}"
    end

    expires 300, :public, :must_revalidate
    erb :image, :locals => locals
end

get '/image/v1' do
    command = params['command']
    begin
        command_hash = JSON.parse(command)
    rescue => e
        logger.error e.to_s
        halt 400, 'command error'
    end
    url = params['url']
    unless url
        halt 400, 'no url parameter'
    end

    image = nil
    use_cache = false
    img_url = nil
    ironcache = IronCache::Client.new
    cache = ironcache.cache('image_cache')
    begin
        img_url = Base64.urlsafe_encode64(command + '*' + url)
        item = cache.get(img_url)
        if item
            image = Magick::Image.from_blob(Base64.urlsafe_decode64(item.value)).shift
            use_cache = true
        end
    rescue => e
        logger.warn e.to_s
    end

    unless image
        begin
            url = Komenuka::Util.build_url(url)
            uri = URI.parse(url)
            is_html = false
            if /^(.+)\.jpg\.to$/ =~ uri.host or /^http:\/\/gazoreply\.jp\/\d+\/[a-zA-Z\.0-9]+$/ =~ url
                is_html = true
            end
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true if uri.scheme == 'https'
            res = http.get(uri.path)
            if is_html and /<img.+src="([^"]+)".+>/ =~ res.body
                uri = URI.parse($1)
                http = Net::HTTP.new(uri.host, uri.port)
                http.use_ssl = true if uri.scheme == 'https'
                res = http.get(uri.path)
            end
            image = Magick::Image.from_blob(res.body).shift
        rescue => e
            logger.info url
            logger.error e.to_s
            halt 500, 'url error'
        end
    end

    unless use_cache
        begin
            Komenuka::ImageEditor.edit_image(command_hash, image)
        rescue => e
            logger.error e.to_s
            halt 500, 'image edit error'
        end
        begin
            cache.put(img_url, Base64.urlsafe_encode64(image.to_blob), :expires_in => 60 * 60 * 24 * 30)
        rescue => e
            logger.warn e.to_s
        end

        begin
            Komenuka::RecentImages.save_recent_url("/page/v1/#{URI.encode(command, /[^\w\d]/)}/#{URI.encode(url, /[^\w\d]/)}")
        rescue => e
            logger.warn e.to_s
        end
    end

    headers['Access-Control-Allow-Origin'] = '*'
    if image.format == 'JPEG'
        content_type :jpg
    elsif image.format == 'GIF'
        content_type :gif
    elsif image.format == 'PNG'
        content_type :png
    else
        halt 500
    end
    expires 259200, :public
    image.to_blob
end

get '/page/v1/*/*' do |command, url|
    locals = {:image_path => "/v1/#{URI.encode(command, /[^\w\d]/)}/#{URI.encode(url, /[^\w\d]/)}", :origin => Komenuka::Util.build_url(url), :ga => erb(:ga)}
    uri = URI.parse(url)
    if /^(img\.)?tiqav\.com$/ =~ uri.host
        locals[:tiqav_path] = "/v1/#{URI.encode(command, /[^\w\d]/)}#{URI.encode(uri.path)}"
    end

    expires 300, :public, :must_revalidate
    erb :image, :locals => locals
end

get '/image/v1/*/*' do |command, url|
    begin
        command_hash = JSON.parse(command)
    rescue => e
        logger.error e.to_s
        halt 400, 'command error'
    end

    use_cache = false
    img_url = nil
    image = nil
    begin
        ironcache = IronCache::Client.new
        cache = ironcache.cache('image_cache')
        img_url = Base64.urlsafe_encode64(command + '*' + url)
        item = cache.get(img_url)
        if item
            image = Magick::Image.from_blob(Base64.urlsafe_decode64(item.value)).shift
            use_cache = true
        end
    rescue => e
        logger.warn e.to_s
    end

    unless image
        begin
            url = Komenuka::Util.build_url(url)
            uri = URI.parse(url)
            is_html = false
            if /^(.+)\.jpg\.to$/ =~ uri.host or /^http:\/\/gazoreply\.jp\/\d+\/[a-zA-Z\.0-9]+$/ =~ url
                is_html = true
            end
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true if uri.scheme == 'https'
            res = http.get(uri.path)
            if is_html and /<img.+src="([^"]+)".+>/ =~ res.body
                uri = URI.parse($1)
                http = Net::HTTP.new(uri.host, uri.port)
                http.use_ssl = true if uri.scheme == 'https'
                res = http.get(uri.path)
            end
            image = Magick::Image.from_blob(res.body).shift
        rescue => e
            logger.info url
            logger.error e.to_s
            halt 500, 'url error'
        end
    end

    unless use_cache
        begin
            Komenuka::ImageEditor.edit_image(command_hash, image)
        rescue => e
            logger.error e.to_s
            halt 500, 'image edit error'
        end
        begin
            cache.put(img_url, Base64.urlsafe_encode64(image.to_blob), :expires_in => 60 * 60 * 24 * 30)
        rescue => e
            logger.warn e.to_s
        end

        begin
            Komenuka::RecentImages.save_recent_url("/page/v1/#{URI.encode(command, /[^\w\d]/)}/#{URI.encode(url, /[^\w\d]/)}")
        rescue => e
            logger.warn e.to_s
        end
    end

    headers['Access-Control-Allow-Origin'] = '*'
    if image.format == 'JPEG'
        content_type :jpg
    elsif image.format == 'GIF'
        content_type :gif
    elsif image.format == 'PNG'
        content_type :png
    else
        halt 500
    end
    expires 259200, :public
    image.to_blob
end

get '/tiqav/v1/*/*' do |command, id|
    begin
        command_hash = JSON.parse(command)
    rescue => e
        logger.error e.to_s
        halt 400, 'command error'
    end

    use_cache = false
    img_url = nil
    uri = nil
    image = nil
    begin
        ironcache = IronCache::Client.new
        cache = ironcache.cache('image_cache')
        img_url = Base64.urlsafe_encode64(command + '*' + id)
        item = cache.get(img_url)
        if item
            image = Magick::Image.from_blob(Base64.urlsafe_decode64(item.value)).shift
            use_cache = true
        end
    rescue => e
        logger.warn e.to_s
    end

    unless image
        begin
            if id.index('.')
                uri = URI.parse("http://img.tiqav.com/#{id}")
            else
                uri = URI.parse("http://api.tiqav.com/images/#{id}.json")
                res = Net::HTTP.start(uri.host, uri.port) {|http|
                    http.get(uri.path)
                }
                tiqav_hash = JSON.parse(res.body)
                uri = URI.parse('http://img.tiqav.com/' + tiqav_hash['id'] + '.' + tiqav_hash['ext'])
            end
            res = Net::HTTP.start(uri.host, uri.port) {|http|
                http.get(uri.path)
            }
            image = Magick::Image.from_blob(res.body).shift
        rescue => e
            logger.error e.to_s
            halt 500, 'url error'
        end
    end

    unless use_cache
        begin
            Komenuka::ImageEditor.edit_image(command_hash, image)
        rescue => e
            logger.error e.to_s
            halt 500, 'image edit error'
        end
        begin
            cache.put(img_url, Base64.urlsafe_encode64(image.to_blob), :expires_in => 60 * 60 * 24 * 30)
        rescue => e
            logger.warn e.to_s
        end

        begin
            if uri
                Komenuka::RecentImages.save_recent_url("/page/v1/#{URI.encode(command, /[^\w\d]/)}/#{URI.encode(uri.to_s, /[^\w\d]/)}")
            end
        rescue => e
            logger.warn e.to_s
        end
    end

    headers['Access-Control-Allow-Origin'] = '*'
    if image.format == 'JPEG'
        content_type :jpg
    elsif image.format == 'GIF'
        content_type :gif
    elsif image.format == 'PNG'
        content_type :png
    else
        halt 500
    end
    expires 259200, :public
    image.to_blob
end
