#import "CCWorkbenchViewController.h"
#import "CCWorkbenchDetailViewController.h"
#import "CCWorkbenchListViewController.h"

@interface CCWorkbenchViewController () <CCWorkbenchListViewControllerDelegate>
@end

@implementation CCWorkbenchViewController {
    CCWorkbenchListViewController *_listController;
    CCWorkbenchDetailViewController *_detailController;
}

- (void)dealloc
{
    [_listController release];
    [_detailController release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Workbench";
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                                                                                            target:self
                                                                                            action:@selector(newConversation:)] autorelease];

    _listController = [[CCWorkbenchListViewController alloc] initWithStyle:UITableViewStylePlain];
    _listController.delegate = self;
    _detailController = [[CCWorkbenchDetailViewController alloc] init];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self addChildViewController:_listController];
        [self.view addSubview:_listController.view];
        [_listController didMoveToParentViewController:self];

        [self addChildViewController:_detailController];
        [self.view addSubview:_detailController.view];
        [_detailController didMoveToParentViewController:self];
    } else {
        [self addChildViewController:_listController];
        [self.view addSubview:_listController.view];
        [_listController didMoveToParentViewController:self];
    }
}

- (void)newConversation:(id)sender
{
    (void)sender;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [_detailController beginNewConversation];
    } else {
        CCWorkbenchDetailViewController *detail = [[[CCWorkbenchDetailViewController alloc] init] autorelease];
        [self.navigationController pushViewController:detail animated:YES];
        [detail beginNewConversation];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    CGRect bounds = self.view.bounds;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        CGFloat listWidth = 300.0;
        _listController.view.frame = CGRectMake(0.0, 0.0, listWidth, bounds.size.height);
        _detailController.view.frame = CGRectMake(listWidth, 0.0, bounds.size.width - listWidth, bounds.size.height);
    } else {
        _listController.view.frame = bounds;
    }
}

- (void)workbenchListDidSelectTitle:(NSString *)title body:(NSString *)body
{
    [self workbenchListDidSelectTitle:title body:body items:nil];
}

- (void)workbenchListDidSelectTitle:(NSString *)title body:(NSString *)body items:(NSArray *)items
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [_detailController showTitle:title body:body items:items];
    } else {
        CCWorkbenchDetailViewController *detail = [[[CCWorkbenchDetailViewController alloc] init] autorelease];
        [self.navigationController pushViewController:detail animated:YES];
        [detail showTitle:title body:body items:items];
    }
}

- (void)workbenchListDidSelectDirectoryTitle:(NSString *)title path:(NSString *)path entries:(NSArray *)entries
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [_detailController showDirectoryWithTitle:title path:path entries:entries];
    } else {
        CCWorkbenchDetailViewController *detail = [[[CCWorkbenchDetailViewController alloc] init] autorelease];
        [self.navigationController pushViewController:detail animated:YES];
        [detail showDirectoryWithTitle:title path:path entries:entries];
    }
}

@end
