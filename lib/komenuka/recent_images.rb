# coding: utf-8
# komenuka
# Copyright (c) 2013 aaharu
# https://raw.github.com/aaharu/komenuka/master/LICENSE
require 'RMagick'
require 'dalli'
require 'memcachier'
require 'set'

module Komenuka
    module RecentImages
        IMAGE_NUM_MAX = 15

        def self.saveRecentUrl(url, image)
            prefix = nil
            if image.format == 'JPEG' then
                prefix = 'jpg'
            elsif image.format == 'GIF' then
                prefix = 'gif'
            elsif image.format == 'PNG' then
                prefix = 'png'
            end
            if prefix then
                dc = Dalli::Client.new(
                    ENV['MEMCACHIER_SERVERS'].split(','),
                    {:username => ENV['MEMCACHIER_USERNAME'], :password => ENV['MEMCACHIER_PASSWORD']}
                )
                image_set = dc.get('set')
                unless image_set
                    image_set = Set.new
                end
                if image_set.length > IMAGE_NUM_MAX
                    tmp = image_set.to_a.shift
                    tmp.push(Komenuka::RecentData.new(url, prefix, image))
                    image_set = Set.new(tmp)
                else
                    image_set.add(Komenuka::RecentData.new(url, prefix, image))
                end
                dc.set('set', image_set)
            end
        end

        def self.getRecentImages()
            dc = Dalli::Client.new(
                ENV['MEMCACHIER_SERVERS'].split(','),
                {:username => ENV['MEMCACHIER_USERNAME'], :password => ENV['MEMCACHIER_PASSWORD']}
            )
            return dc.get('set')
        end
    end
end
