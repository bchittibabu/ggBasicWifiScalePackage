#import <Foundation/Foundation.h>
#import <ggEsptouchFramework/ggEsptouchFramework.h>

#import "GGScaleData.h"
#import "GGEsptouchDelegate.h"

@interface GGEsptouchHelper : NSObject
// Called to return singleton object
+ (GGEsptouchHelper *) getInstance;

// Starts the setup broadcast
- (BOOL) beginSmartConnect: (GGScaleData *)data delegate:(NSObject<GGEsptouchDelegate> *)delegate;

// Returns a GGScanError enum from an int.
// Needed due to Objective C/Swift issues
- (GGScanError) getErrorFromInt:(int)value;

// Gets a Cordova friendly string from a GGScanError enum.
- (NSString*) getErrorString:(GGScanError)value;

// Stops the current task
- (BOOL) stopTask;

// Clears the current task. Call this when done.
- (BOOL) clearTask;
@end
