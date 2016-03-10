//
//  _cache_linked_list.m
//  KMCacheDemo
//
//  Created by Klein Mioke on 15/12/15.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

#import "_cache_linked_list.h"
#import <CoreFoundation/CoreFoundation.h>
#import <QuartzCore/QuartzCore.h>

#import <libkern/OSAtomic.h>

@implementation _cache_node

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    [aCoder encodeDouble:_time forKey:@"_time"];
    [aCoder encodeInteger:_size forKey:@"_size"];
    [aCoder encodeObject:_key forKey:@"_key"];
    [aCoder encodeObject:_value forKey:@"_value"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        
    }
    return self;
}

@end

@interface _cache_linked_list () <NSCoding>

@end

@implementation _cache_linked_list

- (instancetype)init {
    if (self = [super init]) {
        _dic = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        
        // by default
        _releaseOnMainThread = NO;
        _releaseAsynchronously = YES;
        _shouldRefreshNodeWhenUsed = YES;
    }
    return self;
}

- (void)dealloc {
    CFRelease(_dic);
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    [aCoder encodeObject:(__bridge id)(_dic) forKey:@"_dic"];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super init]) { }
    return self;
}

- (void)appendNode:(nonnull _cache_node *)node {
    
    if (_count == 0) {
        _head = node;
        _tail = node;
    } else {
        node->_prev = _tail;
        _tail->_next = node;
        _tail = node;
    }
    CFDictionarySetValue(_dic, (__bridge const void *)(node->_key), (__bridge const void *)(node));
    
    _count ++;
}

- (void)appendNewNodeWithValue:(id)value key:(id)key {
    
    [self appendNewNodeWithValue:value key:key size:0];
}

- (void)appendNewNodeWithValue:(id)value key:(id)key size:(NSUInteger)size {
    
    _cache_node *old = [self nodeForKey:key];
    
    if (old) {
        old->_value = value;
        old->_time = CACurrentMediaTime();
        old->_size = size;
        [self refreshNode:old];
        return;
    }
    
    _cache_node *node = [_cache_node new];
    node->_time = CACurrentMediaTime();
    node->_value = value;
    node->_key = key;
    node->_size = size;
    
    [self appendNode:node];
}

- (void)removeNode:(_cache_node *)node {
    
    CFDictionaryRemoveValue(_dic, (__bridge const void *)(node->_key));
    
    if (node->_prev) {
        node->_prev->_next = node->_next;
    }
    if (node->_next) {
        node->_next->_prev = node->_prev;
    }
    if (_head == node) {
        _head = node->_next;
    }
    if (_tail == node) {
        _tail = node->_prev;
    }
    _count --;
}

- (nullable _cache_node *)removeHeadNode {
    
    if (!_head) { return nil; }
    
    _cache_node *removedNode = _head;
    CFDictionaryRemoveValue(_dic, (__bridge const void *)(_head->_key));
    
    if (_head == _tail) {
        _head = _tail = nil;
    } else {
        _head = _head->_next;
        _head->_prev = nil;
    }
    _count --;
    return removedNode;
}

- (void)refreshNode:(_cache_node *)node {
    
    node->_time = CACurrentMediaTime();
    
    if (_tail == node) { return; }
    
    if (node->_prev) {
        node->_prev->_next = node->_next;
    }
    if (node->_next) {
        node->_next->_prev = node->_prev;
    }
    node->_prev = _tail;
    node->_next = nil;
    _tail->_next = node;
    _tail = node;
}

- (void)removeAllNodes {
    
    if (CFDictionaryGetCount(_dic) > 0) {
        
        CFMutableDictionaryRef holder = _dic;
        _dic = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        
        if (_releaseAsynchronously) {
            dispatch_queue_t queue = _releaseOnMainThread ? dispatch_get_main_queue() : (dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0));
            dispatch_async(queue, ^{
                CFRelease(holder);
            });
        } else if (_releaseOnMainThread && !pthread_main_np()) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                CFRelease(holder);
            });
        } else {
            CFRelease(holder);
        }
    }
    _head = nil;
    _tail = nil;
    _count = 0;
}

- (nullable _cache_node *)nodeForKey:(id)key {
    
    _cache_node *node = CFDictionaryGetValue(_dic, (__bridge const void *)(key));
    if (!node) {
        return nil;
    }
    if (_shouldRefreshNodeWhenUsed) {
        [self refreshNode:node];
    }
    return node;
}

@end
