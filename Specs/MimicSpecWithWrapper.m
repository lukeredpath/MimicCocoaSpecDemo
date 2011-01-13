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
      [[mimic get:@"/ping"] andReturnResponse:@"pong" withStatus:200];
    }];
    
    [LRMimic stubAndCall:^(BOOL success) {
      if (success) {
        [[LRResty client] get:@"http://localhost:11988/ping" withBlock:^(LRRestyResponse *response) {
          responseBody = [[response asString] copy];
        }];
      }
    }];
    
    // wait for the response body and check it is correct
    assertEventuallyThat(&responseBody, equalTo(@"pong"));
  });
  
});

SPEC_END
