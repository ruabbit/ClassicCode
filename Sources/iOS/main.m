#import <UIKit/UIKit.h>
#import "CCAppDelegate.h"

int main(int argc, char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    int ret = UIApplicationMain(argc, argv, nil, NSStringFromClass([CCAppDelegate class]));
    [pool drain];
    return ret;
}
