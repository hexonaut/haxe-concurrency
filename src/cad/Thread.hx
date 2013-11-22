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
import haxe.concurrency.AtomicInteger;
import haxe.concurrency.ConcurrentIntHash;
#if neko
typedef SysThread = neko.vm.Thread;
import neko.vm.Tls;
#elseif cpp
typedef SysThread = cpp.vm.Thread;
import cpp.vm.Tls;
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
enum ThreadState {
	Running;
	Waiting(line:String);
	Sleeping;
	Terminated;
}

class Thread {
	
	#if !macro
	static var ID:AtomicInteger;
	static var THREADS:ConcurrentIntHash<Thread>;
	static var CURRENT:Tls<Thread>;
	
	public var id(default, null):Int;
	public var name:String;
	public var state:ThreadState;
	
	var t:SysThread;

	function new (callb:Void->Void) {
		id = ID.getAndIncrement();
		name = "thread-" + id;
		state = Running;
		THREADS.set(id, this);
		t = SysThread.create(callback(threadStart, callb));
	}
	
	function threadStart (callb:Void->Void):Void {
		CURRENT.value = this;
		callb();
		state = Terminated;
	}
	
	public function sendMessage (msg:Dynamic):Void {
		t.sendMessage(msg);
	}
	
	public static function current ():Thread {
		return CURRENT.value;
	}
	
	public static function create (callb:Void->Void):Thread {
		return new Thread(callb);
	}
	
	public static function _readMessage (block:Bool, ?line:String = ""):Dynamic {
		current().state = Waiting(line);
		var msg = SysThread.readMessage(block);
		current().state = Running;
		return msg;
	}
	
	public static function __init__ ():Void {
		ID = new AtomicInteger();
		THREADS = new ConcurrentIntHash<Thread>();
		CURRENT = new Tls<Thread>();
		
		//Override default sleep method to include debugger info
		var _sleep = Sys.sleep;
		var sleep = function (seconds:Float):Void {
			Thread.current().state = Sleeping;
			_sleep(seconds);
			Thread.current().state = Running;
		}
		Reflect.setField(Sys, "sleep", sleep);
		
		//Wrap main thread
		var mainThread = Type.createEmptyInstance(Thread);
		CURRENT.value = mainThread;
		mainThread.t = SysThread.current();
		mainThread.id = ID.getAndIncrement();
		mainThread.name = "main";
		mainThread.state = Running;
		THREADS.set(mainThread.id, mainThread);
	}
	#end
	
	@:macro public static function readMessage (block:Expr):Expr {
		var pos = Context.currentPos();
		return { expr:ECall({ expr:EField({ expr:EType({ expr:EConst(CIdent("cad")), pos:pos }, "Thread"), pos:pos }, "_readMessage"), pos:pos }, [block, { expr:EConst(CString(Std.string(pos))), pos:pos }]), pos:pos };
	}
	
}
#else
typedef Thread = SysThread;
#end