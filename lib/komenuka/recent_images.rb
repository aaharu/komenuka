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

        def self.save_recent_url(url)
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

        def self.get_recent_images
            dc = Dalli::Client.new(
                ENV['MEMCACHIER_SERVERS'].split(','),
                {:username => ENV['MEMCACHIER_USERNAME'], :password => ENV['MEMCACHIER_PASSWORD']}
            )
            return dc.get('set')
        end

        def self.delete_recent_image(url)
            if url
                dc = Dalli::Client.new(
                    ENV['MEMCACHIER_SERVERS'].split(','),
                    {:username => ENV['MEMCACHIER_USERNAME'], :password => ENV['MEMCACHIER_PASSWORD']}
                )
                split_url = url.split('/', 5)
                encoded_url =  '/' + split_url[1] + '/' + split_url[2] + '/' + URI.encode(split_url[3], /[^\w\d]/) + '/' + URI.encode(split_url[4], /[^\w\d]/)
                image_set = dc.get('set')
                image_set.delete(Komenuka::RecentData.new(encoded_url))
                dc.set('set', image_set)
            end
        end
    end
end
