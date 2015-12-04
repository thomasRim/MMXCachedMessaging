//
//  MessageManager.m
//  M.A.C.
//
//  Created by Vladimir Yevdokimov on 6/2/15.
//  Copyright (c) 2015 magnet. All rights reserved.
//

#import "MMXMessageManager.h"

#define AppWithCachingCheckVersion @"v2.1"

#define kZeroChannelID @"GlobalAppActivityChannel"

#define kPrivateConversation @"private_conversation"
#define kChannelNameSeparator @"_"
#define kChannesSummarySeparator @", "
#define kWeekAgoDate [NSDate dateWithTimeIntervalSince1970:([NSDate date].timeIntervalSince1970 - 60*60*24*7)]

NSString * const NotificationMMX_ZeroMessageReceived = @"NotificationMMX_ZeroMessageReceived";
NSString * const NotificationMMX_MessageReceived = @"NotificationMMX_MessageReceived";
NSString * const kMMXMessageContent = @"kMMXMessageContent";
NSString * const kMMXMessageObject = @"kMMXMessageObject";

@interface MMXMessageManager ()

@property (nonatomic, strong) MMXChannel *zeroChannel;

@end

@implementation MMXMessageManager

+ (instancetype)shared
{
    static MMXMessageManager *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [MMXMessageManager new];
        [shared registerForNotifications];
    });
    return shared;
}

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(invitationToChannel:) name:MMXDidReceiveChannelInviteNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageReceived:) name:MMXDidReceiveMessageNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageSendError:) name:MMXMessageSendErrorNotification object:nil];
}

#pragma mark - Base activity

+ (void)enableZeroTopic:(BOOL)enableZero
{
    if (enableZero) {
        [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:kZeroChannelID];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kZeroChannelID];
    }
}

+ (void)connectLoggedUserToMMX:(void (^)(MMXConnectionStatus, NSError *))result
{

    [MagnetMax initModule:[MMX sharedInstance] success:^{
        
        //check activation, if only just activated - remove previous version caches if exist
        if (![[NSUserDefaults standardUserDefaults] objectForKey:AppWithCachingCheckVersion]) {
            [[NSUserDefaults standardUserDefaults] setObject:AppWithCachingCheckVersion forKey:AppWithCachingCheckVersion];
            //lets load cahed message caches with channel
            
            NSArray *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[MMXMessageCache userCachesPath] error:nil];
            NSString *predicateFormat = [NSString stringWithFormat:@"self ENDSWITH '%@'",kMMXCachedMessageExtension];
            NSArray *logFiles = [dirFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:predicateFormat]];
            if (logFiles.count) {
                for (NSString *logFile in logFiles) {
                    NSString *logFileName = [logFile stringByReplacingOccurrencesOfString:kMMXCachedMessageExtension withString:@""];
                    MMXChannel *channel = [MMXChannel new];
                    channel.name = logFileName.lowercaseString;
                    [MMXMessageCache removeMessageCacheForChannel:channel];
                }
            }
        }
        
        // Indicate that you are ready to receive messages now!
        [MMX start];
        // check for Zero subscription
        //  and/or report on success
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kZeroChannelID]) {
            [MMXMessageManager subscribeForZeroChannel:^(BOOL sucess) {
                result?result([MMXClient sharedClient].connectionStatus,nil):nil;
            }];
        } else {
            result?result([MMXClient sharedClient].connectionStatus,nil):nil;
        }
        
    } failure:^(NSError * error) {
        result?result([MMXClient sharedClient].connectionStatus,error):nil;
        [[MMXMessageManager shared] showAlertWithTitle:@"MagnetMax initModule Error" message:error.localizedDescription];
    }];
}

