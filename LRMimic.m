//
//  LRMimic.m
//  MimicSpecDemo
//
//  Created by Luke Redpath on 13/01/2011.
//  Copyright 2011 LJR Software Limited. All rights reserved.
//

#import "LRMimic.h"
#import <LRResty/LRResty.h>

@interface LRMimic ()
+ (id)sharedInstance;
- (NSData *)payload;
@end

#define kMimicDefaultURL @"http://localhost:11988/api"

@implementation LRMimic

static NSString *mimicURL = nil;
static BOOL automaticallyClearStubs = NO;

+ (void)setURL:(NSString *)url;
{
  [mimicURL autorelease];
  mimicURL = [url copy];
}

+ (void)setAutomaticallyClearsStubs:(BOOL)shouldClear
{
  automaticallyClearStubs = shouldClear;
}

+ (void)reset;
{
  [[self sharedInstance] reset];
}

#pragma mark -
#pragma mark Static API

+ (void)configure:(LRMimicConfigurationBlock)configurationBlock
{
  configurationBlock([self sharedInstance]);
}

+ (void)stubAndCall:(LRMimicCallback)callback;
{
  [[self sharedInstance] prepareStubs:callback clearRemote:automaticallyClearStubs];
}

#pragma mark -

- (id)initWithMimicURL:(NSString *)mimicURL;
{
  if (self = [super init]) {
    URL = [mimicURL copy];
    stubs = [[NSMutableArray alloc] init];
    client = [LRResty newClient];

    [client attachRequestModifier:^(LRRestyRequest *req) {
      [req addHeader:@"Content-Type" value:@"application/plist"];
    }];
  }
  return self;
}

- (void)dealloc
{
  [client release];
  [mimicURL release];
  [stubs release];
  [super dealloc];
}

- (void)prepareStubs:(LRMimicCallback)callback;
{
  [client post:[URL stringByAppendingPathComponent:@"multi"]
       payload:[self payload]
     withBlock:^(LRRestyResponse *response) {
       
    if (response.status == 201) {  
      callback(YES);
    } else {
      callback(NO);
    }
  }];
}
  
- (void)prepareStubs:(LRMimicCallback)callback clearRemote:(BOOL)clearRemote;
{
  if (clearRemote) {
    [self clearRemoteStubs:^(BOOL success) {
      if (success) {
        [self prepareStubs:callback];
      } else {
        callback(NO);
      }
    }];
  } else {
    [self prepareStubs:callback];
  }
}

- (void)clearRemoteStubs:(LRMimicCallback)callback;
{
  [client post:[URL stringByAppendingPathComponent:@"clear"]
       payload:nil
     withBlock:^(LRRestyResponse *response) {
       
    if (response.status == 200) {
      callback(YES);
    } else {
      callback(NO);
    }
  }];
}

- (void)reset;
{
  [stubs removeAllObjects];
}

#pragma mark -
#pragma mark Private methods

- (NSData *)payload;
{
  NSMutableArray *stubPayloads = [NSMutableArray arrayWithCapacity:stubs.count];
  for (LRMimicRequestStub *stub in stubs) {
    [stubPayloads addObject:[stub toDictionary]];
  }
  NSLog(@"STUBBING %@", stubPayloads);
  NSDictionary *payload = [NSDictionary dictionaryWithObject:stubPayloads forKey:@"stubs"];
  return [NSPropertyListSerialization dataFromPropertyList:(id)payload
                                                    format:NSPropertyListXMLFormat_v1_0 
                                          errorDescription:nil];
}

+ (id)sharedInstance;
{
  static id sharedInstance = nil;
  
  if (sharedInstance == nil) {
    if (mimicURL == nil) {
      mimicURL = kMimicDefaultURL;
    }
    sharedInstance = [[self alloc] initWithMimicURL:mimicURL];
  }
  
  return sharedInstance;
}

@end

#pragma mark -

@implementation LRMimic (StubMethods)

- (LRMimicRequestStub *)get:(NSString *)path;
{
  return [self stub:path method:@"GET"];
}

- (LRMimicRequestStub *)post:(NSString *)path;
{
  return [self stub:path method:@"POST"];
}

- (LRMimicRequestStub *)put:(NSString *)path;
{
  return [self stub:path method:@"PUT"];
}

- (LRMimicRequestStub *)delete:(NSString *)path;
{
  return [self stub:path method:@"DELETE"];
}

- (LRMimicRequestStub *)head:(NSString *)path;
{
  return [self stub:path method:@"HEAD"];
}

- (LRMimicRequestStub *)stub:(NSString *)path method:(NSString *)httpMethod;
{
  LRMimicRequestStub *stub = [LRMimicRequestStub stub:path method:httpMethod];
  [stubs addObject:stub];
  return stub;
}

@end


#pragma mark -

@implementation LRMimicRequestStub

+ (id)stub:(NSString *)path;
{
  return [self stub:path method:@"GET"];
}

+ (id)stub:(NSString *)path method:(NSString *)method
{
  return [[[self alloc] initWithPath:path method:method] autorelease];
}

- (id)initWithPath:(NSString *)aPath method:(NSString *)HTTPMethod;
{
  if (self = [super init]) {
    method = [HTTPMethod copy];
    path = [aPath copy];
    body = [[NSString alloc] initWithString:@""];
    code = 200;
  }
  return self;
}

- (void)dealloc
{
  [method release];
  [path release];
  [body release];
  [super dealloc];
}

- (void)andReturnResponse:(NSString *)responseBody withStatus:(NSInteger)statusCode;
{
  body = [responseBody copy];
  code = statusCode;
}

- (NSDictionary *)toDictionary;
{
  NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
  [dictionary setObject:method forKey:@"method"];
  [dictionary setObject:path forKey:@"path"];
  [dictionary setObject:body forKey:@"body"];
  [dictionary setObject:[NSNumber numberWithInteger:code] forKey:@"code"];
  return dictionary;
}

@end

