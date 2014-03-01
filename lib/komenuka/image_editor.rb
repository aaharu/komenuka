# coding: utf-8
# komenuka
# Copyright (c) 2013 aaharu
# https://raw.github.com/aaharu/komenuka/master/LICENSE
require 'RMagick'

module Komenuka
    module ImageEditor
        LONG_CHARACTERS = %W(\u30FC \u301C \uFF5E \u2026 \uFF1D)
        SMALL_CHARACTERS = %W(\u3041 \u3043 \u3045 \u3047 \u3049 \u3083 \u3085 \u3087 \u3063 \u30A1 \u30A3 \u30A5 \u30A7 \u30A9 \u30E3 \u30E5 \u30E7 \u30C3)
        PUNCTUATION_CHARACTERS = %W(\u3001 \uFF0C \u3002 \uFF0E)
        PARENTHESIS_CHARACTERS = %W(\u3009 \u300B \u300D \u300F \u3011 \u3015 \u3017 \u3019 \uFF09 \uFF5D \uFF60 \u3008 \u300A \u300C \u300E \u3010 \u3014 \u3016 \u3018 \uFF08 \uFF5B \uFF5F \uFF1C \uFF1E \u201C \u201D \u2018 \u2019)
        ASCII_CHARACTERS = ['"', "'", '-', '/', ':', ';', '<', '=', '>', '[', ']', '\\', ']', '{', '|', '}', '(', ')']

        def self.select_font(font)
            case font
            when 'ipag'
                return font
            when 'ipagp'
                return font
            when 'ipam'
                return font
            when 'ipamp'
                return font
            when '07YasashisaAntique'
                return font
            else
                return '07YasashisaAntique'
            end
        end

        def self.calculate_matrix(sx, sy, deg, dx, dy)
            # なぜかtx, tyが効かない
            rad = deg * Math::PI / 180
            cos = Math.cos(rad)
            sin = Math.sin(rad)
            return Magick::AffineMatrix.new(sx * cos, sy * sin, -sx * sin, sy * cos, sx * (cos * dx - sin * dy), sy * (sin * dx + cos * dy))
        end

        def self.edit_image(command_hash, image)
            if command_hash.key?('rectangle')
                args = command_hash['rectangle']
                args = [args] if args.instance_of?(Hash)
                for arg in args do
                    draw = Magick::Draw.new
                    draw.fill = arg.fetch('color', '#FFFFFF')
                    draw.rectangle(arg.fetch('x1', 0).to_i, arg.fetch('y1', 0).to_i, arg.fetch('x2', 0).to_i, arg.fetch('y2', 0).to_i)
                    draw.draw(image)
                end
            end

            if command_hash.key?('annotate')
                args = command_hash['annotate']
                args = [args] if args.instance_of?(Hash)
                for arg in args do
                    if arg.key?('text')
                        x = arg.fetch('x', 0).to_i
                        y = arg.fetch('y', 0).to_i
                        size = arg.fetch('size', 30).to_i
                        font = self.select_font(arg['font'])
                        lines = arg['text'].split
                        j = 1
                        for line in lines do
                            draw = Magick::Draw.new
                            draw.annotate(image, image.columns, image.rows, x, y + size * j, line) do
                                self.font = "fonts/#{font}.ttf"
                                self.fill = arg.fetch('color', '#000000')
                                self.pointsize = size
                            end
                            j += 1
                        end
                    end
                end
            end

            if command_hash.key?('tategaki')
                args = command_hash['tategaki']
                args = [args] if args.instance_of?(Hash)
                for arg in args do
                    if arg.key?('text')
                        x = arg.fetch('x', 0).to_i
                        y = arg.fetch('y', 0).to_i
                        size = arg.fetch('size', 30).to_i
                        font = self.select_font(arg['font'])
                        lines = arg['text'].split
                        j = 0
                        for line in lines do
                            draw = Magick::Draw.new
                            i = 0
                            half_count = 0.0
                            while i < line.size
                                # AffineMatrixのtx,tyが効かないので無理やり合わせる
                                draw_x = x.to_f - size.to_f * j.to_f
                                draw_y = y.to_f + size.to_f * (i.to_f + 1.0 - half_count / 2.0)
                                type = 0
                                if LONG_CHARACTERS.include?(line[i])
                                    type = 1
                                    draw_x += 0.35 * size
                                    draw_y -= 0.35 * size
                                elsif SMALL_CHARACTERS.include?(line[i])
                                    type = 2
                                    draw_x += 0.125 * size
                                    draw_y -= 0.125 * size
                                elsif PUNCTUATION_CHARACTERS.include?(line[i])
                                    type = 3
                                    draw_x += 0.625 * size
                                    draw_y -= 0.625 * size
                                elsif PARENTHESIS_CHARACTERS.include?(line[i])
                                    type = 4
                                    draw_x -= 0.4 * size
                                    draw_y -= 0.35 * size
                                elsif ASCII_CHARACTERS.include?(line[i])
                                    type = 5
                                    draw_x -= 0.4 * size
                                    draw_y -= 0.45 * size
                                    half_count += 1.0
                                end
                                draw.annotate(image, image.columns, image.rows, draw_x, draw_y, line[i]) do
                                    self.font = "fonts/#{font}.ttf"
                                    self.align = Magick::CenterAlign
                                    self.fill = arg.fetch('color', '#000000')
                                    self.pointsize = size
                                    if type == 1
                                        self.affine = ImageEditor.calculate_matrix(1, -1, 270, 0, 0)
                                    elsif type == 2
                                        self.affine = ImageEditor.calculate_matrix(1, 1, 0, 0, 0)
                                    elsif type == 3
                                        self.affine = ImageEditor.calculate_matrix(1, 1, 0, 0, 0)
                                    elsif type == 4
                                        self.affine = ImageEditor.calculate_matrix(1, 1, 90, 0, 0)
                                    elsif type == 5
                                        self.affine = ImageEditor.calculate_matrix(1, 1, 90, 0, 0)
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
