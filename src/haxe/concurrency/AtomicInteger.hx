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

import cad.Mutex;

/**
 * A wrapper for an integer which is thread safe.
 * 
 * @author Sam MacPherson
 */
class AtomicInteger {
	
	var lock:Mutex;
	var val:Int;

	public function new (?val:Int = 0) {
		lock = new Mutex();
		this.val = val;
	}
	
	public function get ():Int {
		lock.acquire();
		var result = val;
		lock.release();
		return result;
	}
	
	public function set (val:Int):Void {
		lock.acquire();
		this.val = val;
		lock.release();
	}
	
	public function incrementAndGet ():Int {
		lock.acquire();
		var result = ++val;
		lock.release();
		return result;
	}
	
	public function getAndIncrement ():Int {
		lock.acquire();
		var result = val++;
		lock.release();
		return result;
	}
	
}