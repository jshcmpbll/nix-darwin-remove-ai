#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <objc/runtime.h>

static NSString *const kFramework =
    @"/System/Library/PrivateFrameworks/UnifiedAssetFramework.framework/UnifiedAssetFramework";
static NSString *const kService = @"com.apple.siri.uaf.subscription.service";

@interface NSObject (UAFPrivate)
+ (id)latestStatusForClients:(NSString *)name error:(NSError **)error;
+ (NSXPCInterface *)defaultInterface;
- (int64_t)downloadedFilesystemBytes;
- (oneway void)operationWithConfig:(NSDictionary *)config completion:(void (^)(NSError *))completion;
@end

static int bytes(NSString *set) {
  Class manager = NSClassFromString(@"UAFAutoAssetManager");
  if (![manager respondsToSelector:@selector(latestStatusForClients:error:)]) {
    fprintf(stderr, "asset status interface unavailable\n");
    return 1;
  }
  NSError *error = nil;
  id status = [manager latestStatusForClients:set error:&error];
  if (![status respondsToSelector:@selector(downloadedFilesystemBytes)]) {
    fprintf(stderr, "%s: no status (%s)\n", set.UTF8String, error.localizedDescription.UTF8String);
    return 1;
  }
  printf("%s\t%lld\n", set.UTF8String, [status downloadedFilesystemBytes]);
  return 0;
}

static int reset(NSArray<NSString *> *sets) {
  Class iface = NSClassFromString(@"UAFXPCProxyServiceInterface");
  if (![iface respondsToSelector:@selector(defaultInterface)]) {
    fprintf(stderr, "asset service interface unavailable\n");
    return 1;
  }
  NSXPCConnection *connection = [[NSXPCConnection alloc] initWithMachServiceName:kService options:0];
  connection.remoteObjectInterface = [iface defaultInterface];
  [connection resume];

  SEL op = @selector(operationWithConfig:completion:);
  Protocol *protocol = connection.remoteObjectInterface.protocol;
  if (!protocol_getMethodDescription(protocol, op, YES, YES).name &&
      !protocol_getMethodDescription(protocol, op, NO, YES).name) {
    fprintf(stderr, "asset service does not accept operations\n");
    return 1;
  }

  dispatch_semaphore_t done = dispatch_semaphore_create(0);
  __block int status = 0;
  void (^finish)(NSError *) = ^(NSError *e) {
    if (e) {
      fprintf(stderr, "reset failed: %s\n", e.localizedDescription.UTF8String);
      status = 1;
    }
    dispatch_semaphore_signal(done);
  };
  id proxy = [connection remoteObjectProxyWithErrorHandler:finish];
  [proxy operationWithConfig:@{@"Operation" : @"ResetAssetSets", @"AssetSets" : sets}
                  completion:finish];
  if (dispatch_semaphore_wait(done, dispatch_time(DISPATCH_TIME_NOW, 120 * NSEC_PER_SEC))) {
    fprintf(stderr, "timed out waiting for the asset service\n");
    status = 1;
  }
  [connection invalidate];
  return status;
}

int main(int argc, char **argv) {
  @autoreleasepool {
    if (argc < 3 || !dlopen(kFramework.fileSystemRepresentation, RTLD_NOW)) {
      fprintf(stderr, "usage: uaf-tool bytes|reset <asset set>...\n");
      return 2;
    }
    NSMutableArray *sets = [NSMutableArray array];
    for (int i = 2; i < argc; i++) [sets addObject:@(argv[i])];
    if (strcmp(argv[1], "reset") == 0) return reset(sets);
    if (strcmp(argv[1], "bytes") == 0) {
      int rc = 0;
      for (NSString *s in sets) rc |= bytes(s);
      return rc;
    }
    fprintf(stderr, "unknown command %s\n", argv[1]);
    return 2;
  }
}
