haxe-concurrency is a library to provide high level thread-safe data structures for all targets that support shared memory concurrency. Also included is a fully concurrent server which is similar to neko.net.ThreadServer, except the application logic is concurrent as well. Supported targets are neko and c++.

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

* Array Read 20M items: 1319 ms
* CopyOnWriteArray Read 20M items (2 Threads): 1401 ms
* CopyOnWriteArray Read 20M items (4 Threads): 840 ms
* CopyOnWriteArray Read 20M items (8 Threads): 815 ms
* CopyOnWriteArray Read 20M items (16 Threads): 776 ms