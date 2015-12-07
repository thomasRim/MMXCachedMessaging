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
@property (nonatomic, strong) NSArray *subscribers;

/**
 *  Object loading or by @channel MMX object or by @filePath string
 */
+ (instancetype)messageCacheForChannel:(MMXChannel*)channel;
+ (instancetype)messageCacheForFileAtPath:(NSString*)filePath;

/**
 *  Removing cache file from storage.
 */
+ (void)removeMessageCacheForChannel:(MMXChannel*)channel;

/**
 *  Determing number of messages that were set later of @lastReadDate. @lastReadDate do updates automaticaly by setting messages at very first time, or manually. Adding new messages may update unread messagesCount value. Number of unread messages may update on setting @lastReadDate value.
 *
 *  @return Count of messages later @lastReadDate.
 */
- (NSInteger)unreadMessagesCount;

/**
 *  Path to directory for storing user's cache
 *
 *  @return Path to user's cache directory
 */
+ (NSString*)userCachesPath;

@end
