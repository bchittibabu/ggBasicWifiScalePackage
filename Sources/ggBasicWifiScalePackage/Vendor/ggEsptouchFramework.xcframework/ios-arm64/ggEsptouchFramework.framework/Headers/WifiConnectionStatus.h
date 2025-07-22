#import <Foundation/Foundation.h>

typedef enum
{
	WIFI_UNKNOWN = 0,
	WIFI_CONNECTED = 1,
	// This can mean wifi is disabled, or just not connected
	WIFI_DISCONNECTED = 2,
	WIFI_LOCATION_UNAVAILABLE = 3
} WifiConnectionStatus;
