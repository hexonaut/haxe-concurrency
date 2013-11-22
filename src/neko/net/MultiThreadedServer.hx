/****
* Copyright (C) 2013 Sam MacPherson
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
****/

package neko.net;

import cad.Lock;
import cad.Mutex;
import cad.Thread;
import haxe.io.Bytes;
import haxe.io.Eof;
import haxe.io.Error;
import sys.net.Host;
import sys.net.Socket;

/**
 * An x worker thread, y io thread multithreaded server for server applications with neko.
 * The server behaves as if each client has their own dedicate thread, but in reality the server is switching between threads.
 * Application logic must be thread sensitive. A periodic timer is also included for convenience.
 * 
 * @author Sam MacPherson
 */

private typedef ClientData<Client> = {
	sock:Socket,
	data:Client,
	buf:Bytes,
	bufbytes:Int,
	workerId:Int,
	disconnecting:Bool
};

class MultiThreadedServer < Client, Message > {
	
	static inline var ACTION_DISCONNECT:Int = 0;
	static inline var ACTION_READY:Int = 1;
	
	public var numListen:Int;
	public var timerDelay:Float;
	public var selectTimeout:Float;
	public var defaultBufSize:Int;
	public var maxBufSize:Int;
	public var numIoThreads:Int;
	public var numWorkerThreads:Int;
	
	//Immutable objects
	var serv:Socket;
	var timer:Thread;
	var ioThreads:Array<Thread>;
	var workerThreads:Array<Thread>;
	var mainThread:Thread;
	
	//Mutable objects
	var clients:Array<Socket>;
	var running:Bool;
	var nextWorkerId:Int;

	public function new () {
		//Can override defaults before calling run()
		numListen = 10;
		timerDelay = 1;
		selectTimeout = 1;
		defaultBufSize = 128;
		maxBufSize = 8192;
		numIoThreads = 4;
		numWorkerThreads = 10;
		nextWorkerId = 0;
		running = true;
		clients = new Array<Socket>();
		ioThreads = new Array<Thread>();
		workerThreads = new Array<Thread>();
	}
	
	public function shutdown ():Void {
		//Signal threads to shutdown
		running = false;
		
		//Force the worker threads to wake up so they will see the shutdown signal
		for (i in 0 ... ioThreads.length) doIoWork(function ():Void { });
		for (i in 0 ... workerThreads.length) workerThreads[i].sendMessage(function ():Void { });
	}
	
	public function disconnectClient (sock:Socket):Void {
		mainThread.sendMessage({a:ACTION_DISCONNECT, s:sock});
	}
	
	public function run (host:Host, port:Int):Void {
		//Main start point
		mainThread = Thread.current();
		serv = new Socket();
		serv.bind(host, port);
		serv.listen(numListen);
		clients.push(serv);
		timer = Thread.create(runTimer);
		for (i in 0 ... numIoThreads) {
			ioThreads.push(Thread.create(callback(runWorker, "ioworker-")));
		}
		for (i in 0 ... numWorkerThreads) {
			workerThreads.push(Thread.create(callback(runWorker, "appworker-")));
		}
		
		while (running) {
			var readySocks = Socket.select(clients, null, null, selectTimeout);
			for (i in readySocks.read) {
				//Check if this is the server socket -- if so then accept new connection
				var cl:ClientData<Client> = untyped i.__client;
				if (cl == null) {
					var sock:Socket = null;
					try {
						var sock = serv.accept();
						sock.setBlocking(true);
						
						cl = { sock:sock, data:null, buf:Bytes.alloc(defaultBufSize), bufbytes:0, workerId:nextWorkerId++, disconnecting:false };
						if (nextWorkerId >= numWorkerThreads) nextWorkerId = 0;
						
						untyped sock.__client = cl;
					
						cl.data = clientConnected(sock);
						
						clients.push(sock);
					} catch (e:Dynamic) {
						doException(e);
						try { if (sock != null) sock.close(); } catch (e:Dynamic) { };
					}
					
					//Read initial data
					//doIoWork(callback(ioRead, sock));
				} else {
					//Otherwise this is regular socket read from client
					//Remove client from list so we dont keep adding read work for the same client
					clients.remove(i);
					doIoWork(callback(ioRead, i));
				}
			}
			//for (i in readySocks.write) {
			//	doIoWork(callback(ioWrite, i));
			//}
			//for (i in readySocks.others) {
			//	doIoWork(callback(ioException, i));
			//}
			
			//Do pending work
			var msg:Dynamic = Thread.readMessage(false);
			while (msg != null) {
				switch (msg.a) {
					case ACTION_READY:
						//Check to make sure client is not disconnected
						if (!untyped msg.s.__client.disconnecting) clients.push(msg.s);
					case ACTION_DISCONNECT:
						var cl:ClientData<Client> = untyped msg.s.__client;
						if (!cl.disconnecting) {
							//Set socket client disconnecting attribute to true to mark the user as disconnecting
							cl.disconnecting = true;
							doApplicationWork(msg.s, callback(clientDisconnected, cl.data));
							clients.remove(msg.s);
							try {
								msg.s.close();
							} catch (e:Dynamic) {
							}
						}
				}
				msg = Thread.readMessage(false);
			}
		}
	}
	
