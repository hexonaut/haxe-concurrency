package ;

import cad.Debugger;
import cad.Lock;
import cad.Mutex;
import cad.Thread;
import sys.net.Host;

class Main {

	public static function main ():Void {
		Debugger.listen(new Host("localhost"), 9308, true);
		
		trace("Starting");
		var mutex = new Mutex();
		trace(Thread.current().getInfo());
		while (true) {
			mutex.acquire();
			"asdf";
			mutex.release();
		}
	}
	
}