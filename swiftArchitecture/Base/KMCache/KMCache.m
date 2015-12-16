//
//  KMCache.m
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/15.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

#import "KMCache.h"

@interface KMCache ()

@property (nonatomic ,strong) NSMutableDictionary *cache;

@end

@implementation KMCache

- (unsigned long long)size {
    
    NSLog(@"%llu",  self.cache.fileSize);
    
    NSMutableData *data = [[NSMutableData alloc] init];
    
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:self.cache forKey:@"sizeKey"];
    [archiver finishEncoding];
    
    NSLog(@"%ld", data.length);
    
    return self.cache.fileSize;
}

@end
