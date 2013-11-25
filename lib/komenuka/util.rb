# coding: utf-8
# komenuka
# Copyright (c) 2013 aaharu
# https://raw.github.com/aaharu/komenuka/master/LICENSE
require 'punycode'

module Komenuka
    module Util
        def self.buildUrl url
            unless /^http/ =~ url
                url = 'http://' + url
            else
                unless url.index('://')
                    url.sub!(':/', '://')
                end
            end
            url.sub!(/:\/\/([^\/]+)/) {|match|
                words = $1.split('.')
                words.each_with_index {|word, i|
                    next if word =~ /[0-9a-z\-]/
                    words[i] = "xn--#{Punycode.encode(word)}"
                }
                "://#{words.join('.')}"
            }
            return url
        end
    end
end
