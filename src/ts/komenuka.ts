/*!
 * komenuka
 * Copyright (c) 2013 aaharu
 * https://raw.github.com/aaharu/komenuka/master/LICENSE
 */

/// <reference path="../../submodule/DefinitelyTyped/jquery/jquery.d.ts" />
/// <reference path="../../submodule/DefinitelyTyped/easeljs/easeljs.d.ts" />

module komenuka {
    export class Canvas {
        private _stage: createjs.Stage;
        private _$colorPicker1: JQuery;
        private _$colorPicker2: JQuery;
        private _shape: createjs.Shape;
        private _overlay: createjs.Shape;
        private _jsonObj: Object;
        private _image: createjs.Bitmap;
        private _jsonObjHistory: Object[];

        constructor(stage: createjs.Stage, $colorPicker1: JQuery, $colorPicker2: JQuery) {
            this._stage = stage;
            this._$colorPicker1 = $colorPicker1;
            this._$colorPicker2 = $colorPicker2;
        }

        public init(bmp: createjs.Bitmap) {
            this._image = bmp;
            this._stage.removeAllEventListeners();
            this._stage.canvas.width = bmp.image.width;
            this._stage.canvas.height = bmp.image.height;
            this.clear();
            this._overlay = new createjs.Shape();
            this._overlay.alpha = 0.7;
            this._stage.addChild(this._overlay);
            this._stage.update();
            this._jsonObj = {};
            this._jsonObjHistory = [];
        }

        public publishRectangleEvents() {
            this._stage.removeAllEventListeners();
            this._stage.on("stagemousedown", (mouseDownEvent) => {
                var startX = (<createjs.MouseEvent>mouseDownEvent).stageX | 0, startY = (<createjs.MouseEvent>mouseDownEvent).stageY | 0;
                this._stage.on("stagemousemove", (mouseMoveEvent) => {
                    var moveX = (<createjs.MouseEvent>mouseMoveEvent).stageX | 0, moveY = (<createjs.MouseEvent>mouseMoveEvent).stageY | 0;
                    this._overlay.graphics.c().f("#" + this._$colorPicker1.val()).r(startX, startY, moveX - startX, moveY - startY).ef();
                    this._stage.update();
                });
                this._stage.on("stagemouseup", (mouseUpEvent) => {
                    this._stage.removeAllEventListeners("stagemousemove");
                    this._stage.removeAllEventListeners("stagemouseup");
                    var x1, x2, y1, y2, obj = {}, color = "#" + this._$colorPicker1.val(), upX = (<createjs.MouseEvent>mouseUpEvent).stageX | 0, upY = (<createjs.MouseEvent>mouseUpEvent).stageY | 0;
                    this._overlay.graphics.c();
                    this._shape.graphics.f(color).r(startX, startY, upX - startX, upY - startY).ef();
                    this._stage.update();
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
                        obj["x1"] = x1;
                    }
                    if (x2 !== 0) {
                        obj["x2"] = x2;
                    }
                    if (y1 !== 0) {
                        obj["y1"] = y1;
                    }
                    if (y2 !== 0) {
                        obj["y2"] = y2;
                    }
                    if (color !== "#FFFFFF") {
                        obj["color"] = color;
                    }
                    this.updateJson({ "rectangle": obj });
                });
            });
        }

        public publishAnnotateEvents(jqStr, jqSize) {
            this._stage.removeAllEventListeners();
            this._stage.on("stagemousedown", (mouseDownEvent) => {
                if (jqStr.val()) {
                    var size = jqSize.val(),
                        color = "#" + this._$colorPicker2.val(),
                        text = new createjs.Text(jqStr.val(), size + "px Arial", color);
                    text.x = (<createjs.MouseEvent>mouseDownEvent).stageX | 0;
                    text.y = (<createjs.MouseEvent>mouseDownEvent).stageY | 0;
                    text.alpha = 0.6;
                    this._stage.addChild(text);
                    this._stage.update();
                    this._stage.on("stagemousemove", (mouseMoveEvent) => {
                        text.x = (<createjs.MouseEvent>mouseMoveEvent).stageX | 0;
                        text.y = (<createjs.MouseEvent>mouseMoveEvent).stageY | 0;
                        this._stage.update();
                    });
                    this._stage.on("stagemouseup", (mouseUpEvent) => {
                        this._stage.removeAllEventListeners("stagemousemove");
                        this._stage.removeAllEventListeners("stagemouseup");
                        var obj = { "text": text.text }, upX = (<createjs.MouseEvent>mouseUpEvent).stageX | 0, upY = (<createjs.MouseEvent>mouseUpEvent).stageY | 0;
                        text.x = upX;
                        text.y = upY;
                        text.alpha = 1;
                        this._stage.update();
                        // update annotate json
                        if (upX >= 1) {
                            obj["x"] = upX;
                        }
                        if (upY >= 1) {
                            obj["y"] = upY;
                        }
                        if (size !== "30") {
                            obj["size"] = size;
                        }
                        if (color !== "#000000") {
                            obj["color"] = color;
                        }
                        this.updateJson({ "annotate": obj });
                    });
                }
            });
        }

