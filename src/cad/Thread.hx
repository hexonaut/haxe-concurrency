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

import haxe.concurrent.AtomicInteger;
import haxe.concurrent.ConcurrentMap;
import haxe.CallStack;
import sys.net.Socket;
#if neko
import neko.vm.Tls;
typedef SysThread = neko.vm.Thread;
#elseif cpp
import cpp.vm.Tls;
typedef SysThread = cpp.vm.Thread;
#else
"Not supported on this platform.";
#end

/**
 * Provides additional debugger information.
 * 
 * @author Sam MacPherson
 */
#if cad
enum ThreadState {
	Running;
	Waiting;
	Sleeping;
	Terminated;
	Exception(error:Dynamic);
}

class Thread {
	
	static var ID:AtomicInteger;
	static var THREADS:ConcurrentMap<Int, Thread>;
	static var CURRENT:Tls<Thread>;
	
	public var id(default, null):Int;
	public var name:String;
	public var state(default, null):ThreadState;
	public var stack(default, null):Null<Array<StackItem>>;
	
	var t:SysThread;

	function new (callb:Void->Void) {
		id = ID.getAndIncrement();
		name = "thread-" + id;
		state = Running;
		THREADS.set(id, this);
		t = SysThread.create(threadStart.bind(callb));
	}
	
	function threadStart (callb:Void->Void):Void {
		CURRENT.value = this;
		try {
			callb();
			setState(Terminated);
		} catch (e:Dynamic) {
			setState(Exception(e));
		}
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
	
	public static function readMessage (block:Bool):Dynamic {
		setState(Waiting);
		var msg = SysThread.readMessage(block);
		setState(Running);
		return msg;
	}
	
	public static function setState (state:ThreadState):Void {
		var t = current();
		switch (state) {
			case Waiting, Sleeping:
				t.stack = CallStack.callStack();
				//Drop all the extra callstack info from CAD -- the calling location is what's important
				t.stack.shift();
				t.stack.shift();
			case Exception(e):
				t.stack = CallStack.exceptionStack();
			case Running, Terminated:
				t.stack = null;
		}
		t.state = state;
	}
	
	public static function __init__ ():Void {
		ID = new AtomicInteger();
		THREADS = new ConcurrentMap<Int, Thread>();
		CURRENT = new Tls<Thread>();
		
		//Override default Sys.sleep method to include debugger info
		var _sleep = Sys.sleep;
		var sleep = function (seconds:Float):Void {
			setState(Sleeping);
			_sleep(seconds);
			setState(Running);
		}
		Reflect.setField(Sys, "sleep", sleep);
		
		//Override default Socket.select method to include debugger info
		var _select = Socket.select;
		var select = function (read:Array<Socket>, write:Array<Socket>, others:Array<Socket>, ?timeout:Float):{ read:Array<Socket>, write:Array<Socket>, others:Array<Socket> } {
			setState(Waiting);
			var result = _select(read, write, others, timeout);
			setState(Running);
			return result;
		}
		Reflect.setField(Socket, "select", select);
		
		//Wrap main thread
		var mainThread = Type.createEmptyInstance(Thread);
		CURRENT.value = mainThread;
		mainThread.t = SysThread.current();
		mainThread.id = ID.getAndIncrement();
		mainThread.name = "main";
		mainThread.state = Running;
		THREADS.set(mainThread.id, mainThread);
	}
	
}
#else
typedef Thread = SysThread;
#end