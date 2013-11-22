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

import haxe.concurrency.ConcurrentIntHash;
import haxe.Json;
import sys.net.Host;
import sys.net.Socket;

/**
 * The Concurrent Application Debugger will start a daemon thread to listen on a port
 * and produce JSON output of what the system is currently doing. You need to compile
 * with the '-D cad' flag turned on.
 * 
 * @author Sam MacPherson
 */
class Debugger {
	
	var s:Socket;
	
	function new (host:Host, port:Int) {
		s = new Socket();
		s.bind(host, port);
		s.listen(1);
	}
	
	function buildState ():Dynamic {
		var state = new Array<Dynamic>();
		var threads:ConcurrentIntHash<Thread> = Reflect.field(Thread, "THREADS");
		for (i in threads) {
			state.push( { name:i.name, state:i.state } );
		}
		return state;
	}
	
	function run ():Void {
		while (true) {
			var sock = s.accept();
			s.write(Json.stringify(buildState()));
			s.close();
		}
	}
	
	public static function listen (host:Host, port:Int):Void {
		var d = new Debugger(host, port);
		var t = Thread.create(d.run);
		t.name = "cad-daemon";
	}
	
}