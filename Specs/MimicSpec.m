//
//  MimicSpec.h
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

NSData *stubRequest(NSString *path, NSInteger statusCode, NSString *body);

SPEC_BEGIN(MimicSpec)

describe(@"Testing using Mimic to stub HTTP requests", ^{

  it(@"should allow HTTP endpoints to be stubbed and immediately tested", ^{
    __block NSString *responseBody = nil;
    
    // ensure our POSTs to the Mimic API have the correct content-type
    [[LRResty client] attachRequestModifier:^(LRRestyRequest *req) {
      [req addHeader:@"Content-Type" value:@"application/plist"];
    }];
    
    // make sure all previous stubs are wiped out from other specs
    [[LRResty client] post:@"http://localhost:11988/api/clear" payload:nil withBlock:^(LRRestyResponse *response) {
      if (response.status == 200) {
        
        // configure the remote stub (Mimic running on localhost:11988)
        [[LRResty client] post:@"http://localhost:11988/api/get" 
                       payload:stubRequest(@"/ping", 200, @"pong") 
                     withBlock:^(LRRestyResponse *response) {
                       
         if (response.status == 201) {  
           
           // with the stub in place, let's send a request to the stubbed endpoint
           [[LRResty client] get:@"http://localhost:11988/ping" withBlock:^(LRRestyResponse *response) {
             responseBody = [[response asString] copy];
           }];
         }
        }];
      }
    }];
    
    // wait for the response body and check it is correct
    assertEventuallyThat(&responseBody, equalTo(@"pong"));
  });
  
});

SPEC_END

#pragma mark -
#pragma mark Helper functions

/**
 * Construct the payload for the Mimic API and return it in Plist format
 * ready to send in the REST API POST request.
 */
NSData *stubRequest(NSString *path, NSInteger statusCode, NSString *body) 
{
  NSMutableDictionary *request = [NSMutableDictionary dictionary];
  [request setObject:path forKey:@"path"];
  [request setObject:[NSNumber numberWithInteger:statusCode] forKey:@"code"];
  [request setObject:body forKey:@"body"];
  return [NSPropertyListSerialization dataFromPropertyList:(id)request
          format:NSPropertyListXMLFormat_v1_0 
          errorDescription:nil];
}

