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
typedef SysMutex = neko.vm.Mutex;
#elseif cpp
typedef SysMutex = cpp.vm.Mutex;
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
class Mutex {
	
	#if !macro
	var m:SysMutex;

	public function new () {
		m = new SysMutex();
	}
	
	public function _acquire (?line:String = ""):Void {
		Thread.current().state = Waiting(line);
		m.acquire();
		Thread.current().state = Running;
	}
	
	public function release ():Void {
		m.release();
	}
	
	public function tryAcquire ():Bool {
		return m.tryAcquire();
	}
	#end
	
	macro public function acquire (ethis:Expr):ExprOf<Void> {
		var pos = Context.currentPos();
		return { expr:ECall({ expr:EField(ethis, "_acquire"), pos:pos }, [{ expr:EConst(CString(Std.string(pos))), pos:pos }]), pos:pos };
	}
	
}
#else
typedef Mutex = SysMutex;
#end