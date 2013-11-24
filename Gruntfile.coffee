module.exports = (grunt) ->
    pkg = grunt.file.readJSON "package.json"

    grunt.initConfig
        pkg: pkg
        uglify:
            options:
                preserveComments: "some"
            compile:
                files:
                    "public/js/KomenukaCanvas.min.js": ["src/js/KomenukaCanvas.js"]
                    "public/js/TextEx.min.js": ["src/js/TextEx.js"]
                    "public/js/top.min.js": ["src/coffee/top.js"]
                    "public/js/editor.min.js": ["src/coffee/editor.js"]
                    "public/js/komenuka.min.js": ["src/ts/komenuka.js"]
                    "public/template/recent_images.js": ["src/template/recent_images.js"]
                    "public/template/editor.js": ["src/template/editor.js"]
        jshint:
            all: ["src/js/KomenukaCanvas.js", "src/js/TextEx.js"]
        stylus:
            compile:
                files:
                    "public/css/komenuka.css": "src/styl/komenuka.styl"
        coffee:
            compile:
                files:
                    "src/coffee/top.js": "src/coffee/top.coffee"
            compileBare:
                options:
                    bare: true
                files:
                    "src/coffee/editor.js": "src/coffee/editor.coffee"
        hogan:
            options:
                namespace: "T"
                defaultName: (filename) ->
                    filename.split("/").pop().split(".")[0]
            publish:
                files:
                    "src/template/recent_images.js": ["src/template/recent_images.mustache"]
                    "src/template/editor.js": ["src/template/editor_search.mustache", "src/template/editor_edit.mustache"]
        ts:
            build:
                src: ["src/ts/komenuka.ts"]
                outDir: "src/ts/"
                options:
                    comments: true
                    sourcemap: false

    grunt.loadNpmTasks "grunt-contrib-uglify"
    grunt.loadNpmTasks "grunt-contrib-jshint"
    grunt.loadNpmTasks "grunt-contrib-stylus"
    grunt.loadNpmTasks "grunt-contrib-coffee"
    grunt.loadNpmTasks "grunt-contrib-hogan"
    grunt.loadNpmTasks "grunt-ts"

    grunt.registerTask "default", ["ts", "coffee", "hogan", "jshint", "stylus", "uglify"]