        public publishTategakiEvents(jqStr, jqSize) {
            this._stage.removeAllEventListeners();
            this._stage.on("stagemousedown", (mouseDownEvent) => {
                if (jqStr.val()) {
                    var size = jqSize.val(),
                        color = "#" + this._$colorPicker2.val(),
                        text = new createjs.Text(jqStr.val(), size + "px Arial", color);
                    text.x = (<createjs.MouseEvent>mouseDownEvent).stageX | 0;
                    text.y = (<createjs.MouseEvent>mouseDownEvent).stageY | 0;
                    text.alpha = 0.6;
                    (<any>text).blockProgression = "rl";
                    text.textAlign = "center";
                    this._stage.addChild(text);
                    this._stage.update();
                    this._stage.on("stagemousemove", (mouseMoveEvent) => {
                        text.x = (<createjs.MouseEvent>mouseMoveEvent).stageX | 0;
                        text.y = (<createjs.MouseEvent>mouseMoveEvent).stageY | 0;
                        this._stage.update();
                    });
                    this._stage.on("stagemouseup", (mouseUpEvent) => {
                        this._stage.removeAllEventListeners("stagemousemove");
                        this._stage.removeAllEventListeners("stagemouseup");
                        var obj = { "text": text.text }, upX = (<createjs.MouseEvent>mouseUpEvent).stageX | 0, upY = (<createjs.MouseEvent>mouseUpEvent).stageY | 0;
                        text.x = upX;
                        text.y = upY;
                        text.alpha = 1;
                        this._stage.update();
                        // update tategaki json
                        if (upX >= 1) {
                            obj["x"] = upX;
                        }
                        if (upY >= 1) {
                            obj["y"] = upY;
                        }
                        if (size !== "30") {
                            obj["size"] = size;
                        }
                        if (color !== "#000000") {
                            obj["color"] = color;
                        }
                        this.updateJson({ "tategaki": obj });
                    });
                }
            });
        }

        public publishSpuitEvents() {
            this._stage.removeAllEventListeners();
            this._stage.on("stagemousedown", (e) => {
                var imgData = this._stage.canvas.getContext("2d").getImageData((<createjs.MouseEvent>e).stageX | 0, (<createjs.MouseEvent>e).stageY | 0, 1, 1).data,
                    fontColor = "#000",
                    pointColor = (imgData[0].toString(16) + imgData[1].toString(16) + imgData[2].toString(16)).toUpperCase();
                if (imgData[0] < 128 || imgData[1] < 128 || imgData[2] < 128) {
                    fontColor = "#fff";
                }
                this._$colorPicker1.val(pointColor);
                this._$colorPicker1.css({
                    "background-color": "#" + pointColor,
                    "color": fontColor
                });
            });
        }

        public undo() {
            if (this._jsonObjHistory.length > 0) {
                this.clear();
                this._stage.addChild(this._overlay);
                this._stage.update();
                this._jsonObjHistory.pop();
                this._jsonObj = this._jsonObjHistory[this._jsonObjHistory.length - 1] || {};
                this.drawFromJson(this._jsonObj);
                this.updateHtml(this._jsonObj);
            }
        }

        private clear() {
            this._stage.removeAllChildren();
            this._stage.addChild(this._image);
            this._shape = new createjs.Shape();
            this._stage.addChild(this._shape);
        }

        private updateJson(obj) {
            var k;
            //Objectの結合
            for (k in obj) {
                if (obj.hasOwnProperty(k)) {
                    if (this._jsonObj[k] === undefined) {
                        this._jsonObj[k] = obj[k];
                    } else if (this._jsonObj[k] instanceof Array) {
                        this._jsonObj[k][(this._jsonObj[k]).length] = obj[k];
                    } else {
                        this._jsonObj[k] = [this._jsonObj[k], obj[k]];
                    }
                }
            }
            //add history
            this._jsonObjHistory[this._jsonObjHistory.length] = $.extend(true, {}, this._jsonObj);
            this.updateHtml(this._jsonObj);
        }

        private updateHtml(obj) {
            $(this._stage.canvas).trigger("komenuka:update", obj);
        }

        private drawFromJson(json) {
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
                                this._shape.graphics.f(color).r(x1, y1, x2 - x1, y2 - y1).ef();
                                this._stage.update();
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
                                this._stage.addChild(text);
                                this._stage.update();
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
                                this._stage.addChild(text);
                                this._stage.update();
                            }
                            break;
                    }
                }
            }
        }
    }
}
