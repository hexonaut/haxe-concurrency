/****
* Copyright (C) 2013 Sam MacPherson
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
****/

package haxe.concurrent;

import cad.Mutex;
import haxe.Constraints.IMap;
import haxe.ds.StringMap;
import haxe.ds.ObjectMap;
import haxe.ds.EnumValueMap;
import haxe.ds.IntMap;

/**
 * A wrapper for using Map concurrently. Access is thread safe.
 * 
 * @author Sam MacPherson
 */

@:multiType(K)
abstract ConcurrentMap<K,V>(IMap<K,V>) {
	
	public function new ();
	
	public inline function exists (key:K):Bool {
		var lock:Mutex = Reflect.field(this, "__lock");
		lock.acquire();
		var result = this.exists(key);
		lock.release();
		return result;
	}
	
	@:arrayAccess public inline function get (key:K):Null<V> {
		var lock:Mutex = Reflect.field(this, "__lock");
		lock.acquire();
		var result = this.get(key);
		lock.release();
		return result;
	}
	
	public inline function iterator ():Iterator<V> {
		var lock:Mutex = Reflect.field(this, "__lock");
		var arr = new Array<V>();
		lock.acquire();
		for (i in this.iterator()) {
			arr.push(i);
		}
		lock.release();
		return arr.iterator();
	}
	
	public inline function keys ():Iterator<K> {
		var lock:Mutex = Reflect.field(this, "__lock");
		var arr = new Array<K>();
		lock.acquire();
		for (i in this.keys()) {
			arr.push(i);
		}
		lock.release();
		return arr.iterator();
	}
	
	public inline function remove (key:K):Bool {
		var lock:Mutex = Reflect.field(this, "__lock");
		lock.acquire();
		var result = this.remove(key);
		lock.release();
		return result;
	}
	
	public inline function set (key:K, val:V):Void {
		var lock:Mutex = Reflect.field(this, "__lock");
		lock.acquire();
		this.set(key, val);
		lock.release();
	}
	
	public function toString ():String {
		var lock:Mutex = Reflect.field(this, "__lock");
		lock.acquire();
		var result = this.toString();
		lock.release();
		return result;
	}
	
	public inline function setIfNotExists (key:K, val:V):V {
		var lock:Mutex = Reflect.field(this, "__lock");
		lock.acquire();
		var oldval = this.get(key);
		if (oldval == null) {
			this.set(key, val);
			oldval = val;
		}
		lock.release();
		return oldval;
	}
	
	public inline function getAndRemove (key:K):Null<V> {
		var lock:Mutex = Reflect.field(this, "__lock");
		lock.acquire();
		var result = this.get(key);
		this.remove(key);
		lock.release();
		return result;
	}
	
	@:to static inline function toStringMap<K:String,V>(t:IMap<K,V>):StringMap<V> {
		var map = new StringMap<V>();
		Reflect.setField(map, "__lock", new Mutex());
		return map;
	}
	
	@:to static inline function toIntMap<K:Int,V>(t:IMap<K,V>):IntMap<V> {
		var map = new IntMap<V>();
		Reflect.setField(map, "__lock", new Mutex());
		return map;
	}
	
	@:to static inline function toEnumValueMapMap<K:EnumValue,V>(t:IMap<K,V>):EnumValueMap<K,V> {
		var map = new EnumValueMap<K, V>();
		Reflect.setField(map, "__lock", new Mutex());
		return map;
	}
	
	@:to static inline function toObjectMap<K:{ },V>(t:IMap<K,V>):ObjectMap<K,V> {
		var map = new ObjectMap<K, V>();
		Reflect.setField(map, "__lock", new Mutex());
		return map;
	}
	
	@:from static inline function fromStringMap<V>(map:StringMap<V>):ConcurrentMap<String, V> {
		Reflect.setField(map, "__lock", new Mutex());
		return map;
	}
        
	@:from static inline function fromIntMap<V>(map:IntMap<V>):ConcurrentMap<Int, V> {
		Reflect.setField(map, "__lock", new Mutex());
		return map;
	}

	@:from static inline function fromObjectMap<K:{ }, V>(map:ObjectMap<K,V>):ConcurrentMap<K, V> {
		Reflect.setField(map, "__lock", new Mutex());
		return map;
	}
	
}