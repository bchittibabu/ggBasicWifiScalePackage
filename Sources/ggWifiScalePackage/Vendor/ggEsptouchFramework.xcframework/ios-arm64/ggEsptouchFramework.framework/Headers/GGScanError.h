#import <Foundation/Foundation.h>

typedef enum
{
	CANCELLED = 0,
	NO_RESULT = 1,
	TIMEOUT = 2,
	TCP_START_FAIL = 3,
	TCP_SEND_FAIL = 4,
	TCP_BAD_RESPONSE = 5,
	UNKNOWN = 6

} GGScanError;
