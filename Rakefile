task :default => []

desc 'Minify JavaScript and CSS'
task :minify do
    [
        'public/js/KomenukaCanvas.js',
        'public/js/TextEx.js'
    ].each do |file|
        fork { yui_compress(file) }
    end
    Process.waitall
end

def yui_compress(file_name)
    puts "Minifying #{file_name} ..."
    if /^.+\.js$/ =~ file_name
        `java -jar bin/yuicompressor-2.4.8.jar -o '.js$:.min.js' #{file_name}`
    elsif /^.+\.css$/ =~ file_name
        `java -jar bin/yuicompressor-2.4.8.jar -o '.css$:.min.css' #{file_name}`
    end
end

desc 'Compile Sass'
task :scss do
    [
        'src/scss/komenuka.scss'
    ].each do |file|
        fork { sass_compile(file) }
    end
    Process.waitall
end

def sass_compile(file_name)
    puts "Generating CSS ..."
    %x(scss --style compressed #{file_name} public/css/#{file_name.sub(/.*\/([^\/]+)\.scss$/, '\1.css')})
end
