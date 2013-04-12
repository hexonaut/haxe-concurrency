package;

import haxe.concurrency.ConcurrentHash;
import haxe.concurrency.ConcurrentIntHash;
import haxe.concurrency.CopyOnWriteArray;
import massive.munit.Assert;

#if neko
import neko.vm.Mutex;
import neko.vm.Thread;
import neko.Lib;
#elseif cpp
import cpp.vm.Mutex;
import cpp.vm.Thread;
import cpp.Lib;
#end

/**
* Tests the data structures library for correctness.
*/
class DataStructuresPerformanceTesting {
	
	static var lastTime:Float;
	
	static function runConcurrentFunc (f:Int->Void, numThreads:Int):Void {
		var finishedThreads = 0;
		var lock = new Mutex();
		
		for (i in 0 ... numThreads) {
			Thread.create(function ():Void {
				f(i);
				lock.acquire();
				finishedThreads++;
				lock.release();
			});
		}
		
		while (true) {
			//Check if threads are done every 100 ms
			lock.acquire();
			var done = finishedThreads == numThreads;
			lock.release();
			
			if (done) break;
			
			Sys.sleep(0.1);
		}
	}
	
	static inline function mark ():Void {
		lastTime = Sys.time();
	}
	
	static inline function dur (desc:String, count:Int):Void {
		var delta = Sys.time() - lastTime;
		Lib.println(desc + ": " + Std.int(delta*1e9/count) + " ns (" + Std.int(delta*1000) + " ms total time, " + count + " iterations)");
	}
	
	static inline function durTotal (desc:String):Void {
		var delta = Sys.time() - lastTime;
		Lib.println(desc + ": " + Std.int(delta*1e3) + " ms");
	}
	
	public static function main ():Void {
		Lib.println("==== Comparison to Non-Concurrent Data Structures ====");
		Lib.println("");
		
		//Array vs CopyOnWriteArray Write
		
		var a1 = new Array<Int>();
		var a2 = new CopyOnWriteArray<Int>();
		
		mark();
		for (i in 0 ... 20000000) {
			a1[i % 1000] = i;
		}
		dur("Array Write MOD 1000", 20000000);
		
		mark();
		for (i in 0 ... 500000) {
			a2[i % 1000] = i;
		}
		dur("CopyOnWriteArray Write MOD 1000", 500000);
		
		//Array vs CopyOnWriteArray Read
		
		mark();
		for (i in 0 ... 30000000) {
			a1[i % 1000];
		}
		dur("Array Read MOD 1000", 30000000);
		
		mark();
		for (i in 0 ... 10000000) {
			a2[i % 1000];
		}
		dur("CopyOnWriteArray Read MOD 1000", 10000000);
		
		//IntHash vs ConcurrentIntHash Set
		
		var h1 = new IntHash<Int>();
		var h2 = new ConcurrentIntHash<Int>();
		
		mark();
		for (i in 0 ... 10000000) {
			h1.set(i, i);
		}
		dur("IntHash Write", 10000000);
		
		mark();
		for (i in 0 ... 5000000) {
			h2.set(i, i);
		}
		dur("ConcurrentIntHash Write", 5000000);
		
		//IntHash vs ConcurrentIntHash Get
		
		var h1 = new IntHash<Int>();
		var h2 = new ConcurrentIntHash<Int>();
		
		mark();
		for (i in 0 ... 20000000) {
			h1.get(i);
		}
		dur("IntHash Read", 20000000);
		
		mark();
		for (i in 0 ... 5000000) {
			h2.get(i);
		}
		dur("ConcurrentIntHash Read", 5000000);
		
		Lib.println("");
		Lib.println("==== Throughput Speed Testing ====");
		Lib.println("");
		
		//Array vs CopyOnWriteArray ConcurrentRead
		
		var a3 = new Array<Int>();
		var a4 = new CopyOnWriteArray<Int>();
		
		//Setup
		for (i in 0 ... 10000) {
			a3[i] = i;
			a4[i] = i;
		}
		
		mark();
		for (i in 0 ... 20000000) {
			a3[i % 10000];
		}
		durTotal("Array Read 20M items");
		
		var total:Float = 0;
		var lock = new Mutex();
		runConcurrentFunc(function (tid:Int):Void {
			var low = (20000000 >> 1) * tid;
			var high = (20000000 >> 1) * (tid + 1);
			var lastTime = Sys.time();
			for (i in low ... high) {
				a4[i % 10000];
			}
			lock.acquire();
			total += Sys.time() - lastTime;
			lock.release();
		}, 2);
		Lib.println("CopyOnWriteArray Read 20M items (2 Threads): " + Std.int(total*1e3/2) + " ms");
		
		total = 0;
		runConcurrentFunc(function (tid:Int):Void {
			var low = (20000000 >> 2) * tid;
			var high = (20000000 >> 2) * (tid + 1);
			var lastTime = Sys.time();
			for (i in low ... high) {
				a4[i % 10000];
			}
			lock.acquire();
			total += Sys.time() - lastTime;
			lock.release();
		}, 4);
		Lib.println("CopyOnWriteArray Read 20M items (4 Threads): " + Std.int(total*1e3/4) + " ms");
		
		total = 0;
		runConcurrentFunc(function (tid:Int):Void {
			var low = (20000000 >> 3) * tid;
			var high = (20000000 >> 3) * (tid + 1);
			var lastTime = Sys.time();
			for (i in low ... high) {
				a4[i % 10000];
			}
			lock.acquire();
			total += Sys.time() - lastTime;
			lock.release();
		}, 8);
		Lib.println("CopyOnWriteArray Read 20M items (8 Threads): " + Std.int(total*1e3/8) + " ms");
		
		total = 0;
		runConcurrentFunc(function (tid:Int):Void {
			var low = (20000000 >> 4) * tid;
			var high = (20000000 >> 4) * (tid + 1);
			var lastTime = Sys.time();
			for (i in low ... high) {
				a4[i % 10000];
			}
			lock.acquire();
			total += Sys.time() - lastTime;
			lock.release();
		}, 16);
		Lib.println("CopyOnWriteArray Read 20M items (16 Threads): " + Std.int(total*1e3/16) + " ms");
		
		total = 0;
		runConcurrentFunc(function (tid:Int):Void {
			var low = (20000000 >> 5) * tid;
			var high = (20000000 >> 5) * (tid + 1);
			var lastTime = Sys.time();
			for (i in low ... high) {
				a4[i % 10000];
			}
			lock.acquire();
			total += Sys.time() - lastTime;
			lock.release();
		}, 32);
		Lib.println("CopyOnWriteArray Read 20M items (32 Threads): " + Std.int(total*1e3/32) + " ms");
	}

}