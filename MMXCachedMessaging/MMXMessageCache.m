//
//  MessageCache.m
//  M.A.C.
//
//  Created by Vladimir Yevdokimov on 11/17/15.
//  Copyright © 2015 magnet. All rights reserved.
//

#import "MMXMessageCache.h"

NSString * const kMMXCachedMessageExtension = @".mmxchannellog";

#define kMessageCacheLastReadDate @"lastReadDate"
#define kMessageCacheMessages @"messages"
#define kMessageCacheUnreadCount @"unreadCount"
#define kMessageCacheChannel @"channel"
#define kMessageCacheSubscribers @"subscribers"

#define FString(str, ...) [NSString stringWithFormat:(str), ##__VA_ARGS__]

@interface MMXMessageCache ()

@property (nonatomic, assign) NSInteger unreadCount;

@end

@implementation MMXMessageCache

#pragma mark - Class

+ (instancetype)messageCacheForChannel:(MMXChannel *)channel
{
    MMXMessageCache *messageCache = nil;
    
    NSString *channelName = [MMXMessageCache fileNameForChannel:channel];
    
    NSString *filePath = [[MMXMessageCache userCachesPath] stringByAppendingPathComponent:channelName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]
        && ([NSData dataWithContentsOfFile:filePath].length > 0)) {
        messageCache = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        messageCache.channel = channel;
    } else {
        messageCache = [MMXMessageCache new];
        messageCache.channel = channel;
        [NSKeyedArchiver archiveRootObject:messageCache toFile:filePath];
    }
    
    return messageCache;
}

+ (instancetype)messageCacheForFileAtPath:(NSString *)filePath
{
    MMXMessageCache *messageCache = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]
        && ([NSData dataWithContentsOfFile:filePath].length > 0)) {
        messageCache = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    }
    
    return messageCache;
}

+ (void)removeMessageCacheForChannel:(MMXChannel *)channel
{
    NSString *channelName = [MMXMessageCache fileNameForChannel:channel];
    
    NSString *filePath = [[MMXMessageCache userCachesPath] stringByAppendingPathComponent:channelName];
    NSError *error = nil; // just info
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
    error?NSLog(@"msgCacheRemErr %@",error):nil;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.messages = @[];
        self.lastReadDate = [NSDate date];
        self.unreadCount = 0;
    }
    return self;
}

#pragma mark - Setters

- (void)setChannel:(MMXChannel *)channel
{
    _channel = channel;
    
    [self saveMessageCache];
}

- (void)setLastReadDate:(NSDate *)lastReadDate
{
    _lastReadDate = lastReadDate?:[NSDate date];
    
    [self saveMessageCache];
}

- (void)setMessages:(NSArray <MMXMessage*>*)messages
{
    if (!_lastReadDate) {
        _lastReadDate = [NSDate date];
    }
    
    if (!_messages.count) {
        _messages = messages;
        _unreadCount = _messages.count;
    } else {
        NSMutableArray *composetMessages = _messages.mutableCopy;
        
        _unreadCount = 0;
        
        for (MMXMessage *nMessage in messages) {
            BOOL exist = NO;
            for (MMXMessage *oMessage in _messages) {
                if ([oMessage.messageID isEqualToString:nMessage.messageID]) {
                    exist = YES;
                    break;
                }
            }
            if (!exist) {
                _unreadCount +=1;
                [composetMessages addObject:nMessage];
            }
        }
        
        _messages = [composetMessages sortedArrayUsingComparator:^NSComparisonResult(MMXMessage *m1, MMXMessage *m2) {
            NSString *ts1 = FString(@"%@",@(m1.timestamp.timeIntervalSince1970));
            NSString *ts2 = FString(@"%@",@(m2.timestamp.timeIntervalSince1970));
            return [ts1 compare:ts2 options:NSNumericSearch];
        }];
    }
    
    [self saveMessageCache];
}

- (void)setSubscribers:(NSArray *)subscribers
{
    _subscribers = subscribers;
    
    [self saveMessageCache];
}

- (void)saveMessageCache
{
    NSString *channelName = nil;
    
    if (_messages.count) {
        MMXMessage *message =  _messages.firstObject;
        channelName = [MMXMessageCache fileNameForChannel:message.channel];
    } else if (_channel) {
        channelName = [MMXMessageCache fileNameForChannel:_channel];
    }
    
    if (channelName) {
        NSString *filePath = [[MMXMessageCache userCachesPath] stringByAppendingPathComponent:channelName];
        
        [NSKeyedArchiver archiveRootObject:self toFile:filePath];
    }
}

- (NSInteger)unreadMessagesCount
{
    return self.unreadCount;
}

#pragma mark - Coding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        self.lastReadDate = [aDecoder decodeObjectForKey:kMessageCacheLastReadDate];
        self.messages = [aDecoder decodeObjectForKey:kMessageCacheMessages];
        self.unreadCount = [aDecoder decodeIntegerForKey:kMessageCacheUnreadCount];
        self.channel = [aDecoder decodeObjectForKey:kMessageCacheChannel];
        self.subscribers = [aDecoder decodeObjectForKey:kMessageCacheSubscribers];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.lastReadDate forKey:kMessageCacheLastReadDate];
    [aCoder encodeObject:self.messages forKey:kMessageCacheMessages];
    [aCoder encodeInteger:self.unreadCount forKey:kMessageCacheUnreadCount];
    [aCoder encodeObject:self.channel forKey:kMessageCacheChannel];
    [aCoder encodeObject:self.subscribers forKey:kMessageCacheSubscribers];
}

#pragma mark - Helpers

+ (NSString*)fileNameForChannel:(MMXChannel*)channel
{
    return FString(@"%@%@",channel.name,kMMXCachedMessageExtension);
}

+ (NSString*)userCachesPath
{
    NSString *userPath = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    userPath = [paths[0] stringByAppendingPathComponent:[MMUser currentUser].userID];
    [[NSFileManager defaultManager] createDirectoryAtPath:userPath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
    return userPath;
}

@end
