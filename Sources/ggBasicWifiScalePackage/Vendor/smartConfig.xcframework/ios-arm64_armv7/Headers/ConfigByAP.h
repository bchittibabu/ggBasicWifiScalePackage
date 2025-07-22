//
//  ConfigByAP.h
//  testCrc
//
//  Created by aojinrui on 15/11/2.
//  Copyright (c) 2015年 aojinrui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
@interface ConfigByAP : NSObject<GCDAsyncSocketDelegate>{
    
}
- (long long)little_bytesToLong:(Byte [])b andLength:(int)length;
- (int )StartSmartConfigByApWithSSID:(NSString *)SSID andSetPassWord:(NSString *)Password andNumber:(Byte)number andTokenData:(NSData *)tokenData;
@end
