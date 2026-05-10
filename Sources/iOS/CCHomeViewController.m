#import "CCHomeViewController.h"
#import "CCConnectionProfile.h"
#import "CCRemoteClient.h"
#import "CCSettingsViewController.h"
#import "CCWorkbenchViewController.h"

@implementation CCHomeViewController {
    UILabel *_statusTitleLabel;
    UILabel *_statusValueLabel;
    UILabel *_connectionLabel;
    UILabel *_workspaceLabel;
    UILabel *_detailLabel;
    UIButton *_workbenchButton;
    UIButton *_settingsButton;
    CCRemoteClient *_client;
}

- (void)dealloc
{
    [_statusTitleLabel release];
    [_statusValueLabel release];
    [_connectionLabel release];
    [_workspaceLabel release];
    [_detailLabel release];
    [_workbenchButton release];
    [_settingsButton release];
    [_client release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"ClassicCode";
    self.view.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1.0];
    _client = [[CCRemoteClient alloc] init];

    _statusTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _statusTitleLabel.backgroundColor = [UIColor clearColor];
    _statusTitleLabel.font = [UIFont boldSystemFontOfSize:18.0];
    _statusTitleLabel.text = @"Connection";
    [self.view addSubview:_statusTitleLabel];

    _statusValueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _statusValueLabel.backgroundColor = [UIColor clearColor];
    _statusValueLabel.font = [UIFont boldSystemFontOfSize:30.0];
    _statusValueLabel.text = @"Checking";
    [self.view addSubview:_statusValueLabel];

    _connectionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _connectionLabel.backgroundColor = [UIColor clearColor];
    _connectionLabel.font = [UIFont systemFontOfSize:16.0];
    [self.view addSubview:_connectionLabel];

    _workspaceLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _workspaceLabel.backgroundColor = [UIColor clearColor];
    _workspaceLabel.font = [UIFont systemFontOfSize:16.0];
    [self.view addSubview:_workspaceLabel];

    _detailLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _detailLabel.backgroundColor = [UIColor clearColor];
    _detailLabel.font = [UIFont systemFontOfSize:14.0];
    _detailLabel.numberOfLines = 0;
    _detailLabel.textColor = [UIColor darkGrayColor];
    [self.view addSubview:_detailLabel];

    _workbenchButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
    [_workbenchButton setTitle:@"Open Workbench" forState:UIControlStateNormal];
    [_workbenchButton addTarget:self action:@selector(openWorkbench:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_workbenchButton];

    _settingsButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
    [_settingsButton setTitle:@"Settings" forState:UIControlStateNormal];
    [_settingsButton addTarget:self action:@selector(openSettings:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_settingsButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refreshLabels];
    [self refreshStatus];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    CGRect bounds = self.view.bounds;
    CGFloat margin = 24.0;
    CGFloat width = bounds.size.width - margin * 2.0;
    CGFloat y = 28.0;

    _statusTitleLabel.frame = CGRectMake(margin, y, width, 24.0);
    y += 34.0;
    _statusValueLabel.frame = CGRectMake(margin, y, width, 40.0);
    y += 52.0;
    _connectionLabel.frame = CGRectMake(margin, y, width, 24.0);
    y += 30.0;
    _workspaceLabel.frame = CGRectMake(margin, y, width, 24.0);
    y += 42.0;
    _detailLabel.frame = CGRectMake(margin, y, width, 92.0);

    CGFloat buttonWidth = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 220.0 : width;
    CGFloat buttonTop = bounds.size.height - 116.0;
    _workbenchButton.frame = CGRectMake(margin, buttonTop, buttonWidth, 44.0);
    _settingsButton.frame = CGRectMake(margin, buttonTop + 54.0, buttonWidth, 44.0);
}

- (void)refreshLabels
{
    _connectionLabel.text = [NSString stringWithFormat:@"Target: %@", [CCConnectionProfile summary]];
    _workspaceLabel.text = [NSString stringWithFormat:@"Workspace: %@", [CCConnectionProfile workspace]];
}

- (void)setStatus:(NSString *)status detail:(NSString *)detail
{
    _statusValueLabel.text = status;
    _detailLabel.text = detail;
}

- (void)refreshStatus
{
    [self setStatus:@"Checking" detail:@"Testing the configured remote-control endpoint."];
    NSString *host = [[CCConnectionProfile host] retain];
    NSInteger port = [CCConnectionProfile port];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSError *error = nil;
        NSString *response = [_client sendCommand:@"INFO" toHost:host port:port timeout:3.0 error:&error];
        NSString *status = nil;
        NSString *detail = nil;
        if ([response length] > 0) {
            status = @"Connected";
            detail = response;
        } else {
            status = @"Disconnected";
            detail = [error localizedDescription];
        }
        [status retain];
        [detail retain];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setStatus:status detail:detail];
            [status release];
            [detail release];
        });
        [host release];
        [pool drain];
    });
}

- (void)openSettings:(id)sender
{
    (void)sender;
    CCSettingsViewController *settings = [[[CCSettingsViewController alloc] init] autorelease];
    [self.navigationController pushViewController:settings animated:YES];
}

- (void)openWorkbench:(id)sender
{
    (void)sender;
    CCWorkbenchViewController *workbench = [[[CCWorkbenchViewController alloc] init] autorelease];
    [self.navigationController pushViewController:workbench animated:YES];
}

@end
