#import <UIKit/UIKit.h>

@interface CCWorkbenchDetailViewController : UIViewController

- (void)showTitle:(NSString *)title body:(NSString *)body;
- (void)showTitle:(NSString *)title body:(NSString *)body items:(NSArray *)items;

@end
