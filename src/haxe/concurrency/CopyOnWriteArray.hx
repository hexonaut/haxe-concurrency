/****
* Copyright (C) 2013 Sam MacPherson
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
****/

package haxe.concurrency;

/**
 * A thread safe array. The array is copied completely during a write. Useful for read-heavy usage.
 * Be very careful when iterating by index as the array length can change during this.
 * It is a better idea to iterate by the default iterator and store an index variable alongside the iteration.
 * 
 * @author Sam MacPherson
 */

class CopyOnWriteArray<T> {
	
	public var length(_length, null):Int;
	
	var arr:Array<T>;

	public function new () {
		arr = new Array<T>();
	}
	
	function _length ():Int {
		return arr.length;
	}
	
	public function concat (a:CopyOnWriteArray<T>):CopyOnWriteArray<T> {
		return fromArray(arr.concat(a.arr));
	}
	
	public function copy ():CopyOnWriteArray<T> {
		return fromArray(arr.copy());
	}
	
	public function get (pos:Int):Null<T> {
		return arr[pos];
	}
	
	public function set (pos:Int, x:T):T {
		var a = arr.copy();
		a[pos] = x;
		arr = a;
		return x;
	}
	
	public function insert (pos:Int, x:T):Void {
		var a = new Array();
		var index = 0;
		for (i in arr) {
			if (index == pos) a.push(x);
			a.push(i);
			index++;
		}
		arr = a;
	}
	
	public function iterator ():Iterator<T> {
		return arr.iterator();
	}
	
	public function join (sep:String):String {
		return arr.join(sep);
	}
	
	public function pop ():Null<T> {
		var a = arr.copy();
		var e = a.pop();
		arr = a;
		return e;
	}
	
	public function push (x:T):Int {
		var a = arr.copy();
		var l = a.push(x);
		arr = a;
		return l;
	}
	
	public function remove (x:T):Bool {
		var a = arr.copy();
		var b = a.remove(x);
		arr = a;
		return b;
	}
	
	public function reverse ():Void {
		var a = arr.copy();
		a.reverse();
		arr = a;
	}
	
	public function shift ():Null<T> {
		var a = arr.copy();
		var e = a.shift();
		arr = a;
		return e;
	}
	
	public function slice (pos:Int, ?end:Int):Array<T> {
		return arr.slice(pos, end);
	}
	
	public function sort (f:T->T->Int):Void {
		var a = arr.copy();
		a.sort(f);
		arr = a;
	}
	
	public function splice (pos:Int, len:Int):Array<T> {
		return arr.splice(pos, len);
	}
	
	public function toString ():String {
		return arr.toString();
	}
	
	public function unshift (x:T):Void {
		var a = arr.copy();
		a.unshift(x);
		arr = a;
	}
	
	public inline static function fromArray<T> (a:Array<T>):CopyOnWriteArray<T> {
		var b = new CopyOnWriteArray<T>();
		b.arr = a;
		return b;
	}
	
}