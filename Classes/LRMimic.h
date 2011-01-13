//
//  LRMimic.h
//  MimicSpecDemo
//
//  Created by Luke Redpath on 13/01/2011.
//  Copyright 2011 LJR Software Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LRMimic;
@class LRRestyClient;
@class LRMimicRequestStub;

typedef void (^LRMimicConfigurationBlock)(LRMimic *);
typedef void (^LRMimicCallback)(BOOL);

@interface LRMimic : NSObject {
  NSString *URL;
  NSMutableArray *stubs;
  LRRestyClient *client;
}
+ (void)setURL:(NSString *)url;
+ (void)setAutomaticallyClearsStubs:(BOOL)shouldClear;
+ (void)reset;
+ (void)configure:(LRMimicConfigurationBlock)configurationBlock;
+ (void)stubAndCall:(LRMimicCallback)callback;
- (void)prepareStubs:(LRMimicCallback)callback;
- (void)prepareStubs:(LRMimicCallback)callback clearRemote:(BOOL)clearRemote;
- (void)clearRemoteStubs:(LRMimicCallback)callback;
- (id)initWithMimicURL:(NSString *)mimicURL;
- (void)prepareStubs:(LRMimicCallback)callback;
- (void)reset;
@end

@interface LRMimic (StubMethods)
- (LRMimicRequestStub *)get:(NSString *)path;
- (LRMimicRequestStub *)post:(NSString *)path;
- (LRMimicRequestStub *)put:(NSString *)path;
- (LRMimicRequestStub *)delete:(NSString *)path;
- (LRMimicRequestStub *)head:(NSString *)path;
- (LRMimicRequestStub *)stub:(NSString *)path method:(NSString *)httpMethod;
@end

@interface LRMimicRequestStub : NSObject
{
  NSString *method;
  NSString *path;
  NSString *body;
  NSInteger code;
}
+ (id)stub:(NSString *)path;
+ (id)stub:(NSString *)path method:(NSString *)method;
- (id)initWithPath:(NSString *)aPath method:(NSString *)HTTPMethod;
- (void)willReturnResponse:(NSString *)responseBody withStatus:(NSInteger)statusCode;
- (NSDictionary *)toDictionary;
@end

