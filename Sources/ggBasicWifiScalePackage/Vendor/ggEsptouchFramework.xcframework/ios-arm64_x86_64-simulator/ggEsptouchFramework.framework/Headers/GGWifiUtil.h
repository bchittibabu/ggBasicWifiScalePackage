#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "WifiConnectionData.h"

@interface GGWifiUtil : NSObject

@property (nonatomic) CLAuthorizationStatus locationStatus;

// Returns a the current CLAuthorizationStatus enum.
- (CLAuthorizationStatus)getLocationStatus;

// Returns true if location is authorized.
- (bool)isLocationAuthorized;

// Converts CLAuthorizationStatus eunm into a bool.
- (bool)checkLocationAccess:(CLAuthorizationStatus)status;

// Requests location permission while the app is in use
- (void)requestLocationWhenInUsePermission;

// Requests location permission at any time
- (void)requestLocationAllwaysAllowPermission;

// Returns a string version of CLAuthorizationStatus that can be passed through Cordova.
- (NSString*)getLocationStatusString:(CLAuthorizationStatus)status;

// Returns Wifi connection status. If connected, returns SSID and BSSID.
- (WifiConnectionData*)getWifiConnectionInfo;

// Returns a string version of WifiConnectionStatus that can be passed through Cordova.
- (NSString*)getWifiStatusString:(WifiConnectionStatus)status;

@end