	function ioRead (sock:Socket):Void {
		var cl:ClientData<Client> = untyped sock.__client;
		
		try {
			//Check if need to increase buffer size
			var buflen = cl.buf.length;
			if (cl.bufbytes == buflen) {
				var nsize = buflen * 2;
				if (nsize > maxBufSize) {
					if (buflen == maxBufSize) throw "Max buffer size reached";
					nsize = maxBufSize;
				}
				var buf2 = Bytes.alloc(nsize);
				buf2.blit(0, cl.buf, 0, buflen);
				buflen = nsize;
				cl.buf = buf2;
			}
			
			//Read from socket
			var nbytes = cl.sock.input.readBytes(cl.buf, cl.bufbytes, buflen - cl.bufbytes);
			cl.bufbytes += nbytes;
			
			//Process data
			var pos = 0;
			while (cl.bufbytes > 0) {
				var m = processClientMessage(cl.data, cl.buf, pos, cl.bufbytes);
				if (m == null) break;
				pos += m.bytes;
				cl.bufbytes -= m.bytes;
				
				//Send client message
				doApplicationWork(sock, callback(doClientMessage, cl, m.msg));
			}
			if (pos > 0) cl.buf.blit(0, cl.buf, pos, cl.bufbytes);
			
			//We have read the socket data -- notify main thread that client is ready to accept more
			mainThread.sendMessage({a:ACTION_READY, s:sock});
		} catch (e:Error) {
			mainThread.sendMessage({a:ACTION_READY, s:sock});
			disconnectClient(cl.sock);
		} catch (e:Dynamic) {
			if (!Std.is(e, Eof)) doException(e);
			mainThread.sendMessage({a:ACTION_READY, s:sock});
			disconnectClient(cl.sock);
		}
	}
	
	function ioWrite (sock:Socket, msg:String):Void {
		try {
			sock.write(msg);
		} catch (e:Dynamic) {
			//Error writing data -- disconnect client
			disconnectClient(sock);
		}
	}
	
	/*function ioException (sock:Socket):Void {
		#if debug
		trace("GOT EXCEPTION");
		#end
		if (sock != serv) disconnectClient(sock);
	}*/
	
	function doIoWork (f:Void -> Void):Void {
		ioThreads[Std.int(Math.random() * ioThreads.length)].sendMessage(f);
	}
	
	function doApplicationWork (sock:Socket, f:Void -> Void):Void {
		//Need to use constant per user workerId to make sure messages are processed sequentially
		workerThreads[untyped sock.__client.workerId].sendMessage(f);
	}
	
	function runWorker (prefix:String):Void {
		#if cad
		//Name the threads if we are using the debugger
		var t = Thread.current();
		t.name = prefix + t.id;
		#end
		
		//For both io and application workers
		while (running) {
			var f:Void->Void = Thread.readMessage(true);
			try {
				f();
			} catch (e:Dynamic) {
				doException(e);
			}
		}
	}
	
	function runTimer ():Void {
		#if cad
		//Name the thread if we are using the debugger
		Thread.current().name = "update";
		#end
		
		var l = new Lock();
		while (running) {
			l.wait(timerDelay);
			update();
		}
	}
	
	function doException (e:Dynamic):Void {
		try {
			exception(e);
		} catch (e:Dynamic) {
		}
	}
	
	function doClientMessage (cl:ClientData<Client>, msg:Message):Void {
		try {
			clientMessage(cl.data, msg);
		} catch (e:Dynamic) {
			doException(e);
		}
	}
	
	public function write (sock:Socket, msg:String):Void {
		doIoWork(callback(ioWrite, sock, msg));
	}
	
	/**
	 * Customize these functions.
	 */
	
	public function clientConnected (sock:Socket):Client {
		return null;
	}
	
	public function clientDisconnected (cl:Client):Void {
	}
	
	public function processClientMessage (cl:Client, buf:Bytes, bufpos:Int, buflen:Int):{ bytes:Int, msg:Message } {
		return null;
	}
	
	public function clientMessage (cl:Client, msg:Message):Void {
	}
	
	public function update ():Void {
	}
	
	public function exception (e:Dynamic):Void {
	}
}