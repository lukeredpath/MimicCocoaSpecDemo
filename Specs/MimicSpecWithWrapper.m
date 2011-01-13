//
//  MimicSpecWithWrapper.m
//  MimicSpecDemo
//
//  Created by Luke Redpath on 13/01/2011.
//  Copyright 2011 LJR Software Limited. All rights reserved.
//

#import "Kiwi.h"
#define HC_SHORTHAND
#import "OCHamcrest.h"
#import "AssertEventually.h"
#import <LRResty/LRResty.h>
#import "LRMimic.h"

SPEC_BEGIN(MimicSpecWithWrapper)

describe(@"Testing using Mimic to stub HTTP requests with an Objective-C wrapper API", ^{
  
  beforeAll(^{
    [LRMimic setURL:@"http://localhost:11988/api"];
    [LRMimic setAutomaticallyClearsStubs:YES];
    [LRMimic reset];
  });
  
  it(@"should allow HTTP endpoints to be stubbed and immediately tested", ^{
    __block NSString *responseBody = nil;

    [LRMimic configure:^(LRMimic *mimic) {
      [[mimic get:@"/ping"] willReturnResponse:@"pong" withStatus:200];
    }];
    
    [LRMimic stubAndCall:^(BOOL success) {
      if (success) {
        [[LRResty client] get:@"http://localhost:11988/ping" withBlock:^(LRRestyResponse *response) {
          responseBody = [[response asString] copy];
        }];
      }
    }];

    assertEventuallyThat(&responseBody, equalTo(@"pong"));
  });
  
  it(@"should allow multiple HTTP endpoints to be stubbed and immediately tested", ^{
    __block NSString *responseBodyOne = nil;
    __block NSString *responseBodyTwo = nil;
    
    [LRMimic configure:^(LRMimic *mimic) {
      [[mimic get:@"/ping"] willReturnResponse:@"pong" withStatus:200];
      [[mimic get:@"/wiff"] willReturnResponse:@"waff" withStatus:200];
    }];
    
    [LRMimic stubAndCall:^(BOOL success) {
      if (success) {
        [[LRResty client] get:@"http://localhost:11988/ping" withBlock:^(LRRestyResponse *response) {
          responseBodyOne = [[response asString] copy];
        }];
        [[LRResty client] get:@"http://localhost:11988/wiff" withBlock:^(LRRestyResponse *response) {
          responseBodyTwo = [[response asString] copy];
        }];
      }
    }];

    assertEventuallyThat(&responseBodyOne, equalTo(@"pong"));
    assertEventuallyThat(&responseBodyTwo, equalTo(@"waff"));
  });
  
});

SPEC_END
