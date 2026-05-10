#import "CCWorkbenchListViewController.h"
#import "CCConnectionProfile.h"
#import "CCLineRemoteControlAdapter.h"
#import "CCRemoteControl.h"

enum {
    CCWorkbenchSectionConversations = 0,
    CCWorkbenchSectionFiles = 1,
    CCWorkbenchSectionCount = 2
};

@implementation CCWorkbenchListViewController {
    NSArray *_conversations;
    NSArray *_files;
    NSString *_currentPath;
    id<CCRemoteControlAdapter> _adapter;
}

@synthesize delegate = _delegate;

- (void)dealloc
{
    [_conversations release];
    [_files release];
    [_currentPath release];
    [_adapter release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _adapter = [[CCLineRemoteControlAdapter alloc] init];
    _conversations = [[NSArray alloc] init];
    _files = [[NSArray alloc] init];
    _currentPath = [[CCConnectionProfile workspace] retain];
    self.title = [self workspaceTitle];
    self.tableView.rowHeight = 52.0;
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh:)] autorelease];
    [self loadWorkspaceObjects];
}

- (NSString *)workspaceTitle
{
    NSString *workspace = [CCConnectionProfile workspace];
    NSString *last = [workspace lastPathComponent];
    return [last length] > 0 ? last : workspace;
}

- (NSString *)filePathForEntry:(NSDictionary *)entry
{
    NSString *name = [self stringValue:[entry objectForKey:@"fileName"]];
    if ([name length] == 0) {
        return _currentPath;
    }
    return [_currentPath stringByAppendingPathComponent:name];
}

- (NSString *)conversationTitle:(NSDictionary *)thread
{
    id rawName = [thread objectForKey:@"name"];
    NSString *name = [rawName isKindOfClass:[NSString class]] ? rawName : nil;
    if ([name length] == 0) {
        name = [thread objectForKey:@"preview"];
    }
    if ([name length] == 0) {
        name = [thread objectForKey:@"id"];
    }
    return name;
}

- (NSString *)stringValue:(id)value
{
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }
    return @"";
}

- (void)setConversations:(NSArray *)conversations files:(NSArray *)files
{
    [_conversations release];
    _conversations = [conversations retain];
    [_files release];
    _files = [files retain];
    [self.tableView reloadData];
}

- (void)loadWorkspaceObjects
{
    NSString *workspace = [CCConnectionProfile workspace];
    NSString *path = _currentPath;
    self.title = [self workspaceTitle];
    [_delegate workbenchListDidSelectTitle:self.title body:@"Loading workspace..."];
    [workspace retain];
    [path retain];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSDictionary *sessionParams = [NSDictionary dictionaryWithObject:workspace forKey:@"workspace"];
        NSDictionary *fileParams = [NSDictionary dictionaryWithObject:path forKey:@"path"];
        NSError *sessionError = nil;
        NSError *fileError = nil;
        CCRemoteControlResult *sessionResult = [_adapter performOperation:CCRemoteControlOperationListSessions parameters:sessionParams error:&sessionError];
        CCRemoteControlResult *fileResult = [_adapter performOperation:CCRemoteControlOperationListFiles parameters:fileParams error:&fileError];
        NSArray *conversations = sessionResult.items;
        NSArray *files = fileResult.items;
        BOOL filesConnected = [fileResult.state isEqualToString:@"connected"];
        NSString *body = nil;
        if ([sessionResult.state isEqualToString:@"connected"] || [fileResult.state isEqualToString:@"connected"]) {
            body = [NSString stringWithFormat:@"%@\n\n%lu conversations\n%lu files/directories",
                    workspace,
                    (unsigned long)[conversations count],
                    (unsigned long)[files count]];
        } else {
            body = [NSString stringWithFormat:@"Could not load workspace.\n\n%@\n%@",
                    [sessionError localizedDescription],
                    [fileError localizedDescription]];
        }
        [conversations retain];
        [files retain];
        [body retain];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setConversations:conversations files:files];
            if (filesConnected) {
                [_delegate workbenchListDidSelectDirectoryTitle:[path lastPathComponent] path:path entries:files];
            } else {
                [_delegate workbenchListDidSelectTitle:self.title body:body];
            }
            [conversations release];
            [files release];
            [body release];
            [workspace release];
            [path release];
        });
        [pool drain];
    });
}

