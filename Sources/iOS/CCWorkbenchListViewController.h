#import <UIKit/UIKit.h>

@protocol CCWorkbenchListViewControllerDelegate;

@interface CCWorkbenchListViewController : UITableViewController

@property (nonatomic, assign) id<CCWorkbenchListViewControllerDelegate> delegate;

@end

@protocol CCWorkbenchListViewControllerDelegate <NSObject>
- (void)workbenchListDidSelectTitle:(NSString *)title body:(NSString *)body;
- (void)workbenchListDidSelectTitle:(NSString *)title body:(NSString *)body items:(NSArray *)items;
@end
