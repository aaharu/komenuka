/*!
* Text
* Visit http://createjs.com/ for documentation, updates and examples.
*
* Copyright (c) 2010 gskinner.com, inc.
* 
* Permission is hereby granted, free of charge, to any person
* obtaining a copy of this software and associated documentation
* files (the "Software"), to deal in the Software without
* restriction, including without limitation the rights to use,
* copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the
* Software is furnished to do so, subject to the following
* conditions:
* 
* The above copyright notice and this permission notice shall be
* included in all copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
* OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
* NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
* HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
* OTHER DEALINGS IN THE SOFTWARE.
*/

// namespace:
this.createjs = this.createjs||{};

(function() {

var TextEx = function(text, font, color) {
  this.initialize(text, font, color);
}
var p = TextEx.prototype = new createjs.Text();
// public properties:
	/**
	 * Indicates the text direction. Any of "tb" or "rl". Default is "tb".
	 * @property blockProgression
	 * @type String
	 */
	p.blockProgression = "tb";

	p.toString = function() {
		return "[TextEx (text="+  (this.text.length > 20 ? this.text.substr(0, 17)+"..." : this.text) +", blockProgression="+this.blockProgression+")]";
	}
	
	/** 
	 * @method _drawTextLine
	 * @param {CanvasRenderingContext2D} ctx
	 * @param {String} text
	 * @param {Number} y
	 * @protected 
	 **/
	p._drawTextLine = function(ctx, text, y) {
		// Chrome 17 will fail to draw the text if the last param is included but null, so we feed it a large value instead:
		if (this.blockProgression === "rl") {
			this._drawVerticalTextLine(ctx, text, y);
		} else {
			if (this.outline) { ctx.strokeText(text, 0, y, this.maxWidth||0xFFFF); }
			else { ctx.fillText(text, 0, y, this.maxWidth||0xFFFF); }
		}
	}

	p._drawVerticalTextLine = function(ctx, text, y) {
		var i, l = text.length, lineHeight = this.lineHeight||this.getMeasuredLineHeight();
		if (this.outline) {
			for (i=0; i<l; ++i) {
				this._updateMatrix(ctx, this._getCharType(text.charAt(i)), -y, i*lineHeight, ctx.measureText(text.charAt(i)).width, lineHeight);
				ctx.strokeText(text.charAt(i), -y, i*lineHeight, this.maxWidth||0xFFFF);
			}
		} else {
			for (i=0; i<l; ++i) {
				this._updateMatrix(ctx, this._getCharType(text.charAt(i)), -y, i*lineHeight, ctx.measureText(text.charAt(i)).width, lineHeight);
				ctx.fillText(text.charAt(i), -y, i*lineHeight, this.maxWidth||0xFFFF);
			}
		}
	}

	p._updateMatrix = function(ctx, type, x, y, w, h) {
		var matrix = this.getMatrix();
		matrix.appendMatrix(this._getVerticalTextMatrix(type, x, y, w, h));
		ctx.setTransform(matrix.a, matrix.b, matrix.c, matrix.d, matrix.tx, matrix.ty);
	}

	p._getCharType = function(c) {
		if (c === "\u30FC" || c === "\u301C" || c === "\uFF5E" || c === "\u2026" || c === "\uFF1D") {
			return "long";
		} else if (c === "\u3001" || c === "\uFF0C" || c === "\u3002" || c === "\uFF0E") {
			return "punctuation";
		} else if (/^[\u3041\u3043\u3045\u3047\u3049\u3083\u3085\u3087\u3063\u30A1\u30A3\u30A5\u30A7\u30A9\u30E3\u30E5\u30E7\u30C3]$/.test(c)) {
			return "small";
		} else if (/^[\u3009\u300B\u300D\u300F\u3011\u3015\u3017\u3019\uFF09\uFF5D\uFF60\u3008\u300A\u300C\u300E\u3010\u3014\u3016\u3018\uFF08\uFF5B\uFF5F\uFF1C\uFF1E\u201C\u201D\u2018\u2019]$/.test(c)) {
			return "parentheses";
		} else if (c === '"' || c === "'" || c === '-' || c === '/' || c === ':' || c === ';' || c === '<' || c === '=' || c === '>' || c === '[' || c === ']' || c === '\\' || c === ']' || c === '{' || c === '|' || c === '}') {
			return "ascii";
		}
		return "";
	}

	p._getVerticalTextMatrix = function(type, x, y, w, h) {
		switch (type) {
			case "long":
				return this._calculateMatrix(1, -1, 270, -x + y + w/2, x - y - h/2);
				break;
			case "punctuation":
				return this._calculateMatrix(1, 1, 0, 0.625 * w, -0.625 * h);
				break;
			case "small":
				return this._calculateMatrix(1, 1, 0, 0.125 * w, -0.125 * h);
				break;
			case "parentheses":
				return this._calculateMatrix(1, 1, 90, -x + y + h/2, -x - y - w/2);
				break;
			case "ascii":
				return this._calculateMatrix(1, 1, 90, -x + y + h/2, x - y - h/2);
				break;
			default:
				return new createjs.Matrix2D(1, 0, 0, 1, 0, 0);
				break;
		}
	}

	p._calculateMatrix = function(sx, sy, deg, dx, dy) {
		var rad = deg * Math.PI / 180;
		var cos = Math.cos(rad);
		var sin = Math.sin(rad);
		return new createjs.Matrix2D(sx * cos, sy * sin, -sx * sin, sy * cos, sx * (cos * dx - sin * dy), sy * (sin * dx + cos * dy));
	}

createjs.TextEx = TextEx;
}());
