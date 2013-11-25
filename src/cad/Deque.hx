/****
* Copyright (C) 2013 Sam MacPherson
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
****/

package cad;

import cad.Thread;
#if neko
typedef SysDeque<T> = neko.vm.Deque<T>;
#elseif cpp
typedef SysDeque<T> = cpp.vm.Deque<T>;
#else
"Not supported on this platform.";
#end

/**
 * Provides additional debugger information.
 * 
 * @author Sam MacPherson
 */
#if cad
class Deque<T> {

	var d:SysDeque<T>;

	public function new () {
		d = new SysDeque<T>();
	}
	
	public function add (i:T):Void {
		d.add(i);
	}
	
	public function pop (block:Bool):T {
		Thread.setState(Waiting);
		var result = d.pop(block);
		Thread.setState(Running);
		return result;
	}
	
	public function push (i:T):Void {
		d.push(i);
	}
	
}
#else
typedef Deque<T> = SysDeque<T>;
#end