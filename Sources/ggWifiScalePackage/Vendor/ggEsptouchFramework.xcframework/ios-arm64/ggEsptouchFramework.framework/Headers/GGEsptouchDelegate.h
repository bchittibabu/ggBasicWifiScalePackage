//
//  GGEsptouchDelegate.h
//  esptouchTestApp-ios
//
//  Created by James Crow on 7/11/19.
//  Copyright © 2019 Greater Goods. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GGEsptouchHelper.h"
#import "GGScaleData.h"
#import "GGScanError.h"
#import "TcpResult.h"
#import <ggEsptouchFramework/ESPTouchResult.h>

@protocol GGEsptouchDelegate <NSObject>

@optional
// Called after data has been passed in, but before anything is started
- (void) beforeStart;

@optional
// Called after data is ready, but before execution is started
- (void) beforeExecute;

@optional
// Called after a result has been returned, but before it is checked
- (void) onPostExecute;

// Called if the scan fails
- (void) onFailure:(GGScanError)error message:(NSString *)errorMessage;

@optional
// Called after a device is discovered, but before a TCP connection is formed
- (void) onDeviceDiscovered:(ESPTouchResult *)result;

@optional
// Called after a TCP Connection is formed, but before data is sent
- (void) onTcpConnect;

@optional
// Called when TCP disconnects
- (void) onTcpDisconnect;

// Called after data is retruned over the TCP connection with a status of "OK"
- (void) onSuccess: (TcpResult *) tcpResult;

@end
