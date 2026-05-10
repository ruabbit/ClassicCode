#import "CCWorkbenchViewController.h"
#import "CCConnectionProfile.h"
#import "CCWorkbenchDetailViewController.h"
#import "CCWorkbenchListViewController.h"

@interface CCWorkbenchViewController () <CCWorkbenchListViewControllerDelegate>
@end

@implementation CCWorkbenchViewController {
    CCWorkbenchListViewController *_listController;
    CCWorkbenchDetailViewController *_detailController;
    UIView *_sidebarHeaderView;
    UILabel *_sidebarTitleLabel;
    UIToolbar *_sidebarComposeToolbar;
    UIView *_sidebarHeaderLine;
}

- (void)dealloc
{
    [_listController release];
    [_detailController release];
    [_sidebarHeaderView release];
    [_sidebarTitleLabel release];
    [_sidebarComposeToolbar release];
    [_sidebarHeaderLine release];
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

    _sidebarHeaderView = [[UIView alloc] initWithFrame:CGRectZero];
    _sidebarHeaderView.backgroundColor = [UIColor colorWithRed:0.86 green:0.91 blue:0.94 alpha:1.0];
    [self.view addSubview:_sidebarHeaderView];

    _sidebarTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _sidebarTitleLabel.backgroundColor = [UIColor clearColor];
    _sidebarTitleLabel.font = [UIFont boldSystemFontOfSize:16.0];
    NSString *workspace = [CCConnectionProfile workspace];
    NSString *workspaceName = [workspace lastPathComponent];
    _sidebarTitleLabel.text = [workspaceName length] > 0 ? workspaceName : workspace;
    [_sidebarHeaderView addSubview:_sidebarTitleLabel];

    _sidebarComposeToolbar = [[UIToolbar alloc] initWithFrame:CGRectZero];
    _sidebarComposeToolbar.barStyle = UIBarStyleDefault;
    UIBarButtonItem *compose = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                                                                              target:self
                                                                              action:@selector(newConversation:)] autorelease];
    _sidebarComposeToolbar.items = [NSArray arrayWithObject:compose];
    [_sidebarHeaderView addSubview:_sidebarComposeToolbar];

    _sidebarHeaderLine = [[UIView alloc] initWithFrame:CGRectZero];
    _sidebarHeaderLine.backgroundColor = [UIColor colorWithWhite:0.72 alpha:1.0];
    [_sidebarHeaderView addSubview:_sidebarHeaderLine];

    _listController = [[CCWorkbenchListViewController alloc] initWithStyle:UITableViewStylePlain];
    _listController.delegate = self;
    _detailController = [[CCWorkbenchDetailViewController alloc] init];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        _sidebarHeaderView.hidden = NO;
        [self addChildViewController:_listController];
        [self.view addSubview:_listController.view];
        [_listController didMoveToParentViewController:self];

        [self addChildViewController:_detailController];
        [self.view addSubview:_detailController.view];
        [_detailController didMoveToParentViewController:self];
    } else {
        _sidebarHeaderView.hidden = YES;
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.navigationController setNavigationBarHidden:YES animated:animated];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.navigationController setNavigationBarHidden:NO animated:animated];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    CGRect bounds = self.view.bounds;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        CGFloat listWidth = 300.0;
        CGFloat headerHeight = 48.0;
        _sidebarHeaderView.frame = CGRectMake(0.0, 0.0, listWidth, headerHeight);
        _sidebarTitleLabel.frame = CGRectMake(18.0, 6.0, listWidth - 72.0, headerHeight - 12.0);
        _sidebarComposeToolbar.frame = CGRectMake(listWidth - 52.0, 2.0, 44.0, 44.0);
        _sidebarHeaderLine.frame = CGRectMake(0.0, headerHeight - 1.0, listWidth, 1.0);
        _listController.view.frame = CGRectMake(0.0, headerHeight, listWidth, bounds.size.height - headerHeight);
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
