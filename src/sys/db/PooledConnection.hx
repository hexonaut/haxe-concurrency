/****
* Copyright (C) 2013 Sam MacPherson
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
****/







package sys.db;

#if neko
import neko.vm.Mutex;
#elseif cpp
import cpp.vm.Mutex;
#end

typedef ConnectionWrapper = {
	ready:Bool,
	conn:Connection
}

/**
 * A thread-safe abstraction layer for accessing databases. Connections are pooled and automatically restarted when a failure occurs.
 * Requests made during a failure will be automagically retried. Set maxRetries to 0 to handle failures manually.
 * 
 * @author Sam MacPherson
 */

class PooledConnection implements Connection {
	
	var conns:Array<ConnectionWrapper>;
	var createNewConnection:Void->Connection;
	var maxRetries:Int;
	var lock:Mutex;
	var nextIndex:Int;
	var closed:Bool;

	public function new (connectionFactory:Void->Connection, ?poolSize:Int = 1, ?maxRetries:Int = 5) {
		conns = new Array<ConnectionWrapper>();
		createNewConnection = connectionFactory;
		this.maxRetries = maxRetries;
		lock = new Mutex();
		nextIndex = 0;
		closed = false;
		
		for (i in 0 ... poolSize) {
			var connWrapper = { ready:true, conn:null };
			expRetry(function ():Void { try { connWrapper.conn = createNewConnection(); } catch (e:Dynamic) { connWrapper.conn.close(); throw e; } } );
			untyped connWrapper.conn.__wrapper = connWrapper;
			conns.push(connWrapper);
		}
	}
	
	function expRetry (f:Void->Void):Void {
		var delay = 1;
		while (true) {
			try {
				f();
				return;
			} catch (e:Dynamic) {
				if (delay >= (1 << maxRetries)) throw "Operation failed: " + e;
				
				Sys.sleep(delay);
				delay = delay << 1;
			}
		}
		return null;
	}
	
	function getAvailableConnection ():Connection {
		var conn:Connection = null;
		lock.acquire();
		while (conn == null) {
			if (closed) throw "Already closed.";
			
			for (i in nextIndex ... nextIndex + conns.length) {
				var connWrapper = conns[i % conns.length];
				if (connWrapper.ready) {
					conn = connWrapper.conn;
					connWrapper.ready = false;
				}
			}
			Sys.sleep(0.1);	//Sleep a bit
		}
		lock.release();
		return conn;
	}
	
	function releaseConnection (c:Connection):Void {
		lock.acquire();
		if (closed) {
			try {
				c.close();
			} catch (e:Dynamic) {
			}
		} else {
			untyped c.__wrapper.ready = true;
		}
		lock.release();
	}
	
	function renewConnection (oldConn:Connection):Connection {
		var connWrapper:ConnectionWrapper = untyped oldConn.__wrapper;
		try {
			//Not really sure what the error was so just close the old connection and create a new one regardless
			oldConn.close();
		} catch (e:Dynamic) {
		}
		
		var conn:Connection = null;
		try {
			conn = createNewConnection();
		} catch (e:Dynamic) {
			conn.close();
			throw e;
		}
		//Update wrapper
		connWrapper.conn = conn;
		return conn;
	}
	
	function doQuery (method:String, args:Array<Dynamic>):Dynamic {
		var conn = getAvailableConnection();
		var result:Dynamic;
		expRetry(function ():Void {
			try {
				result = Reflect.callMethod(conn, Reflect.field(conn, method), args);
			} catch (e:Dynamic) {
				conn = renewConnection(conn);
				throw e;
			}
		});
		releaseConnection(conn);
		return result;
	}
	
	public function request (s:String):ResultSet {
		if (closed) throw "Already closed";
		
		return doQuery("request", [s]);
	}
	
	public function close ():Void {
		if (closed) throw "Already closed";
		
		lock.acquire();
		
		closed = true;
		
		//Immediately close any ready connections
		for (i in conns) {
			if (i.ready) {
				try {
					i.conn.close();
				} catch (e:Dynamic) {
				}
			}
		}
		lock.release();
	}
	
	public function escape (s:String):String {
		if (closed) throw "Already closed";
		
		return doQuery("escape", [s]);
	}
	
	public function quote (s:String):String {
		if (closed) throw "Already closed";
		
		return doQuery("quote", [s]);
	}
	
	public function addValue (s:StringBuf, v:Dynamic):Void {
		if (closed) throw "Already closed";
		
		doQuery("addValue", [s, v]);
	}
	
	public function lastInsertId ():Int {
		if (closed) throw "Already closed";
		
		return doQuery("lastInsertId", []);
	}
	
	public function dbName ():String {
		if (closed) throw "Already closed";
		
		return doQuery("dbName", []);
	}
	
	public function startTransaction ():Void {
		if (closed) throw "Already closed";
		
		return doQuery("startTransaction", []);
	}
	
	public function commit ():Void {
		if (closed) throw "Already closed";
		
		return doQuery("commit", []);
	}
	
	public function rollback ():Void {
		if (closed) throw "Already closed";
		
		return doQuery("rollback", []);
	}
	
}