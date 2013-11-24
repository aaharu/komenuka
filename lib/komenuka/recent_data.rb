# coding: utf-8
# komenuka
# Copyright (c) 2013 aaharu
# https://raw.github.com/aaharu/komenuka/master/LICENSE
require 'json'
require 'base64'

module Komenuka
    class RecentData
        attr_reader :url, :pre, :img

        def initialize(url, prefix, image)
            @url = url
            @pre = prefix
            @img = image
        end

        def hash
            @url.hash
        end

        def eql?(other)
            @url.eql?(other.url)
        end

        def to_json(*a)
            {:url => @url, :type => @pre, :data => Base64.strict_encode64(@img.to_blob)}.to_json(*a)
        end
    end
end
