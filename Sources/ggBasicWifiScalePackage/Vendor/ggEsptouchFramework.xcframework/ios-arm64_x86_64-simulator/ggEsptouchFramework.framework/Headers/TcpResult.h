#import <Foundation/Foundation.h>

@interface TcpResult : NSObject

@property (atomic, strong) NSString * response;

@property (atomic, strong) NSString * devType;

@property (atomic, strong) NSString * dmac;

- (TcpResult*)initWithData:(NSString *)response devType:(NSString *)devType dmac:(NSString *)dmac;

@end
