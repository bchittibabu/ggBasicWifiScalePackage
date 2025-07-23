#import <Cordova/CDV.h>
#import "smartConfig.h"
#import "ConfigByAP.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import <ggEsptouchFramework/ggEsptouchFramework.h>

@interface wifiSmartConnect : CDVPlugin {
	smartConfig *smart;
	ConfigByAP *configByAP;
	NSString* connectionType;
	NSString* ssid;
	NSString* bssid;
	NSString* password;
	int userNumber;
	Byte userNumberByte;
	NSString* token;
	NSData *tokenData;    
}


- (void)smartConnect:(CDVInvokedUrlCommand*)command;
- (void)esptouchSmartConnect:(CDVInvokedUrlCommand*)command;
- (void)apMode:(CDVInvokedUrlCommand*)command;
- (void)stop:(CDVInvokedUrlCommand*)command;

@end
