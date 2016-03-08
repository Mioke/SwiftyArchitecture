# KMCache
Inspired by [YYCache](https://github.com/ibireme/YYCache).

### Usage

1. Clone or download the zip into your computer, copy the `KMCache` folder into your project
2. If you are using cocoapods:

   ```ruby
   pod "KMCache"
   ```

### Thought
Using `CFMutableDictinaryRef` as a container for quick searching. Create `_cache_node` and `_cache_linked_list` to build a linked list for building ordered data. `_cache_node` is a node with properties of `key`, `value`, `timestamp`, `size`, and pointers of `_prev` and `_next`.It store object and other infomations. `_cache_linked_list` is ordered by time of insertion, and refresh the node when the node use again.

Think it as a queue, every time you want to add an object into cache, first create a node, and append the node to the tail of the queue.It does two things when append a node: 1. Add the node into dictionary. 2. Set the node's prev pointer to the tail of the queue, and the node becomes new tail. 

Searching is getting values from a dictionary.

KMCache provide two release types, release by time and by size. Node's infomation contains `time` property, it will check this when cache auto-clean it self. 

KMCache will auto count the size of dictionary data's size before, but this really cost a lot to do so. Think about it, every time we append a node into the list, we must cast dictionay to `NSData` and count it. What was worse, if the size of dictionary is too large, we don't know how many nodes should we release. So I give it up.

Finally, with the help of `YYCache` and `NSCache's` comment, the better way is to set a property of `_cache_node` for recording the size of node. But the size is not automatically generated, it's set by user.

### Atention

Auto-clean will run every 5 seconds(by default), I set a `NSTimer` in KMCache. The timer is add into the main runloop, so if the main thread is doing something synchronously, the timer will stop too.
