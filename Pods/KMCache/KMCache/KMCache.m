//
//  KMCache.m
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/15.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

#import "KMCache.h"
#import "_cache_linked_list.h"
#import <libkern/OSAtomic.h>
#import <math.h>

#import <UIKit/UIKit.h>

@interface KMCache ()

@property (nonatomic, strong) _cache_linked_list *cacheList;

@end

@implementation KMCache
{
    OSSpinLock _lock;
    NSUInteger _maxByte;
    
    dispatch_queue_t _queue;
    NSTimer *_timer;
}

- (instancetype)init {
    if (self = [super init]) {
        _type = KMCacheTypeDefualt;
        _queue = dispatch_queue_create("com.kleinmioke.memorycache", DISPATCH_QUEUE_SERIAL);
        
        self.maxCount = INT_MAX;
        self.maxSize = NSUIntegerMax;
        _lock = OS_SPINLOCK_INIT;
        self.autoCleanInterval = 5;
        
        self.needRefreshCacheWhenUsed = YES;
        self.releaseOnMainThread = NO;
        self.releaseAsynchronously = YES;
        self.shouldAutoReleaseWhenReceiveMemoryWarning = YES;
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didReceiveMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

- (instancetype)initWithType:(KMCacheType)type {
    if (self = [self init]) {
        _type = type;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)setCacheObject:(id<NSObject>)object ofSize:(NSUInteger)size forKey:(id<NSObject>)key {
    
    OSSpinLockLock(&_lock);
    @try {
        [self.cacheList appendNewNodeWithValue:object key:key size:size];
        
        if (self.cacheList->_count > self.maxCount) {
            _cache_node *head = [self.cacheList removeHeadNode];
            
            if (self.releaseAsynchronously) {
                dispatch_queue_t queue = self.releaseOnMainThread ? dispatch_get_main_queue() : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
                dispatch_async(queue, ^{
                    [head description];
                });
            } else if (self.releaseOnMainThread && !pthread_main_np()) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [head description];
                });
            }
        }
        OSSpinLockUnlock(&_lock);
        return YES;
    }
    @catch (NSException *exception) {
        OSSpinLockUnlock(&_lock);
        return NO;
    }
}

- (BOOL)setCacheObject:(id<NSObject>)object forKey:(id<NSObject>)key {
    
    return [self setCacheObject:object ofSize:0 forKey:key];
}

- (nullable id)objectForKey:(id)key {
    
    OSSpinLockLock(&_lock);
    _cache_node *node = [self.cacheList nodeForKey:key];
    OSSpinLockUnlock(&_lock);
    if (!node) {
        return nil;
    }
    return node->_value;
}

- (void)clean {
    
    dispatch_async(_queue, ^{
        
        [self cleanCacheByCount];
        
        if (self.type == KMCacheTypeDefualt) {
            return;
        }
        if (self.type & KMCacheTypeReleaseByTime) {
            [self cleanCacheByTime];
        }
        if (self.type & KMCacheTypeReleaseBySize) {
            [self cleanCacheBySize];
        }
    });
}

- (void)cleanAllCache {
    
    OSSpinLockLock(&_lock);
    [self.cacheList removeAllNodes];
    OSSpinLockUnlock(&_lock);
}

- (void)cleanCacheByCount {
    
    if (self.maxCount >= self.cacheList->_count) {
        return;
    }
    
    if (self.maxCount == 0) {
        [self cleanAllCache];
        return;
    }
    
    CFMutableArrayRef holder = CFArrayCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeArrayCallBacks);
    
    while (self.cacheList->_count > self.maxCount) {
        
        if (OSSpinLockTry(&_lock)) {
            _cache_node *head = [self.cacheList removeHeadNode];
            CFArrayAppendValue(holder, (__bridge const void *)(head));
            OSSpinLockUnlock(&_lock);
        } else {
            usleep(10000);
        }
    }
    [self releaseObj:holder];
}