- (void)refresh:(id)sender
{
    (void)sender;
    [self loadWorkspaceObjects];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    (void)tableView;
    return CCWorkbenchSectionCount;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    (void)tableView;
    if (section == CCWorkbenchSectionConversations) {
        return @"Conversations";
    }
    return _currentPath;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    (void)tableView;
    if (section == CCWorkbenchSectionConversations) {
        return [_conversations count];
    }
    NSInteger count = [_files count];
    if (![_currentPath isEqualToString:[CCConnectionProfile workspace]]) {
        count++;
    }
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"WorkbenchObjectCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID] autorelease];
    }

    cell.detailTextLabel.text = nil;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    if (indexPath.section == CCWorkbenchSectionConversations) {
        NSDictionary *thread = [_conversations objectAtIndex:(NSUInteger)indexPath.row];
        cell.textLabel.text = [self conversationTitle:thread];
        cell.detailTextLabel.text = [self stringValue:[thread objectForKey:@"id"]];
        return cell;
    }

    BOOL hasParentRow = ![_currentPath isEqualToString:[CCConnectionProfile workspace]];
    if (hasParentRow && indexPath.row == 0) {
        cell.textLabel.text = @"..";
        cell.detailTextLabel.text = [_currentPath stringByDeletingLastPathComponent];
        return cell;
    }

    NSInteger fileIndex = indexPath.row - (hasParentRow ? 1 : 0);
    NSDictionary *entry = [_files objectAtIndex:(NSUInteger)fileIndex];
    NSString *name = [self stringValue:[entry objectForKey:@"fileName"]];
    BOOL isDirectory = [[entry objectForKey:@"isDirectory"] boolValue];
    cell.textLabel.text = name;
    cell.detailTextLabel.text = isDirectory ? @"Directory" : @"File";
    return cell;
}

- (void)showLoadingTitle:(NSString *)title
{
    [_delegate workbenchListDidSelectTitle:title body:@"Loading..."];
}

- (void)openConversation:(NSDictionary *)thread
{
    NSString *threadID = [self stringValue:[thread objectForKey:@"id"]];
    if ([threadID length] == 0) {
        return;
    }
    NSString *title = [self conversationTitle:thread];
    [self showLoadingTitle:title];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSError *error = nil;
        NSDictionary *params = [NSDictionary dictionaryWithObject:threadID forKey:@"threadId"];
        CCRemoteControlResult *result = [_adapter performOperation:CCRemoteControlOperationGetTranscript parameters:params error:&error];
        NSString *body = result.detail;
        NSArray *items = result.items;
        if ([body length] == 0) {
            body = [error localizedDescription];
        }
        [title retain];
        [body retain];
        [items retain];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate workbenchListDidSelectTitle:title body:body items:items];
            [title release];
            [body release];
            [items release];
        });
        [pool drain];
    });
}

- (void)openFileAtPath:(NSString *)path title:(NSString *)title
{
    [self showLoadingTitle:title];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSError *error = nil;
        NSDictionary *params = [NSDictionary dictionaryWithObject:path forKey:@"path"];
        CCRemoteControlResult *result = [_adapter performOperation:CCRemoteControlOperationReadFile parameters:params error:&error];
        NSString *body = result.detail;
        if ([body length] == 0) {
            body = [error localizedDescription];
        }
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == CCWorkbenchSectionConversations) {
        [self openConversation:[_conversations objectAtIndex:(NSUInteger)indexPath.row]];
        return;
    }

    BOOL hasParentRow = ![_currentPath isEqualToString:[CCConnectionProfile workspace]];
    if (hasParentRow && indexPath.row == 0) {
        [_currentPath release];
        _currentPath = [[_currentPath stringByDeletingLastPathComponent] retain];
        [self loadWorkspaceObjects];
        return;
    }

    NSInteger fileIndex = indexPath.row - (hasParentRow ? 1 : 0);
    NSDictionary *entry = [_files objectAtIndex:(NSUInteger)fileIndex];
    NSString *path = [self filePathForEntry:entry];
    if ([[entry objectForKey:@"isDirectory"] boolValue]) {
        [_currentPath release];
        _currentPath = [path retain];
        [self loadWorkspaceObjects];
    } else {
        [self openFileAtPath:path title:[entry objectForKey:@"fileName"]];
    }
}

@end
