package ;

import cad.Debugger;
import cad.Lock;
import cad.Mutex;
import cad.Thread;
import haxe.concurrent.ConcurrentMap;
import haxe.concurrent.CopyOnWriteArray;
import sys.net.Host;

class Main {
	
	static var hash = new ConcurrentMap<Int, CopyOnWriteArray<Int>>();
	
	public static function main ():Void {
		Debugger.listen(new Host("localhost"), 9308, true);
		
		trace("Starting");
		for (i in 0 ... 10) {
			Thread.create(start);
		}
		while (true) {
			for (i in hash.get(1)) {
				
			}
		}
	}
	
	static function start ():Void {
		while (true) {
			hash.setIfNotExists(Std.int(Math.random() * 100), new CopyOnWriteArray());
			hash.remove(Std.int(Math.random() * 100));
		}
	}
	
}