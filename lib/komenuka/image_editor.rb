# coding: utf-8
# komenuka
# Copyright (c) 2013 aaharu
# https://raw.github.com/aaharu/komenuka/master/LICENSE
require 'RMagick'

module Komenuka
    module ImageEditor
        LONG_CHARACTERS = ["\u30FC", "\u301C", "\uFF5E", "\u2026", "\uFF1D"]
        SMALL_CHARACTERS = ["\u3041", "\u3043", "\u3045", "\u3047", "\u3049", "\u3083", "\u3085", "\u3087", "\u3063", "\u30A1", "\u30A3", "\u30A5", "\u30A7", "\u30A9", "\u30E3", "\u30E5", "\u30E7", "\u30C3"]
        PUNCTUATION_CHARACTERS = ["\u3001", "\uFF0C", "\u3002", "\uFF0E"]
        PARENTHESIS_CHARACTERS = ["\u3009", "\u300B", "\u300D", "\u300F", "\u3011", "\u3015", "\u3017", "\u3019", "\uFF09", "\uFF5D", "\uFF60", "\u3008", "\u300A", "\u300C", "\u300E", "\u3010", "\u3014", "\u3016", "\u3018", "\uFF08", "\uFF5B", "\uFF5F", "\uFF1C", "\uFF1E", "\u201C", "\u201D", "\u2018", "\u2019"]
        ASCII_CHARACTERS = ['"', "'", '-', '/', ':', ';', '<', '=', '>', '[', ']', '\\', ']', '{', '|', '}', '(', ')']

        def self.selectFont(fontFamily)
            case fontFamily
            when 'ipag'
                return fontFamily
            when 'ipagp'
                return fontFamily
            when 'ipam'
                return fontFamily
            when 'ipamp'
                return fontFamily
            when '07YasashisaAntique'
                return fontFamily
            else
                return '07YasashisaAntique'
            end
        end

        def self.calculateMatrix(sx, sy, deg, dx, dy)
            # なぜかtx, tyが効かない
            rad = deg * Math::PI / 180;
            cos = Math.cos(rad);
            sin = Math.sin(rad);
            return Magick::AffineMatrix.new(sx * cos, sy * sin, -sx * sin, sy * cos, sx * (cos * dx - sin * dy), sy * (sin * dx + cos * dy))
        end

        def self.editImage(command_hash, image)
            if command_hash.key?('rectangle') then
                args = command_hash['rectangle']
                if args.instance_of?(Hash) then
                    args = [args]
                end
                for arg in args do
                    draw = Magick::Draw.new
                    draw.fill = arg.fetch('color', '#FFFFFF')
                    draw.rectangle(arg.fetch('x1', 0).to_i, arg.fetch('y1', 0).to_i, arg.fetch('x2', 0).to_i, arg.fetch('y2', 0).to_i)
                    draw.draw(image)
                end
            end

            if command_hash.key?('annotate') then
                args = command_hash['annotate']
                if args.instance_of?(Hash) then
                    args = [args]
                end
                for arg in args do
                    if arg.key?('text') then
                        x = arg.fetch('x', 0).to_i
                        y = arg.fetch('y', 0).to_i
                        fontSize = arg.fetch('size', 30).to_i
                        fontFamily = self.selectFont(arg['font'])
                        lines = arg['text'].split
                        j = 1
                        for line in lines do
                            draw = Magick::Draw.new
                            draw.annotate(image, image.columns, image.rows, x, y + fontSize * j, line) do
                                self.font = "fonts/#{fontFamily}.ttf"
                                self.fill = arg.fetch('color', '#000000')
                                self.pointsize = fontSize
                            end
                            j += 1
                        end
                    end
                end
            end

            if command_hash.key?('tategaki') then
                args = command_hash['tategaki']
                if args.instance_of?(Hash) then
                    args = [args]
                end
                for arg in args do
                    if arg.key?('text') then
                        x = arg.fetch('x', 0).to_i
                        y = arg.fetch('y', 0).to_i
                        fontSize = arg.fetch('size', 30).to_i
                        fontFamily = self.selectFont(arg['font'])
                        lines = arg['text'].split
                        j = 0
                        for line in lines do
                            draw = Magick::Draw.new
                            i = 0
                            half_count = 0.0
                            while i < line.size
                                # AffineMatrixのtx,tyが効かないので無理やり合わせる
                                drawX = x.to_f - fontSize.to_f * j.to_f
                                drawY = y.to_f + fontSize.to_f * (i.to_f + 1.0 - half_count / 2.0)
                                type = 0
                                if LONG_CHARACTERS.include?(line[i]) then
                                    type = 1
                                    drawX += 0.35 * fontSize
                                    drawY -= 0.35 * fontSize
                                elsif SMALL_CHARACTERS.include?(line[i]) then
                                    type = 2
                                    drawX += 0.125 * fontSize
                                    drawY -= 0.125 * fontSize
                                elsif PUNCTUATION_CHARACTERS.include?(line[i]) then
                                    type = 3
                                    drawX += 0.625 * fontSize
                                    drawY -= 0.625 * fontSize
                                elsif PARENTHESIS_CHARACTERS.include?(line[i]) then
                                    type = 4
                                    drawX -= 0.4 * fontSize
                                    drawY -= 0.35 * fontSize
                                elsif ASCII_CHARACTERS.include?(line[i]) then
                                    type = 5
                                    drawX -= 0.4 * fontSize
                                    drawY -= 0.45 * fontSize
                                    half_count += 1.0
                                end
                                draw.annotate(image, image.columns, image.rows, drawX, drawY, line[i]) do
                                    self.font = "fonts/#{fontFamily}.ttf"
                                    self.align = Magick::CenterAlign
                                    self.fill = arg.fetch('color', '#000000')
                                    self.pointsize = fontSize
                                    if type == 1 then
                                        self.affine = self.calculateMatrix(1, -1, 270, 0, 0)
                                    elsif type == 2 then
                                        self.affine = self.calculateMatrix(1, 1, 0, 0, 0)
                                    elsif type == 3 then
                                        self.affine = self.calculateMatrix(1, 1, 0, 0, 0)
                                    elsif type == 4 then
                                        self.affine = self.calculateMatrix(1, 1, 90, 0, 0)
                                    elsif type == 5 then
                                        self.affine = self.calculateMatrix(1, 1, 90, 0, 0)
                                    end
                                end
                                i += 1
                            end
                            j += 1
                        end
                    end
                end
            end
        end
    end
end
