#import <Foundation/Foundation.h>
#import "WifiConnectionStatus.h"

@interface WifiConnectionData : NSObject

@property (atomic) WifiConnectionStatus status;

@property (atomic, strong) NSString * ssid;

@property (atomic, strong) NSString * bssid;

@end
