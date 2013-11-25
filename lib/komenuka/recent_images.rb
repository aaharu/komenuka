# coding: utf-8
# komenuka
# Copyright (c) 2013 aaharu
# https://raw.github.com/aaharu/komenuka/master/LICENSE
require 'RMagick'
require 'dalli'
require 'memcachier'
require 'set'
require 'uri'

module Komenuka
    module RecentImages
        IMAGE_NUM_MAX = 15

        def self.saveRecentUrl url
            dc = Dalli::Client.new(
                ENV['MEMCACHIER_SERVERS'].split(','),
                {:username => ENV['MEMCACHIER_USERNAME'], :password => ENV['MEMCACHIER_PASSWORD']}
            )
            image_set = dc.get('set')
            image_set = Set.new unless image_set
            if image_set.length > IMAGE_NUM_MAX
                images = image_set.to_a.shift
                images.push(Komenuka::RecentData.new(url))
                image_set = Set.new(images)
            else
                image_set.add(Komenuka::RecentData.new(url))
            end
            dc.set('set', image_set)
        end

        def self.getRecentImages
            dc = Dalli::Client.new(
                ENV['MEMCACHIER_SERVERS'].split(','),
                {:username => ENV['MEMCACHIER_USERNAME'], :password => ENV['MEMCACHIER_PASSWORD']}
            )
            return dc.get('set')
        end

        def self.deleteRecentImage url
            if url
                dc = Dalli::Client.new(
                    ENV['MEMCACHIER_SERVERS'].split(','),
                    {:username => ENV['MEMCACHIER_USERNAME'], :password => ENV['MEMCACHIER_PASSWORD']}
                )
                splited_url = url.split('/', 5)
                encoded_url =  '/' + splited_url[1] + '/' + splited_url[2] + '/' + URI.encode(splited_url[3], /[^\w\d]/) + '/' + URI.encode(splited_url[4], /[^\w\d]/)
                image_set = dc.get('set')
                image_set.delete(Komenuka::RecentData.new(encoded_url, nil, nil))
                dc.set('set', image_set)
            end
        end
    end
end
