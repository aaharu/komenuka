# coding: utf-8
# komenuka
# Copyright (c) 2013 aaharu
# https://raw.github.com/aaharu/komenuka/master/LICENSE
require 'json'

module Komenuka
    class RecentData
        attr_reader :url

        def initialize(url)
            @url = url
        end

        def hash
            @url.hash
        end

        def eql?(other)
            @url.eql?(other.url)
        end

        def to_json(*a)
            {:url => @url, :image => @url.sub(/^\/page\//, '/image/')}.to_json(*a)
        end
    end
end