- (void)cleanCacheByTime {
    
    if (self.type != KMCacheTypeReleaseByTime || self.cacheList->_count == 0) {
        return;
    }
    CFTimeInterval current = CACurrentMediaTime();
    CFMutableArrayRef holder = CFArrayCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeArrayCallBacks);
    
    _cache_node *node = self.cacheList->_head;
    
    while (node && (node->_time + self.releaseTime < current)) {
        
        if (OSSpinLockTry(&_lock)) {
            
            [self.cacheList removeNode:node];
            _cache_node *holded = node;
            CFArrayAppendValue(holder, (__bridge const void *)(holded));
            node = node->_next;
            OSSpinLockUnlock(&_lock);
        } else {
            usleep(10000);
        }
    }
    [self releaseObj:holder];
}

- (void)cleanCacheBySize {
    
}

//- (void)cleanRecursively {
//
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.autoCleanInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//
//    });
//}

- (_cache_linked_list *)cacheList {
    
    if (!_cacheList) {
        _cacheList = [[_cache_linked_list alloc] init];
    }
    return _cacheList;
}

- (NSUInteger)size {
    
    OSSpinLockLock(&_lock);
    NSMutableData *data = [[NSMutableData alloc] init];
    
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:self.cacheList forKey:@"sizeKey"];
    [archiver finishEncoding];
    OSSpinLockUnlock(&_lock);
    
//    NSLog(@"%ld", data.length);
    
    return data.length;
}

- (void)_didReceiveMemoryWarning {
    
    if (self.shouldAutoReleaseWhenReceiveMemoryWarning) {
        [self cleanAllCache];
    }
}

#pragma mark - Getter and setter

- (void)setMaxSize:(NSUInteger)maxSize {
    _maxSize = maxSize;
    
    if (_maxSize < 1024) {
        _maxByte = _maxSize * sqrt(1024);
    }
}

//- (BOOL)releaseOnMainThread {
//
//    OSSpinLockLock(&_lock);
//    BOOL releaseOnMainThread = self.cacheList->_releaseOnMainThread;
//    OSSpinLockUnlock(&_lock);
//    return releaseOnMainThread;
//}

- (void)setReleaseOnMainThread:(BOOL)releaseOnMainThread {
    
    _releaseOnMainThread = releaseOnMainThread;
    
    OSSpinLockLock(&_lock);
    self.cacheList->_releaseOnMainThread = releaseOnMainThread;
    OSSpinLockUnlock(&_lock);
}

//- (BOOL)releaseAsynchronously {
//    OSSpinLockLock(&_lock);
//    BOOL releaseAsynchronously = self.cacheList->_releaseAsynchronously;
//    OSSpinLockUnlock(&_lock);
//    return releaseAsynchronously;
//}

- (void)setReleaseAsynchronously:(BOOL)releaseAsynchronously {
    
    _releaseAsynchronously = releaseAsynchronously;
    
    OSSpinLockLock(&_lock);
    self.cacheList->_releaseAsynchronously = releaseAsynchronously;
    OSSpinLockUnlock(&_lock);
}

- (void)setAutoCleanInterval:(NSTimeInterval)autoCleanInterval {
    _autoCleanInterval = autoCleanInterval;
    
    if (_timer != nil) {
        [_timer invalidate];
        _timer = nil;
    }
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:_autoCleanInterval target:self selector:@selector(clean) userInfo:nil repeats:YES];
}

- (void)setNeedRefreshCacheWhenUsed:(BOOL)needRefreshCacheWhenUsed {
    
    _needRefreshCacheWhenUsed = needRefreshCacheWhenUsed;
    self.cacheList->_shouldRefreshNodeWhenUsed = _needRefreshCacheWhenUsed;
}

#pragma mark - Other functions

- (void)releaseObj:(CFTypeRef)holder {
    
    if (self.releaseAsynchronously) {
        dispatch_queue_t queue = self.releaseOnMainThread ? dispatch_get_main_queue() : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
        dispatch_async(queue, ^{
            CFRelease(holder);
        });
    } else if (self.releaseOnMainThread && !pthread_main_np()) {
        dispatch_async(dispatch_get_main_queue(), ^{
            CFRelease(holder);
        });
    } else {
        CFRelease(holder);
    }
}

@end