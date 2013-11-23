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

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#else
import cad.Thread;
#if neko
typedef SysLock = neko.vm.Lock;
#elseif cpp
typedef SysLock = cpp.vm.Lock;
#else
"Not supported on this platform.";
#end
#end

/**
 * Provides additional debugger information.
 * 
 * @author Sam MacPherson
 */
#if cad
class Lock {

	#if !macro
	var l:SysLock;

	public function new () {
		l = new SysLock();
	}
	
	public function release ():Void {
		l.release();
	}
	
	public function _wait (timeout:Float, ?line:String = ""):Bool {
		Thread.current().state = Waiting(line);
		var result = l.wait(timeout);
		Thread.current().state = Running;
		return result;
	}
	#end
	
	macro public function wait (ethis:Expr, timeout:ExprOf<Float>):ExprOf<Bool> {
		var pos = Context.currentPos();
		return { expr:ECall({ expr:EField(ethis, "_wait"), pos:pos }, [timeout, { expr:EConst(CString(Std.string(pos))), pos:pos }]), pos:pos };
	}
	
}
#else
typedef Lock = SysLock;
#end