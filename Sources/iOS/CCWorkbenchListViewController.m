#import "CCWorkbenchListViewController.h"
#import "CCConnectionProfile.h"
#import "CCRemoteControl.h"

@implementation CCWorkbenchListViewController {
    NSArray *_titles;
    NSArray *_bodies;
}

@synthesize delegate = _delegate;

- (void)dealloc
{
    [_titles release];
    [_bodies release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Workbench";
    _titles = [[NSArray alloc] initWithObjects:@"Overview", @"Sessions", @"Files", @"Logs", @"Tasks", nil];
    _bodies = [[NSArray alloc] initWithObjects:
               [NSString stringWithFormat:@"Connection\n%@\n\nWorkspace\n%@\n\nBackend\nCodex remote-control adapter boundary is not connected yet. The current host shim is only for diagnostics.", [CCConnectionProfile summary], [CCConnectionProfile workspace]],
               [NSString stringWithFormat:@"Planned operation\n%@\n\nSessions will list Codex remote-control sessions here.", CCRemoteControlOperationListSessions],
               [NSString stringWithFormat:@"Planned operations\n%@\n%@\n\nFiles will use a left-pane navigator and right-pane code viewer.", CCRemoteControlOperationListFiles, CCRemoteControlOperationReadFile],
               [NSString stringWithFormat:@"Planned operation\n%@\n\nLogs will show backend and task output.", CCRemoteControlOperationTailLogs],
               [NSString stringWithFormat:@"Planned operations\n%@\n%@\n\nTasks will expose Codex remote-control work once the real backend adapter is available.", CCRemoteControlOperationStartTask, CCRemoteControlOperationCancelTask],
               nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    (void)tableView;
    (void)section;
    return [_titles count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"WorkbenchCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    cell.textLabel.text = [_titles objectAtIndex:(NSUInteger)indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *title = [_titles objectAtIndex:(NSUInteger)indexPath.row];
    NSString *body = [_bodies objectAtIndex:(NSUInteger)indexPath.row];
    [_delegate workbenchListDidSelectTitle:title body:body];
}

@end
