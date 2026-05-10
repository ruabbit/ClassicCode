#import "CCHomeViewController.h"
#import "CCConnectionProfile.h"
#import "CCLineRemoteControlAdapter.h"
#import "CCSettingsViewController.h"
#import "CCWorkbenchViewController.h"

@interface CCHomeViewController () <UITableViewDataSource, UITableViewDelegate>
@end

@implementation CCHomeViewController {
    UILabel *_statusTitleLabel;
    UILabel *_statusValueLabel;
    UILabel *_connectionLabel;
    UILabel *_detailLabel;
    UILabel *_workspaceTitleLabel;
    UITableView *_workspaceTableView;
    NSArray *_workspaces;
    UIButton *_refreshButton;
    UIButton *_workbenchButton;
    UIButton *_settingsButton;
    id<CCRemoteControlAdapter> _adapter;
}

- (void)dealloc
{
    [_statusTitleLabel release];
    [_statusValueLabel release];
    [_connectionLabel release];
    [_detailLabel release];
    [_workspaceTitleLabel release];
    [_workspaceTableView release];
    [_workspaces release];
    [_refreshButton release];
    [_workbenchButton release];
    [_settingsButton release];
    [_adapter release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"ClassicCode";
    self.view.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1.0];
    _adapter = [[CCLineRemoteControlAdapter alloc] init];
    _workspaces = [[NSArray alloc] init];

    _statusTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _statusTitleLabel.backgroundColor = [UIColor clearColor];
    _statusTitleLabel.font = [UIFont boldSystemFontOfSize:13.0];
    _statusTitleLabel.textColor = [UIColor darkGrayColor];
    _statusTitleLabel.text = @"Status";
    [self.view addSubview:_statusTitleLabel];

    _statusValueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _statusValueLabel.backgroundColor = [UIColor clearColor];
    _statusValueLabel.font = [UIFont boldSystemFontOfSize:18.0];
    _statusValueLabel.text = @"Checking";
    [self.view addSubview:_statusValueLabel];

    _connectionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _connectionLabel.backgroundColor = [UIColor clearColor];
    _connectionLabel.font = [UIFont systemFontOfSize:14.0];
    [self.view addSubview:_connectionLabel];

    _detailLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _detailLabel.backgroundColor = [UIColor clearColor];
    _detailLabel.font = [UIFont systemFontOfSize:12.0];
    _detailLabel.numberOfLines = 0;
    _detailLabel.textColor = [UIColor darkGrayColor];
    [self.view addSubview:_detailLabel];

    _workspaceTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _workspaceTitleLabel.backgroundColor = [UIColor clearColor];
    _workspaceTitleLabel.font = [UIFont boldSystemFontOfSize:16.0];
    _workspaceTitleLabel.text = @"Workspace";
    [self.view addSubview:_workspaceTitleLabel];

    _workspaceTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _workspaceTableView.dataSource = self;
    _workspaceTableView.delegate = self;
    _workspaceTableView.rowHeight = 48.0;
    [self.view addSubview:_workspaceTableView];

    _refreshButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
    [_refreshButton setTitle:@"Refresh" forState:UIControlStateNormal];
    [_refreshButton addTarget:self action:@selector(refreshAll:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_refreshButton];

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
    [self refreshAll:nil];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    CGRect bounds = self.view.bounds;
    CGFloat margin = 24.0;
    CGFloat width = bounds.size.width - margin * 2.0;
    CGFloat y = 18.0;

    _statusTitleLabel.frame = CGRectMake(margin, y, 90.0, 24.0);
    _statusValueLabel.frame = CGRectMake(margin + 92.0, y, width - 92.0, 24.0);
    y += 30.0;
    _connectionLabel.frame = CGRectMake(margin, y, width, 24.0);
    y += 26.0;
    _detailLabel.frame = CGRectMake(margin, y, width, 44.0);
    y += 52.0;
    _workspaceTitleLabel.frame = CGRectMake(margin, y, width, 24.0);
    y += 30.0;

    CGFloat buttonTop = bounds.size.height - 116.0;
    CGFloat workbenchWidth = width - 108.0;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && workbenchWidth > 220.0) {
        workbenchWidth = 220.0;
    }
    _workspaceTableView.frame = CGRectMake(margin, y, width, MAX(80.0, buttonTop - y - 12.0));
    _refreshButton.frame = CGRectMake(margin, buttonTop, 96.0, 44.0);
    _workbenchButton.frame = CGRectMake(margin + 108.0, buttonTop, workbenchWidth, 44.0);
    _settingsButton.frame = CGRectMake(margin, buttonTop + 54.0, width, 44.0);
}

