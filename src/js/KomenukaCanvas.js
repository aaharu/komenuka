/*!
 * KomenukaCanvas
 * Copyright (c) 2013 aaharu
 * https://raw.github.com/aaharu/komenuka/master/LICENSE
 */
var KomenukaCanvas = function (stage, $out, $outUrl, $colorPicker1, $colorPicker2, $imageUrlText) {
    "use strict";
    var shape, overlay, jsonObj, image, jsonObjHistory;

    function updateJson(obj) {
        var k;
        //Objectの結合
        for (k in obj) {
            if (obj.hasOwnProperty(k)) {
                if (jsonObj[k] === undefined) {
                    jsonObj[k] = obj[k];
                } else if (jsonObj[k] instanceof Array) {
                    jsonObj[k][(jsonObj[k]).length] = obj[k];
                } else {
                    jsonObj[k] = [jsonObj[k], obj[k]];
                }
            }
        }
        //add history
        jsonObjHistory[jsonObjHistory.length] = $.extend(true, {}, jsonObj);
        updateHtml(jsonObj);
    }

    function updateHtml(obj) {
        var url, ptn;
        if (obj === undefined || Object.keys(obj).length === 0) {
            $out.val("");
            $outUrl.val("");
            return;
        }
        $out.val(JSON.stringify(obj));
        url = $imageUrlText.val();
        if ((/^http:\/\//i).test(url)) {
            url = url.substring(7);
            ptn = url.match(/^(img\.)?tiqav\.com\/([\w\d]+(\.jpg|\.gif|\.png)?)$/i);
        }
        if (ptn === null || ptn === undefined) {
            $outUrl.val("http://komenuka.herokuapp.com/image/v1/" + encodeURIComponent(JSON.stringify(obj)) + "/" + encodeURIComponent(url));
        } else {
            $outUrl.val("http://komenuka.herokuapp.com/tiqav/v1/" + encodeURIComponent(JSON.stringify(obj)) + "/" + encodeURIComponent(ptn[2]));
        }
    }

    function drawFromJson(json) {
        var command, args, i, l, color, x1, x2, y1, y2, t, text, size;
        for (command in json) {
            if (json.hasOwnProperty(command)) {
                if (json[command].length) {
                    args = json[command];
                } else {
                    args = [json[command]];
                }
                switch (command) {
                case "rectangle":
                    for (i = 0, l = args.length; i < l; ++i) {
                        color = args[i].color || "#fff";
                        x1 = args[i].x1 || 0;
                        x2 = args[i].x2 || 0;
                        y1 = args[i].y1 || 0;
                        y2 = args[i].y2 || 0;
                        shape.graphics.f(color).r(x1, y1, x2 - x1, y2 - y1).ef();
                        stage.update();
                    }
                    break;
                case "annotate":
                    for (i = 0, l = args.length; i < l; ++i) {
                        t = args[i].text || "";
                        x1 = args[i].x || 0;
                        y1 = args[i].y || 0;
                        size = args[i].size || "30";
                        color = args[i].color || "#000000";
                        text = new createjs.Text(t, size + "px Arial", color);
                        text.x = x1;
                        text.y = y1;
                        stage.addChild(text);
                        stage.update();
                    }
                    break;
                case "tategaki":
                    for (i = 0, l = args.length; i < l; ++i) {
                        t = args[i].text || "";
                        x1 = args[i].x || 0;
                        y1 = args[i].y || 0;
                        size = args[i].size || "30";
                        color = args[i].color || "#000000";
                        text = new createjs.Text(t, size + "px Arial", color);
                        text.x = x1;
                        text.y = y1;
                        text.blockProgression = "rl";
                        text.textAlign = "center";
                        stage.addChild(text);
                        stage.update();
                    }
                    break;
                }
            }
        }
    }

    function clear() {
        stage.removeAllChildren();
        stage.addChild(image);
        shape = new createjs.Shape();
        stage.addChild(shape);
    }

    return {
        "init" : function(bmp) {
            image = bmp;
            stage.removeAllEventListeners();
            stage.canvas.width = bmp.image.width;
            stage.canvas.height = bmp.image.height;
            clear();
            overlay = new createjs.Shape();
            overlay.alpha = 0.7;
            stage.addChild(overlay);
            stage.update();
            jsonObj = {};
            jsonObjHistory = [];
            return this;
        },
        "publishRectangleEvents" : function() {
            stage.removeAllEventListeners();
            stage.addEventListener("mousedown", function(mouseDownEvent) {
                var startX = mouseDownEvent.stageX|0, startY = mouseDownEvent.stageY|0;
                mouseDownEvent.addEventListener("mousemove", function(mouseMoveEvent) {
                    var moveX = mouseMoveEvent.stageX|0, moveY = mouseMoveEvent.stageY|0;
                    overlay.graphics.c().f("#" + $colorPicker1.val()).r(startX, startY, moveX - startX, moveY - startY).ef();
                    stage.update();
                });
                mouseDownEvent.addEventListener("mouseup", function(mouseUpEvent) {
                    var x1, x2, y1, y2, obj = {}, color = "#" + $colorPicker1.val(), upX = mouseUpEvent.stageX|0, upY = mouseUpEvent.stageY|0;
                    overlay.graphics.c();
                    shape.graphics.f(color).r(startX, startY, upX - startX, upY - startY).ef();
                    stage.update();
                    // update rectangle json
                    if (startX < upX) {
                        x1 = startX;
                        x2 = upX;
                    } else {
                        x1 = upX;
                        x2 = startX;
                    }
                    if (startY < upY) {
                        y1 = startY;
                        y2 = upY;
                    } else {
                        y1 = upY;
                        y2 = startY;
                    }
                    if (x1 !== 0) {
                        obj.x1 = x1;
                    }
                    if (x2 !== 0) {
                        obj.x2 = x2;
                    }
                    if (y1 !== 0) {
                        obj.y1 = y1;
                    }
                    if (y2 !== 0) {
                        obj.y2 = y2;
                    }
                    if (color !== "#FFFFFF") {
                        obj.color = color;
                    }
                    updateJson({"rectangle" : obj});
                });
            });
        },
        "publishAnnotateEvents" : function(jqStr, jqSize) {
            stage.removeAllEventListeners();
            stage.addEventListener("mousedown", function(mouseDownEvent) {
                if (jqStr.val()) {
                    var size = jqSize.val(),
                        color = "#" + $colorPicker2.val(),
                        text = new createjs.Text(jqStr.val(), size + "px Arial", color);
                    text.x = mouseDownEvent.stageX|0;
                    text.y = mouseDownEvent.stageY|0;
                    text.alpha = 0.6;
                    stage.addChild(text);
                    stage.update();
                    mouseDownEvent.addEventListener("mousemove", function(mouseMoveEvent) {
                        text.x = mouseMoveEvent.stageX|0;
                        text.y = mouseMoveEvent.stageY|0;
                        stage.update();
                    });
                    mouseDownEvent.addEventListener("mouseup", function(mouseUpEvent) {
                        var obj = {"text" : text.text}, upX = mouseUpEvent.stageX|0, upY = mouseUpEvent.stageY|0;
                        text.x = upX;
                        text.y = upY;
                        text.alpha = 1;
                        stage.update();
                        // update annotate json
                        if (upX >= 1) {
                            obj.x = upX;
                        }
                        if (upY >= 1) {
                            obj.y = upY;
                        }
                        if (size !== "30") {
                            obj.size = size;
                        }
                        if (color !== "#000000") {
                            obj.color = color;
                        }
                        updateJson({"annotate" : obj});
                    });
                }
            });
        },
        "publishTategakiEvents" : function(jqStr, jqSize) {
            stage.removeAllEventListeners();
            stage.addEventListener("mousedown", function(mouseDownEvent) {
                if (jqStr.val()) {
                    var size = jqSize.val(),
                        color = "#" + $colorPicker2.val(),
                        text = new createjs.Text(jqStr.val(), size + "px Arial", color);
                    text.x = mouseDownEvent.stageX|0;
                    text.y = mouseDownEvent.stageY|0;
                    text.alpha = 0.6;
                    text.blockProgression = "rl";
                    text.textAlign = "center";
                    stage.addChild(text);
                    stage.update();
                    mouseDownEvent.addEventListener("mousemove", function(mouseMoveEvent) {
                        text.x = mouseMoveEvent.stageX|0;
                        text.y = mouseMoveEvent.stageY|0;
                        stage.update();
                    });
                    mouseDownEvent.addEventListener("mouseup", function(mouseUpEvent) {
                        var obj = {"text" : text.text}, upX = mouseUpEvent.stageX|0, upY = mouseUpEvent.stageY|0;
                        text.x = upX;
                        text.y = upY;
                        text.alpha = 1;
                        stage.update();
                        // update tategaki json
                        if (upX >= 1) {
                            obj.x = upX;
                        }
                        if (upY >= 1) {
                            obj.y = upY;
                        }
                        if (size !== "30") {
                            obj.size = size;
                        }
                        if (color !== "#000000") {
                            obj.color = color;
                        }
                        updateJson({"tategaki" : obj});
                    });
                }
            });
        },
        "publishSpuitEvents" : function() {
            stage.removeAllEventListeners();
            stage.addEventListener("mousedown", function(e) {
                var imgData = stage.canvas.getContext("2d").getImageData(e.stageX|0, e.stageY|0, 1, 1).data,
                    fontColor = "#000",
                    pointColor = (imgData[0].toString(16) + imgData[1].toString(16) + imgData[2].toString(16)).toUpperCase();
                if (imgData[0] < 128 || imgData[1] < 128 || imgData[2] < 128) {
                    fontColor = "#fff";
                }
                $colorPicker1.val(pointColor);
                $colorPicker1.css({
                    "background-color" : "#" + pointColor,
                    "color" : fontColor
                });
            });
        },
        "undo" : function() {
            if (jsonObjHistory.length > 0) {
                clear();
                stage.addChild(overlay);
                stage.update();
                jsonObjHistory.pop();
                jsonObj = jsonObjHistory[jsonObjHistory.length - 1] || {};
                drawFromJson(jsonObj);
                updateHtml(jsonObj);
            }
        }
    };
};