+ (void)subscribeForZeroChannel:(void(^)(BOOL sucess))result
{
    //check if zero channel exist
    [MMXChannel channelForName:kZeroChannelID isPublic:YES success:^(MMXChannel * _Nonnull channel) {
        if (channel) {
            NSLog(@"got zero channel for name");
            // check if user subscribed to zero channel
            [MMXMessageManager shared].zeroChannel = channel;

            if (channel.isSubscribed) {
                result?result(YES):nil;
            } else {
                [channel subscribeWithSuccess:^{
                    result?result(YES):nil;
                } failure:^(NSError * _Nonnull error) {
                    result?result(NO):nil;
                }];
            }

        } else {
            NSLog(@"no zero channel for name");
            [MMXChannel createWithName:kZeroChannelID summary:kZeroChannelID isPublic:YES publishPermissions:MMXPublishPermissionsSubscribers success:^(MMXChannel * _Nonnull channel) {
                if (channel) {
                    [MMXMessageManager shared].zeroChannel = channel;
                    // subscribe user to zero channel
                    [channel subscribeWithSuccess:^{
                        result?result(YES):nil;
                    } failure:^(NSError * _Nonnull error) {
                        NSLog(@"failed - subscribe zero channel %@",error);
                        result?result(NO):nil;
                    }];
                } else {
                    result?result(NO):nil;
                }
            } failure:^(NSError * _Nonnull error) {
                NSLog(@"failed - create zero channel %@",error);
                result?result(NO):nil;
            }];

        }
    } failure:^(NSError * _Nonnull error) {
//        result?result(NO):nil;
        NSLog(@"failed - channel for name  %@",error);
        // create zero channel
        [MMXChannel createWithName:kZeroChannelID summary:kZeroChannelID isPublic:YES publishPermissions:MMXPublishPermissionsSubscribers success:^(MMXChannel * _Nonnull channel) {
            if (channel) {
                [MMXMessageManager shared].zeroChannel = channel;
                // subscribe user to zero channel
                [channel subscribeWithSuccess:^{
                    result?result(YES):nil;
                } failure:^(NSError * _Nonnull error) {
                    NSLog(@"failed - subscribe zero channel 2 %@",error);
                    result?result(NO):nil;
                }];
            }
        } failure:^(NSError * _Nonnull error) {
            NSLog(@"failed - create zero channel 2 %@",error);
            result?result(NO):nil;
        }];

    }];
}

+ (void)postMessageToZero:(NSString*)message
{
    [[MMXMessageManager shared].zeroChannel publish:@{kMMXMessageContent : message} success:^(MMXMessage * _Nonnull message) {
        
    } failure:^(NSError * _Nonnull error) {
        
    }];

}

#pragma mark - Conversation Activity

+ (void)getNewConversations:(void(^)(NSArray <MMXMessageCache*> *conversations, NSError *error))result
{
    // here we check server data for channels
    
    NSArray *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[MMXMessageCache userCachesPath] error:nil];
    NSString *predicateFormat = [NSString stringWithFormat:@"self ENDSWITH '%@'",kMMXCachedMessageExtension];
    NSArray *logFiles = [dirFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:predicateFormat]];
    
    [MMXChannel subscribedChannelsWithSuccess:^(NSArray<MMXChannel *> * _Nonnull channels) {
        NSMutableArray *availablePublics = channels.mutableCopy;
        //exclude Zero topic
        for (MMXChannel *ch in channels) {
            if ([ch.name isEqualToString:kZeroChannelID]) {
                [availablePublics removeObject:ch];
                break;
            }
        }
        // check channels that need to be cached
        // and report results
        NSMutableArray *caches = @[].mutableCopy;
        for (MMXChannel *channel in availablePublics) {
            MMXMessageCache *cache = [MMXMessageCache messageCacheForChannel:channel];
            [caches addObject:cache];
        }
        result?result(caches,nil):nil;
        
        //check caches that not belong to any channel
        NSMutableArray *nonlinkedCaches = @[].mutableCopy;
        
        for (NSString *logFile in logFiles) {
            BOOL linked = NO;
            for (MMXChannel *pubChannel in availablePublics) {
                NSString *logFileName = [logFile stringByReplacingOccurrencesOfString:kMMXCachedMessageExtension withString:@""];
                if ([logFileName.lowercaseString isEqualToString:pubChannel.name.lowercaseString]) {
                    linked = YES;
                    break;
                }
            }
            if (!linked) {
                [nonlinkedCaches addObject:logFile];
            }
        }
        for (NSString *logFile in nonlinkedCaches) {
            NSString *logFileName = [logFile stringByReplacingOccurrencesOfString:kMMXCachedMessageExtension withString:@""];
            MMXChannel *channel = [MMXChannel new];
            channel.name = logFileName.lowercaseString;
            [MMXMessageCache removeMessageCacheForChannel:channel];
        }

    } failure:^(NSError * _Nonnull error) {
        result?result(nil,error):nil;

    }];
}

+ (void)getCachedConversations:(void(^)(NSArray <MMXMessageCache*> *conversations, NSError *error))result
{
    //lets load cahed message caches with channel
    NSError *error = nil;
    NSArray *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[MMXMessageCache userCachesPath] error:&error];
    if (error) {
        result?result(nil,error):nil;
    } else {
        NSString *predicateFormat = [NSString stringWithFormat:@"self ENDSWITH '%@'",kMMXCachedMessageExtension];
        NSArray *logFiles = [dirFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:predicateFormat]];
        
        NSMutableArray *messageCacheChannels = @[].mutableCopy;
        for (NSString *logFile in logFiles) {
            MMXMessageCache *cache = [MMXMessageCache messageCacheForFileAtPath:[[MMXMessageCache userCachesPath] stringByAppendingPathComponent:logFile]];
            [messageCacheChannels addObject:cache];
        }
        
        result?result(messageCacheChannels,error):nil;
    }
}


