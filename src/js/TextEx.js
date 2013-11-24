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

(function() {
	if (typeof createjs.Text === "undefined") {
		setTimeout(argments.callee, 100);
	} else {
		var p = createjs.Text.prototype;
		/**
		 * Indicates the text direction. Any of "tb" or "rl". Default is "tb".
		 * @property blockProgression
		 * @type String
		 */
		p.blockProgression = "tb";

		/**
		 * Draws multiline text.
		 * @method _drawText
		 * @param {CanvasRenderingContext2D} ctx
		 * @protected
		 * @return {Number} The number of lines drawn.
		 **/
		p._drawText = function(ctx) {
			var paint = !!ctx;
			if (!paint) { ctx = this._getWorkingContext(); }
			var lines = String(this.text).split(/(?:\r\n|\r|\n)/);
			var lineHeight = this.lineHeight||this.getMeasuredLineHeight();
			if (this.blockProgression === "rl") lineHeight = this.font.match(/(\d+)px /)[1]; // Get font-size
			var count = 0;
			for (var i=0, l=lines.length; i<l; i++) {
				var w = ctx.measureText(lines[i]).width;
				if (this.lineWidth === null || w < this.lineWidth) {
					if (paint) { this._drawTextLine(ctx, lines[i], count*lineHeight); }
					count++;
					continue;
				}

				// split up the line
				var words = lines[i].split(/(\s)/);
				var str = words[0];
				for (var j=1, jl=words.length; j<jl; j+=2) {
					// Line needs to wrap:
					if (ctx.measureText(str + words[j] + words[j+1]).width > this.lineWidth) {
						if (paint) { this._drawTextLine(ctx, str, count*lineHeight); }
						count++;
						str = words[j+1];
					} else {
						str += words[j] + words[j+1];
					}
				}
				if (paint) { this._drawTextLine(ctx, str, count*lineHeight); } // Draw remaining text
				count++;
			}
			return count;
		};

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
		};

		/**
		 * @method _drawVerticalTextLine
		 * @param {CanvasRenderingContext2D} ctx
		 * @param {String} text
		 * @param {Number} x
		 * @protected
		 **/
		p._drawVerticalTextLine = function(ctx, text, x) {
			var i, l = text.length, lineHeight = this.lineHeight||this.getMeasuredLineHeight(), type, y = 0, w = this.font.match(/(\d+)px /)[1], h;
			if (this.outline) {
				for (i=0; i<l; ++i) {
					type = this._getCharType(text.charAt(i));
					switch (type) {
						case "long":
						case "punctuation":
						case "small":
						case "parentheses":
							h = lineHeight;
							break;
						case "rotate-ascii":
							h = ctx.measureText(text.charAt(i)).width;
							break;
						default:
							h = lineHeight;
							break;
					}
					y += h;
					this._updateMatrix(ctx, type, -x, y, w, h);
					ctx.strokeText(text.charAt(i), -x, y);
				}
			} else {
				for (i=0; i<l; ++i) {
					type = this._getCharType(text.charAt(i));
					switch (type) {
						case "long":
						case "punctuation":
						case "small":
						case "parentheses":
							h = lineHeight;
							break;
						case "rotate-ascii":
							h = ctx.measureText(text.charAt(i)).width;
							break;
						default:
							h = lineHeight;
							break;
					}
					y += h;
					this._updateMatrix(ctx, type, -x, y, w, h);
					ctx.fillText(text.charAt(i), -x, y);
				}
			}
		};

		/**
		 * @method _updateMatrix
		 * @param {CanvasRenderingContext2D} ctx
		 * @param {String} type
		 * @param {Number} x
		 * @param {Number} y
		 * @param {Number} w
		 * @param {Number} h
		 * @protected
		 **/
		p._updateMatrix = function(ctx, type, x, y, w, h) {
			var matrix = this.getMatrix();
			matrix.appendMatrix(this._getVerticalTextMatrix(type, x, y, w, h));
			ctx.setTransform(matrix.a, matrix.b, matrix.c, matrix.d, matrix.tx, matrix.ty);
		};

		/**
		 * @method _getCharType
		 * @param {String} c
		 * @return {String} The character type in vertical writing.
		 * @protected
		 **/
		p._getCharType = function(c) {
			if (/^[\u30FC\u301C\uFF5E\u2026\uFF1D]$/.test(c)) {
				return "long";
			} else if (/^[\u3001\uFF0C\u3002\uFF0E]$/.test(c)) {
				return "punctuation";
			} else if (/^[\u3041\u3043\u3045\u3047\u3049\u3083\u3085\u3087\u3063\u30A1\u30A3\u30A5\u30A7\u30A9\u30E3\u30E5\u30E7\u30C3]$/.test(c)) {
				return "small";
			} else if (/^[\u3008\u3009\u300A\u300B\u3010\u3011\u3016\u3017\uFF08\uFF09\uFF5F\uFF60\u300C\u300D\u300E\u300F\u3014\u3015\u3018\u3019\uFF5B\uFF5D\uFF1C\uFF1E\u201C\u201D\u2018\u2019]$/.test(c)) {
				return "parentheses";
			} else if (c === '"' || c === "'" || c === '-' || c === '/' || c === ':' || c === ';' || c === '<' || c === '=' || c === '>' || c === '[' || c === ']' || c === '\\' || c === '{' || c === '|' || c === '}' || c === '(' || c === ')') {
				return "rotate-ascii";
			}
			return "";
		};

		/**
		 * @method _getVerticalTextMatrix
		 * @param {String} type
		 * @param {Number} x
		 * @param {Number} y
		 * @param {Number} w
		 * @param {Number} h
		 * @return {Matrix2D}
		 * @protected
		 **/
		p._getVerticalTextMatrix = function(type, x, y, w, h) {
			switch (type) {
				case "long":
					return this._calculateMatrix(1, -1, 270, -x + y + w * 0.4, x - y - h * 0.45);
				case "punctuation":
					return this._calculateMatrix(1, 1, 0, 0.625 * w, -0.625 * h);
				case "small":
					return this._calculateMatrix(1, 1, 0, 0.15 * w, -0.15 * h);
				case "parentheses":
					return this._calculateMatrix(1, 1, 90, -x + y + w * 0.4, -x - y - h * 0.4);
				case "rotate-ascii":
					return this._calculateMatrix(1, 1, 90, -x + y + w * 0.8, -x - y - h * 1.65);
				default:
					return new createjs.Matrix2D(1, 0, 0, 1, 0, 0);
			}
		};

		/**
		 * @method _calculateMatrix
		 * @param {Number} sx
		 * @param {Number} sy
		 * @param {Number} deg
		 * @param {Number} dx
		 * @param {Number} dy
		 * @return {Matrix2D}
		 * @protected
		 **/
		p._calculateMatrix = function(sx, sy, deg, dx, dy) {
			var rad = deg * Math.PI / 180;
			var cos = Math.cos(rad);
			var sin = Math.sin(rad);
			return new createjs.Matrix2D(sx * cos, sy * sin, -sx * sin, sy * cos, sx * (cos * dx - sin * dy), sy * (sin * dx + cos * dy));
		};
	}
}());
