haxe-concurrency is a library to provide high level thread-safe data structures for all targets that support shared memory concurrency. Also included is . Supported targets are neko and c++.

Data Structures
===============

* CopyOnWriteArray - A data structure for read-heavy storage. As the name suggests, the array is copied when a modification is performed.
* ConcurrentHash/ConcurrentIntHash - Provides a Hash which is thread safe.

Performance
===========

Here are some performance tests run on a win7-64bit i7 Dell Inspiron laptop (8 CPUs) under the neko target:

Comparison to Non-Concurrent Data Structures
--------------------------------------------

* Array Write MOD 1000: 83 ns
* CopyOnWriteArray Write MOD 1000: 3487 ns
* Array Read MOD 1000: 67 ns
* CopyOnWriteArray Read MOD 1000: 130 ns
* IntHash Write: 149 ns
* ConcurrentIntHash Write: 342 ns
* IntHash Read: 66 ns
* ConcurrentIntHash Read: 236 ns

Throughput Speed Testing
------------------------

* Array Read 20M items: 1363 ms
* CopyOnWriteArray Read 20M items (2 Threads): 1431 ms
* CopyOnWriteArray Read 20M items (4 Threads): 813 ms
* CopyOnWriteArray Read 20M items (8 Threads): 597 ms
* CopyOnWriteArray Read 20M items (16 Threads): 369 ms
* CopyOnWriteArray Read 20M items (32 Threads): 182 ms

Extras
======

* neko.net.MultiThreadedServer - A fully concurrent server which is similar to neko.net.ThreadServer, except the application logic is concurrent as well.
* sys.db.PooledConnection -  A thread-safe abstraction layer for accessing databases. Connections are pooled and automatically restarted when a failure occurs.

PooledConnection Usage
----------------------

Usage is very simple. Instead of creating your sys.db.Mysql.connect() or sys.db.Sqlite.read() connections just create a new PooledConnection and pass in a factory constructor as shown below:
	
	//Create a pooled connection
	var cnx = new sys.db.PooledConnection(function ():sys.db.Connection {
		return sys.db.Mysql.connect( { host:HOST, port:PORT, user:USER, pass:PASS, socket:null, database:DATABASE } );
	}, NUM_CONNECTIONS);
	
	//Use with SPOD!
	//A point of caution - SPOD uses a global object cache by default so you will need to deal with this when using in a multithreaded application
	sys.db.Manager.cnx = cnx;

Concurrent Application Debugger
===============================

You can use the Concurrent Application Debugger (CAD) to debug concurrent applications. Included in the cad package is cad.Debugger which will listen on a port you choose and output the current state of all threads within the application. Two formats are available: Full HTML and JSON. The HTML output is nice if you want a quick/pretty display from a browser. The JSON output is nicer for custom clients.

Here is an example:

	cad.Debugger.listen(new sys.net.Host("0.0.0.0"), 9308, true);	//Last arg means use HTML output

![CAD](https://raw.github.com/Blank101/haxe-concurrency/master/example.jpg "Concurrent Application Debugger - HTML Output")

To opt-in you need to make sure all Mutex/Locks/Deques are using the wrapper classes of cad.Mutex, cad.Lock, cad.Deque. This is the only modification required to your existing code base. You then compile your code with the '-D cad' compiler flag to turn on CAD.

The nice thing about this is that when you are done and don't want the overhead of CAD anymore you can just remove the compiler flag, and cad.* typedefs to the std classes. Also the Debugger will just ignore the listen() call.