+ (void)getMessageUpdateForConversation:(MMXMessageCache*)messageCache startingDate:(NSDate  *)startDate completition:(void(^)(NSArray <MMXMessage*> *messages, NSError *error))result
{
    [messageCache.channel messagesBetweenStartDate:startDate?:kWeekAgoDate endDate:[NSDate date] limit:1000 offset:0 ascending:YES success:^(int totalCount, NSArray<MMXMessage *> * _Nonnull messages) {
        messageCache.messages = messages;
        result?result(messages,nil):nil;
    } failure:^(NSError * _Nonnull error) {
        result?result(nil,error):nil;
    }];
}

+ (void)createConversationWithUsers:(NSArray <MMUser *> *)users completition:(void(^)(MMXMessageCache *cache, NSError *error))result
{
    NSString *name = [NSString stringWithFormat:@"chat-%@",[NSUUID UUID].UUIDString];

    NSString *summary = [MMXMessageManager channelSummaryWithInvitees:users];
    
    [MMXMessageManager createConversationName:name summary:summary users:users completition:^(MMXMessageCache *cache, NSError *error) {
        result?result(cache,error):nil;
    }];
}

+ (void)createConversationName:(NSString*)name summary:(NSString*)summary users:(NSArray <MMUser *> *)users completition:(void(^)(MMXMessageCache *cache, NSError *error))result
{
    NSMutableSet *usersSet = [NSMutableSet setWithArray:users];
    [usersSet addObject:[MMUser currentUser]];
    
    [MMXChannel createWithName:name summary:summary isPublic:YES publishPermissions:MMXPublishPermissionsSubscribers  subscribers:usersSet success:^(MMXChannel * _Nonnull channel) {

        result?result([MMXMessageCache messageCacheForChannel:channel],nil):nil;


    } failure:^(NSError * _Nonnull error) {
        result?result(nil,error):nil;
    }];
}

+ (void)postMessage:(NSString*)message toConversation:(MMXMessageCache*)cache completition:(void(^)(MMXMessage *message, NSError *error))result
{
    [cache.channel publish:@{kMMXMessageContent: message} success:^(MMXMessage * _Nonnull message) {
        result?result(message,nil):nil;
    } failure:^(NSError * _Nonnull error) {
        result?result(nil,error):nil;
    }];
}


#pragma mark - Message Receiving

- (void)invitationToChannel:(NSNotification*)note
{
//    NSLog(@"invitation come %@",note);
    NSDictionary *userInfo = note.userInfo;
    MMXInvite *invite = userInfo[MMXInviteKey];
    [invite acceptWithComments:kPrivateConversation success:^{
    } failure:^(NSError * _Nonnull error) {
    }];
}

- (void)messageReceived:(NSNotification*)note
{
    NSDictionary *userInfo = note.userInfo;
    
    MMXMessage *messageObj = userInfo[MMXMessageKey];
    MMXChannel *channel = messageObj.channel;
 
    if ([channel.name.lowercaseString isEqualToString:kZeroChannelID.lowercaseString]) {

        NSDictionary *content = @{kMMXMessageObject : messageObj};

        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationMMX_ZeroMessageReceived object:nil userInfo:content];
    } else {
        NSDictionary *content = @{kMMXMessageObject : messageObj};
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationMMX_MessageReceived object:nil userInfo:content];
    }
    
}

- (void)messageSendError:(NSNotification*)note
{
    NSLog(@"message sending fail %@",note);
}


#pragma mark - Private


+ (NSArray*)userIDs:(NSArray <MMUser*> *)users
{
    NSMutableArray *ids = @[].mutableCopy;
    for (MMUser *user in users) {
        [ids addObject:user.userID];
    }
    return ids;
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message
{
    [[UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert] addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }]];
}

#pragma mark - Messaging

+ (NSString*)channelSummaryWithInvitees:(NSArray*)users
{
    NSMutableArray *allUsers = @[].mutableCopy;
    
    for (MMUser *user in users) {
        [allUsers addObject:[NSString stringWithFormat:@"%@ %@",user.firstName, user.lastName]];
    }
    [allUsers addObject:[NSString stringWithFormat:@"%@ %@",[MMUser currentUser].firstName,[MMUser currentUser].lastName]];
    
    allUsers = [allUsers sortedArrayUsingComparator:^NSComparisonResult(NSString *username1, NSString *username2) {
        return [username1 compare:username2 options:NSLiteralSearch];
    }].mutableCopy;
    
    return [allUsers componentsJoinedByString:kChannesSummarySeparator];
}



@end
