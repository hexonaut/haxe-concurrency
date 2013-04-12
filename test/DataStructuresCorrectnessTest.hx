package;

import haxe.concurrency.ConcurrentHash;
import haxe.concurrency.ConcurrentIntHash;
import haxe.concurrency.CopyOnWriteArray;
import massive.munit.Assert;

#if neko
import neko.vm.Mutex;
import neko.vm.Thread;
#elseif cpp
import cpp.vm.Mutex;
import cpp.vm.Thread;
#end

/**
* Tests the data structures library for correctness.
*/
class DataStructuresCorrectnessTest {
	
	inline static var NUM_THREADS:Int = 500;
	
	public function new () {
		
	}
	
	function runConcurrentFunc (f:Int->Void, ?numThreads:Int = NUM_THREADS):Void {
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
	
	@Test
	public function testCopyOnWriteArrayPush ():Void {
		var arr = new CopyOnWriteArray<Int>();
		
		runConcurrentFunc(function (tid:Int):Void {
			Sys.sleep(Math.random() * 0.3);
			
			arr.push(tid);
		});
		arr.sort(function (a:Int, b:Int):Int {
			return a > b ? 1 : -1;
		});
		
		var matches = true;
		for (i in 0 ... NUM_THREADS) {
			if (arr[i] != i) matches = false;
		}
		Assert.isTrue(matches);
	}
	
	@Test
	public function testCopyOnWriteArrayPushPop ():Void {
		var arr = new CopyOnWriteArray<Int>();
		
		runConcurrentFunc(function (tid:Int):Void {
			Sys.sleep(Math.random() * 0.3);
			
			//Push half the values and pop half the values
			if (tid % 2 == 0) {
				arr.push(tid);
			} else {
				while (arr.pop() == null) {
					Sys.sleep(Math.random() * 0.01);	//Wait small period
				}
			}
		});
		
		Assert.areEqual(0, arr.length);
	}
	
	@Test
	public function testConcurrentIntHashSet ():Void {
		var hash = new ConcurrentIntHash<Int>();
		
		runConcurrentFunc(function (tid:Int):Void {
			Sys.sleep(Math.random() * 0.3);
			
			//Set values concurrently
			hash.set(tid, tid);
		});
		
		var matches = true;
		for (i in 0 ... NUM_THREADS) {
			if (hash.get(i) != i) matches = false;
		}
		Assert.isTrue(matches);
	}
	
	@Test
	public function testConcurrentIntHashRandom ():Void {
		var hash = new ConcurrentIntHash<Int>();
		
		runConcurrentFunc(function (tid:Int):Void {
			Sys.sleep(Math.random() * 0.3);
			
			//Keep trying to put your thread id into a random slot
			var prevVal = tid;
			while (true) {
				prevVal = hash.setIfNotExists(Std.int(Math.random() * 1500), tid);	//1500 slots to put 500 numbers
				if (prevVal == tid) break;
			}
		});
		
		//Make sure all tids exist exactly once
		var arr = new Array<Int>();
		for (i in hash) {
			arr.push(i);
		}
		arr.sort(function (a:Int, b:Int):Int {
			return a > b ? 1 : -1;
		});
		var matches = true;
		for (i in 0 ... NUM_THREADS) {
			if (arr[i] != i) matches = false;
		}
		Assert.isTrue(matches);
	}

}