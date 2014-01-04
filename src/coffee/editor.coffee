komenukaEditor =
    container:
        $("#main")
    initEditor: () ->
        komenukaEditor.container.html(T.editor_edit.render())

        $outjson = $("#outjson")
        $rectangleBtn = $("#rectangleBtn")
        $annotateBtn = $("#annotateBtn")
        $tategakiBtn = $("#tategakiBtn")
        $undoBtn = $("#undoBtn")
        $drawText = $("#drawText")
        $textSize = $("#textSize")
        $komenukaUrlText = $("#komenukaUrlText")
        komenukaCanvas = new komenuka.Canvas(new createjs.Stage("canvas"), $("#colorPicker-r"), $("#colorPicker-w"))

        $outjson.change(() ->
            url = location.hash.substring(1)
            $komenukaUrlText.val("http://#{location.host}/page/v1/#{encodeURIComponent(JSON.stringify($outjson.val()))}/#{encodeURIComponent(url)}")
            return
        )

        $("#chkBtn").click(() ->
            document.getElementById("komenukaImg").src = $komenukaUrlText.val().replace("page", "image")
            return false
        )

        url = location.hash.substring(1)
        $rectangleBtn.attr({disabled: "disabled"})
        $annotateBtn.attr({disabled: "disabled"})
        $tategakiBtn.attr({disabled: "disabled"})
        $undoBtn.attr({disabled: "disabled"})
        $drawText.attr({disabled: "disabled"})
        $textSize.attr({disabled: "disabled"})

        if not url
            alert("url error")
            return
        reg = url.match(/(https?):\/\/([^\/]+)(.*)/i)
        if reg is null
            alert("url error")
            return
        url = reg[1] + "://" + punycode.toASCII(reg[2]) + reg[3]
        is_html = false
        if /^(.+)\.jpg\.to$/i.test(reg[2]) or /^http:\/\/gazoreply\.jp\/\d+\/[a-z\.0-9]+$/i.test(url)
            is_html = true

        img = new Image()
        img.crossOrigin = "Anonymous"
        img.onload = () ->
            jscolor.init()
            komenukaCanvas.init(new createjs.Bitmap(img))
            $outjson.val("")
            $rectangleBtn.removeAttr("disabled")
            $annotateBtn.removeAttr("disabled")
            $tategakiBtn.removeAttr("disabled")
            $undoBtn.removeAttr("disabled")
            return
        if is_html
            # あとでちゃんとかく
            $.get("//allow-any-origin.appspot.com/" + url, (data) ->
                imgTag = data.match(/<img.+src="([^"]+)".+>/i)
                if imgTag isnt null
                    img.src = "//allow-any-origin.appspot.com/#{imgTag[1]}"
            )
        else
            ptn = url.match(/^http:\/\/tiqav\.com\/([\w\d]+)$/i)
            if ptn isnt null
                # あとでちゃんとかく
                $.get("//allow-any-origin.appspot.com/http://api.tiqav.com/images/#{ptn[1]}.json", (data) ->
                    tiqavUrl = "http://img.tiqav.com/#{data.id}.#{data.ext}"
                    location.hash = tiqavUrl
                    url = tiqavUrl
                    img.src = "//allow-any-origin.appspot.com/#{tiqavUrl}"
                    return
                )
            else
                # Access-Control-Allow-Originで許可されていればproxyいらない
                img.src = "//allow-any-origin.appspot.com/#{url}"

        $rectangleBtn.click(() ->
            $drawText.attr({disabled: "disabled"})
            $textSize.attr({disabled: "disabled"})
            komenukaCanvas.publishRectangleEvents()
            return
        )

        $annotateBtn.click(() ->
            $drawText.removeAttr("disabled")
            $textSize.removeAttr("disabled")
            komenukaCanvas.publishAnnotateEvents($drawText, $textSize)
            return
        )

        $tategakiBtn.click(() ->
            $drawText.removeAttr("disabled")
            $textSize.removeAttr("disabled")
            komenukaCanvas.publishTategakiEvents($drawText, $textSize)
            return
        )

        $undoBtn.click(() ->
            komenukaCanvas.undo()
            return
        )

        $("#spuitBtn").click(() ->
            komenukaCanvas.publishSpuitEvents()
            return
        )

        $("#canvas").on("komenuka:update", (event, obj) ->
            if obj is undefined or Object.keys(obj).length is 0
                $outjson.val("")
                $komenukaUrlText.val("")
                return
            $outjson.val(JSON.stringify(obj))
            $komenukaUrlText.val("http://#{location.host}/page/v1/#{encodeURIComponent(JSON.stringify(obj))}/#{encodeURIComponent(url)}")
            return
        )
        return

if location.hash is ""
    komenukaEditor.container.html(T.editor_search.render())
else
    komenukaEditor.initEditor()

app = angular.module("app", [])
app.controller("EditorController", ["$scope", "$http", ($scope, $http) ->
    $scope.images = []

    $scope.inputUrl = () ->
        if not $scope.url?
            return
        location.hash = $scope.url
        komenukaEditor.initEditor()
        return

    $scope.searchTiqav = () ->
        if not $scope.query?
            return
        $scope.images = [{src: "/img/loading.gif"}]
        $http.jsonp("http://api.tiqav.com/search.json?callback=JSON_CALLBACK&q=#{$scope.query}").success((data) ->
            srcs = []
            data.forEach((image) ->
                srcs.push
                    src: "http://img.tiqav.com/#{image.id}.#{image.ext}"
                return
            )
            $scope.images = srcs
            return
        )
        return

    $scope.selectImage = ($event) ->
        if $event.target.src? and not /\/img\/loading\.gif$/.test($event.target.src)
            location.hash = $event.target.src
            komenukaEditor.initEditor()
        return
    return
])
