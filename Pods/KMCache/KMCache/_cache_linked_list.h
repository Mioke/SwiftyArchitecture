//
//  _cache_linked_list.h
//  KMCacheDemo
//
//  Created by Klein Mioke on 15/12/15.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <pthread.h>

NS_ASSUME_NONNULL_BEGIN

@interface _cache_node : NSObject <NSCoding>
{
    @package
    NSTimeInterval _time;
    NSUInteger _size;
    
    id _key;
    id _value;
    __unsafe_unretained _cache_node *_prev;
    __unsafe_unretained _cache_node *_next;
}
@end

@interface _cache_linked_list : NSObject
{
    @package
    CFMutableDictionaryRef _dic;
    __unsafe_unretained _cache_node *_head;
    __unsafe_unretained _cache_node *_tail;
    int _count;
    BOOL _releaseOnMainThread;
    BOOL _releaseAsynchronously;
    BOOL _shouldRefreshNodeWhenUsed;
}

- (void)appendNode:(_cache_node *)node;
- (void)appendNewNodeWithValue:(id)value key:(id)key;
- (void)appendNewNodeWithValue:(id)value key:(id)key size:(NSUInteger)size;

- (void)removeNode:(_cache_node *)node;
- (nullable _cache_node *)removeHeadNode;
- (void)removeAllNodes;

- (void)refreshNode:(_cache_node *)node;
- (nullable _cache_node *)nodeForKey:(id)key;

@end

NS_ASSUME_NONNULL_END

