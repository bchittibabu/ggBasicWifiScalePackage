#import <Foundation/Foundation.h>

@interface GGScaleData : NSObject

@property (atomic, strong) NSString * ssid;

@property (atomic, strong) NSString * bssid;

@property (atomic, strong) NSString * userToken;

@property (atomic, strong) NSString * password;

@property (atomic) NSString * userNumber;

- (GGScaleData*)initWithData:(NSString *)ssid bssid:(NSString *)bssid token:(NSString *)userToken password:(NSString *)password number:(NSString *) userNumber;

@end