- (void)refreshLabels
{
    _connectionLabel.text = [NSString stringWithFormat:@"Endpoint: %@", [CCConnectionProfile summary]];
}

- (void)setStatus:(NSString *)status detail:(NSString *)detail
{
    _statusValueLabel.text = status;
    _detailLabel.text = detail;
}

- (NSString *)detailForStatusResult:(CCRemoteControlResult *)result error:(NSError *)error
{
    if (result == nil || ![result.state isEqualToString:@"connected"]) {
        NSString *message = [error localizedDescription];
        if ([message length] == 0) {
            message = result.detail;
        }
        if ([message length] == 0) {
            message = @"Endpoint unavailable";
        }
        return [NSString stringWithFormat:@"%@. Settings changes the endpoint; Workspace stays here.", message];
    }
    return @"Connection OK. Select a workspace below.";
}

- (NSArray *)fallbackWorkspaces
{
    NSString *workspace = [CCConnectionProfile workspace];
    NSDictionary *item = [NSDictionary dictionaryWithObjectsAndKeys:
                          workspace, @"path",
                          workspace, @"label",
                          nil];
    return [NSArray arrayWithObject:item];
}

- (void)refreshAll:(id)sender
{
    (void)sender;
    [self refreshLabels];
    [self setStatus:@"Checking" detail:@"Checking endpoint and workspace list."];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSError *error = nil;
        CCRemoteControlResult *statusResult = [_adapter performOperation:CCRemoteControlOperationStatus parameters:nil error:&error];
        NSString *status = statusResult.summary;
        NSString *detail = [self detailForStatusResult:statusResult error:error];
        NSArray *items = nil;

        if ([statusResult.state isEqualToString:@"connected"]) {
            NSError *workspaceError = nil;
            CCRemoteControlResult *workspaceResult = [_adapter performOperation:CCRemoteControlOperationListWorkspaces parameters:nil error:&workspaceError];
            items = workspaceResult.items;
            if ([items count] == 0 && workspaceError != nil) {
                detail = [workspaceError localizedDescription];
            }
        }
        if ([status length] == 0) {
            status = @"Disconnected";
        }
        if ([items count] == 0) {
            items = [self fallbackWorkspaces];
        }

        [status retain];
        [detail retain];
        [items retain];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_workspaces release];
            _workspaces = [items retain];
            [_workspaceTableView reloadData];
            [self setStatus:status detail:detail];
            [status release];
            [detail release];
            [items release];
        });
        [pool drain];
    });
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    (void)tableView;
    (void)section;
    return [_workspaces count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"WorkspaceCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID] autorelease];
    }

    NSDictionary *workspace = [_workspaces objectAtIndex:(NSUInteger)indexPath.row];
    NSString *path = [workspace objectForKey:@"path"];
    NSString *label = [workspace objectForKey:@"label"];
    if ([label length] == 0) {
        label = path;
    }
    cell.textLabel.text = label;
    cell.detailTextLabel.text = path;
    cell.accessoryType = [path isEqualToString:[CCConnectionProfile workspace]] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *workspace = [_workspaces objectAtIndex:(NSUInteger)indexPath.row];
    NSString *path = [workspace objectForKey:@"path"];
    if ([path length] > 0) {
        [CCConnectionProfile saveWorkspace:path];
        [tableView reloadData];
        [self setStatus:_statusValueLabel.text detail:@"Workspace selected. Open Workbench to browse sessions and files."];
    }
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
