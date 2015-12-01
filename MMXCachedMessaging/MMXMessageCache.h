//
//  MessageCache.h
//  M.A.C.
//
//  Created by Vladimir Yevdokimov on 11/17/15.
//  Copyright © 2015 magnet. All rights reserved.
//

#import <Foundation/Foundation.h>

@import MagnetMax;

extern NSString * const kMMXCachedMessageExtension;

@interface MMXMessageCache : NSObject<NSCoding>

@property (nonatomic, strong) NSDate *lastReadDate;
@property (nonatomic, strong) NSArray <MMXMessage*> *messages;
@property (nonatomic, strong) MMXChannel *channel;

+ (instancetype)messageCacheForChannel:(MMXChannel*)channel;
+ (instancetype)messageCacheForFileAtPath:(NSString*)filePath;

+ (void)removeMessageCacheForChannel:(MMXChannel*)channel;

- (NSInteger)unreadMessagesCount;

@end
