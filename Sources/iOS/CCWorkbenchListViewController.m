#import "CCWorkbenchListViewController.h"
#import "CCConnectionProfile.h"
#import "CCLineRemoteControlAdapter.h"
#import "CCRemoteControl.h"

@implementation CCWorkbenchListViewController {
    NSArray *_titles;
    NSArray *_bodies;
    id<CCRemoteControlAdapter> _adapter;
}

@synthesize delegate = _delegate;

- (void)dealloc
{
    [_titles release];
    [_bodies release];
    [_adapter release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Workbench";
    _adapter = [[CCLineRemoteControlAdapter alloc] init];
    _titles = [[NSArray alloc] initWithObjects:@"Overview", @"Sessions", @"Files", @"Logs", @"Tasks", nil];
    _bodies = [[NSArray alloc] initWithObjects:
               [NSString stringWithFormat:@"Connection\n%@\n\nWorkspace\n%@\n\nBackend\nCodex remote-control adapter boundary is not connected yet. The current host shim is only for diagnostics.", [CCConnectionProfile summary], [CCConnectionProfile workspace]],
               [NSString stringWithFormat:@"Planned operation\n%@\n\nSessions will list Codex remote-control sessions here.", CCRemoteControlOperationListSessions],
               [NSString stringWithFormat:@"Planned operations\n%@\n%@\n\nFiles will use a left-pane navigator and right-pane code viewer.", CCRemoteControlOperationListFiles, CCRemoteControlOperationReadFile],
               [NSString stringWithFormat:@"Planned operation\n%@\n\nLogs will show backend and task output.", CCRemoteControlOperationTailLogs],
               [NSString stringWithFormat:@"Planned operations\n%@\n%@\n\nTasks will expose Codex remote-control work once the real backend adapter is available.", CCRemoteControlOperationStartTask, CCRemoteControlOperationCancelTask],
               nil];
}

- (NSString *)operationForTitle:(NSString *)title
{
    if ([title isEqualToString:@"Overview"]) {
        return CCRemoteControlOperationStatus;
    }
    if ([title isEqualToString:@"Sessions"]) {
        return CCRemoteControlOperationListSessions;
    }
    if ([title isEqualToString:@"Files"]) {
        return CCRemoteControlOperationListFiles;
    }
    return nil;
}

- (NSDictionary *)parametersForOperation:(NSString *)operation
{
    if ([operation isEqualToString:CCRemoteControlOperationListFiles]) {
        return [NSDictionary dictionaryWithObject:[CCConnectionProfile workspace] forKey:@"path"];
    }
    return nil;
}

- (NSString *)formattedSessions:(NSArray *)items
{
    NSMutableString *body = [NSMutableString string];
    NSUInteger index = 1;
    for (id item in items) {
        if (![item isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        NSDictionary *thread = (NSDictionary *)item;
        id rawName = [thread objectForKey:@"name"];
        NSString *name = [rawName isKindOfClass:[NSString class]] ? rawName : nil;
        if ([name length] == 0) {
            name = [thread objectForKey:@"preview"];
        }
        NSString *threadID = [thread objectForKey:@"id"];
        NSString *cwd = [thread objectForKey:@"cwd"];
        [body appendFormat:@"%lu. %@\n", (unsigned long)index, name];
        [body appendFormat:@"   id: %@\n", threadID];
        [body appendFormat:@"   cwd: %@\n\n", cwd];
        index++;
    }
    if ([body length] == 0) {
        [body appendString:@"No sessions returned."];
    }
    return body;
}

- (NSString *)formattedFiles:(NSArray *)items
{
    NSMutableString *body = [NSMutableString stringWithFormat:@"%@\n\n", [CCConnectionProfile workspace]];
    for (id item in items) {
        if (![item isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        NSDictionary *entry = (NSDictionary *)item;
        NSString *name = [entry objectForKey:@"fileName"];
        BOOL isDirectory = [[entry objectForKey:@"isDirectory"] boolValue];
        [body appendFormat:@"%@ %@\n", isDirectory ? @"[dir] " : @"      ", name];
    }
    return body;
}

- (NSString *)bodyForResult:(CCRemoteControlResult *)result title:(NSString *)title error:(NSError *)error
{
    if (result == nil) {
        return [error localizedDescription];
    }
    if ([title isEqualToString:@"Sessions"]) {
        return [self formattedSessions:result.items];
    }
    if ([title isEqualToString:@"Files"]) {
        return [self formattedFiles:result.items];
    }
    return result.detail;
}

- (void)loadRemoteTitle:(NSString *)title operation:(NSString *)operation
{
    NSDictionary *parameters = [self parametersForOperation:operation];
    [_delegate workbenchListDidSelectTitle:title body:@"Loading..."];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSError *error = nil;
        CCRemoteControlResult *result = [_adapter performOperation:operation parameters:parameters error:&error];
        NSString *body = [self bodyForResult:result title:title error:error];
        [title retain];
        [body retain];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate workbenchListDidSelectTitle:title body:body];
            [title release];
            [body release];
        });
        [pool drain];
    });
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
    NSString *operation = [self operationForTitle:title];
    if (operation != nil) {
        [self loadRemoteTitle:title operation:operation];
    } else {
        NSString *body = [_bodies objectAtIndex:(NSUInteger)indexPath.row];
        [_delegate workbenchListDidSelectTitle:title body:body];
    }
}

@end
