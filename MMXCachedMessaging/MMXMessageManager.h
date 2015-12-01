//
//  MessageManager.h
//  M.A.C.
//
//  Created by Vladimir Yevdokimov on 6/2/15.
//  Copyright (c) 2015 magnet. All rights reserved.
//

#import <Foundation/Foundation.h>

@import MagnetMax;

#import "MMXMessageCache.h"
//
extern NSString * const NotificationMMX_ZeroMessageReceived; // for Zero topic activity
extern NSString * const NotificationMMX_MessageReceived; // for user 2 user activity

extern NSString * const kMMXMessageContent;
extern NSString * const kMMXMessageObject;

@interface MMXMessageManager : NSObject


@property (nonatomic, strong) NSString *deviceToken;

/**
 *  Setup MessageManager before connection to MMX server
 *
 *  @param enableZero NO - by default. If set to YES - this will enable to send message by {postMessageToZero:} to all users via 'Zero' topic. Using 'NotificationMMXZeroMessageReceived' - one can receive 'Zero' topic messages. 'Zero' topic is public, but not cacheable and not listed in Conversations list.
 */
+ (void)enableZeroTopic:(BOOL)enableZero; // NO - by dafault.

/**
 *  Use this method to connect logged user to MMX server
 *
 *  @param result Return actual connection satatus and/or error for connection result.
 */
+ (void)connectLoggedUserToMMX:(void(^)(MMXConnectionStatus status, NSError *error))result;

/**
 *  Notify other users that some app global data changed and they may have refresh their app UI
 *
 *  @param message Description of where and what have changed
 */
+ (void)postMessageToZero:(NSString*)message;

// Conversation Activity
/**
 *  Getting cached conversations. There might be repetitive callbacks. One if there are existing cached conversations. Other when conversations did updated with server messages.
 *
 *  @param result Callback with cached conversations, or error if something wrong.
 */
+ (void)getAllConversations:(void(^)(NSArray <MMXMessageCache*> *conversations, NSError *error))result;

/**
 *  Doing update to single conversation.
 *
 *  @param messageCache Conversation that needs update
 *  @param startDate    Conversation messages period from now till @startDate. If set to nil - time period will be a week from now.
 *  @param result       Messages of conversation. Composed by cached before, with those, from time period, defined by @startDate, or error if something wrong.
 */
+ (void)getMessageUpdateForConversation:(MMXMessageCache*)messageCache startingDate:(NSDate  *)startDate completition:(void(^)(NSArray <MMXMessage*> *messages, NSError *error))result;

/**
 *  Create new conversation with creating message cache.
 *
 *  @param users  Users that will be invited for this conversation.
 *  @param result Callback with cached conversation, or error if something wrong.
 */
+ (void)createConversationWithUsers:(NSArray <MMUser *> *)users completition:(void(^)(MMXMessageCache *cache, NSError *error))result;

/**
 *  Create new conversation with creating message cache.
 *
 *  @param name    New channel name
 *  @param summary New channel summary
 *  @param users   Users that will be invited for this conversation.
 *  @param result  Callback with cached conversation, or error if something wrong.
 */
+ (void)createConversationName:(NSString*)name summary:(NSString*)summary users:(NSArray <MMUser *> *)users completition:(void(^)(MMXMessageCache *cache, NSError *error))result;

/**
 *  Posting message to conversation.
 *
 *  @param message Message string.
 *  @param cache   Conversation to post to.
 */
+ (void)postMessage:(NSString*)message toConversation:(MMXMessageCache*)cache;

@end;
