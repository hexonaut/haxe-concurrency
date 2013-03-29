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

#if neko
import neko.vm.Mutex;
#elseif cpp
import cpp.vm.Mutex;
#end

/**
 * A simple wrapper for using the IntHash. Access is thread safe.
 * 
 * @author Sam MacPherson
 */

class ConcurrentIntHash<T> {
	
	var lock:Mutex;
	var hash:IntHash<T>;

	public function new () {
		lock = new Mutex();
		hash = new IntHash<T>();
	}
	
	public inline function exists (key:Int):Bool {
		lock.acquire();
		var result = hash.exists(key);
		lock.release();
		return result;
	}
	
	public inline function get (key:Int):Null<T> {
		lock.acquire();
		var result = hash.get(key);
		lock.release();
		return result;
	}
	
	public inline function iterator ():Iterator<T> {
		var arr = new Array<T>();
		lock.acquire();
		for (i in hash.iterator()) {
			arr.push(i);
		}
		lock.release();
		return arr.iterator();
	}
	
	public inline function keys ():Iterator<Int> {
		var arr = new Array<Int>();
		lock.acquire();
		for (i in hash.keys()) {
			arr.push(i);
		}
		lock.release();
		return arr.iterator();
	}
	
	public inline function remove (key:Int):Bool {
		lock.acquire();
		var result = hash.remove(key);
		lock.release();
		return result;
	}
	
	public inline function set (key:Int, val:T):Void {
		lock.acquire();
		hash.set(key, val);
		lock.release();
	}
	
	public inline function toString ():String {
		lock.acquire();
		var result = hash.toString();
		lock.release();
		return result;
	}
	
	public inline function setIfNotExists (key:Int, val:T):T {
		lock.acquire();
		var oldval = hash.get(key);
		if (oldval == null) {
			hash.set(key, val);
			oldval = val;
		}
		lock.release();
		return oldval;
	}
	
	public inline function getAndRemove (key:Int):Null<T> {
		lock.acquire();
		var result = hash.get(key);
		hash.remove(key);
		lock.release();
		return result;
	}
	
}