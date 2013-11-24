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
            if /^http:\/\//i.test(url)
                url = url.substring(7)
                ptn = url.match(/^(img\.)?tiqav\.com\/([\w\d]+(\.jpe?g|\.gif|\.png)?)$/i)
            if ptn?
                $komenukaUrlText.val("http://" + location.host + "/tiqav/v1/" + encodeURIComponent(JSON.stringify($outjson.val())) + "/" + encodeURIComponent(ptn[2]))
            else
                $komenukaUrlText.val("http://" + location.host + "/page/v1/" + encodeURIComponent(JSON.stringify($outjson.val())) + "/" + encodeURIComponent(url))
        )

        $("#chkBtn").click(() ->
            document.getElementById("komenukaImg").src = $komenukaUrlText.val()
            return false
        )

        url = location.hash.substring(1)
        $rectangleBtn.attr({disabled: "disabled"})
        $annotateBtn.attr({disabled: "disabled"})
        $tategakiBtn.attr({disabled: "disabled"})
        $undoBtn.attr({disabled: "disabled"})
        $drawText.attr({disabled: "disabled"})
        $textSize.attr({disabled: "disabled"})

        if url
            img = new Image()
            img.crossOrigin = "Anonymous"
            img.onload = () ->
                komenukaCanvas.init(new createjs.Bitmap(img))
                $outjson.val("")
                $rectangleBtn.removeAttr("disabled")
                $annotateBtn.removeAttr("disabled")
                $tategakiBtn.removeAttr("disabled")
                $undoBtn.removeAttr("disabled")
            ptn = url.match(/^http:\/\/tiqav\.com\/([\w\d]+)$/i)
            if ptn isnt null
                # あとでちゃんとかく
                $.get("//allow-any-origin.appspot.com/http://api.tiqav.com/images/" + ptn[1] + ".json", (data) ->
                    tiqavUrl = "http://img.tiqav.com/" + data.id + "." + data.ext
                    $imageUrlText.val(tiqavUrl)
                    img.src = "//allow-any-origin.appspot.com/" + tiqavUrl
                )
            else
                # Access-Control-Allow-Originで許可されていればproxyいらない
                img.src = "//allow-any-origin.appspot.com/" + url
            $rectangleBtn.click(() ->
                $drawText.attr({disabled: "disabled"})
                $textSize.attr({disabled: "disabled"})
                komenukaCanvas.publishRectangleEvents()
            )
            $annotateBtn.click(() ->
                $drawText.removeAttr("disabled")
                $textSize.removeAttr("disabled")
                komenukaCanvas.publishAnnotateEvents($drawText, $textSize)
            )
            $tategakiBtn.click(() ->
                $drawText.removeAttr("disabled")
                $textSize.removeAttr("disabled")
                komenukaCanvas.publishTategakiEvents($drawText, $textSize)
            )
            $undoBtn.click(() ->
                komenukaCanvas.undo()
            )
            $("#spuitBtn").click(() ->
                komenukaCanvas.publishSpuitEvents()
            )
            $("#canvas").on("komenuka:update", (event, obj) ->
                if obj is undefined or Object.keys(obj).length is 0
                    $outjson.val("")
                    $komenukaUrlText.val("")
                    return
                $outjson.val(JSON.stringify(obj))
                if /^http:\/\//i.test(url)
                    urlPath = url.substring(7)
                    ptn = urlPath.match(/^(img\.)?tiqav\.com\/([\w\d]+(\.jpe?g|\.gif|\.png)?)$/i)
                if ptn?
                    $komenukaUrlText.val("http://" + location.host + "/tiqav/v1/" + encodeURIComponent(JSON.stringify(obj)) + "/" + encodeURIComponent(ptn[2]))
                else
                    $komenukaUrlText.val("http://" + location.host + "/page/v1/" + encodeURIComponent(JSON.stringify(obj)) + "/" + encodeURIComponent(urlPath))
            )

if location.hash? or location.hash is ""
    komenukaEditor.initEditor()
else
    komenukaEditor.container.html(T.editor_edit.render())

app = angular.module("app", [])
app.controller("EditorController", ["$scope", ($scope) ->
    $scope.inputUrl = () ->
        location.hash = $scope.url
        komenukaEditor.initEditor()
])
