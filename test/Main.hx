package ;

import haxe.ds.ConcurrentMap;
import haxe.ds.CopyOnWriteArray;
import neko.net.AppThreadServer;
import sys.db.PooledConnection;

/**
 * Testing for haxe-concurrency.
 * 
 * @author Sam MacPherson
 */
class Main {

	public static function main () {
		var map = new ConcurrentMap<Int, Dynamic>();
		map.set(1, 1);
		map.set(2, "test");
		map.set(3, 3);
		trace(map[1]);
		trace(map[2]);
		trace(map.get(3));
		
		for (i in map) {
			trace(i);
		}
		
		var arr = new CopyOnWriteArray<String>();
		arr.push("1");
		arr.push("2");
		arr.push("3");
		trace(arr);
	}
	
}