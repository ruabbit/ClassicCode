#import "CCAppDelegate.h"
#import "CCRemoteClient.h"
#import "CCWire.h"

@interface CCRootViewController : UIViewController <UITextFieldDelegate>
@end

@implementation CCRootViewController {
    UITextField *_hostField;
    UITextField *_portField;
    UITextView *_logView;
    CCRemoteClient *_client;
}

- (void)dealloc
{
    [_hostField release];
    [_portField release];
    [_logView release];
    [_client release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"ClassicCode";
    self.view.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1.0];

    _client = [[CCRemoteClient alloc] init];

    _hostField = [[UITextField alloc] initWithFrame:CGRectZero];
    _hostField.borderStyle = UITextBorderStyleRoundedRect;
    _hostField.placeholder = @"Host";
    _hostField.text = CCWireDefaultHost;
    _hostField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _hostField.autocorrectionType = UITextAutocorrectionTypeNo;
    _hostField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    _hostField.delegate = self;
    [self.view addSubview:_hostField];

    _portField = [[UITextField alloc] initWithFrame:CGRectZero];
    _portField.borderStyle = UITextBorderStyleRoundedRect;
    _portField.placeholder = @"Port";
    _portField.text = [NSString stringWithFormat:@"%d", CCWireDefaultPort];
    _portField.keyboardType = UIKeyboardTypeNumberPad;
    _portField.delegate = self;
    [self.view addSubview:_portField];

    NSArray *items = [NSArray arrayWithObjects:@"HELLO", @"PING", @"INFO", nil];
    UISegmentedControl *commands = [[[UISegmentedControl alloc] initWithItems:items] autorelease];
    commands.segmentedControlStyle = UISegmentedControlStyleBar;
    commands.selectedSegmentIndex = 0;
    [commands addTarget:self action:@selector(commandChanged:) forControlEvents:UIControlEventValueChanged];
    commands.tag = 1001;
    [self.view addSubview:commands];

    UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [sendButton setTitle:@"Send" forState:UIControlStateNormal];
    [sendButton addTarget:self action:@selector(sendCommand:) forControlEvents:UIControlEventTouchUpInside];
    sendButton.tag = 1002;
    [self.view addSubview:sendButton];

    _logView = [[UITextView alloc] initWithFrame:CGRectZero];
    _logView.editable = NO;
    _logView.font = [UIFont fontWithName:@"Courier" size:13.0];
    _logView.text = @"Ready\n";
    [self.view addSubview:_logView];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    CGRect bounds = self.view.bounds;
    CGFloat margin = 12.0;
    CGFloat top = 16.0;
    CGFloat width = bounds.size.width - margin * 2.0;

    _hostField.frame = CGRectMake(margin, top, width * 0.66 - 4.0, 36.0);
    _portField.frame = CGRectMake(CGRectGetMaxX(_hostField.frame) + 8.0, top, width * 0.34 - 4.0, 36.0);

    UIView *commands = [self.view viewWithTag:1001];
    commands.frame = CGRectMake(margin, CGRectGetMaxY(_hostField.frame) + 10.0, width - 88.0, 36.0);

    UIView *sendButton = [self.view viewWithTag:1002];
    sendButton.frame = CGRectMake(CGRectGetMaxX(commands.frame) + 8.0, commands.frame.origin.y, 80.0, 36.0);

    _logView.frame = CGRectMake(margin, CGRectGetMaxY(commands.frame) + 10.0, width, bounds.size.height - CGRectGetMaxY(commands.frame) - 22.0);
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)appendLog:(NSString *)line
{
    NSString *text = [_logView.text stringByAppendingString:line];
    _logView.text = text;
    NSRange end = NSMakeRange([_logView.text length], 0);
    [_logView scrollRangeToVisible:end];
}

- (NSString *)selectedCommand
{
    UISegmentedControl *control = (UISegmentedControl *)[self.view viewWithTag:1001];
    if (control.selectedSegmentIndex == 1) {
        return @"PING";
    }
    if (control.selectedSegmentIndex == 2) {
        return @"INFO";
    }
    return @"HELLO";
}

- (void)commandChanged:(id)sender
{
    (void)sender;
}

- (void)sendCommand:(id)sender
{
    (void)sender;
    NSString *host = _hostField.text;
    NSInteger port = [_portField.text integerValue];
    NSString *command = [self selectedCommand];
    [self appendLog:[NSString stringWithFormat:@"> %@ %@:%d\n", command, host, (int)port]];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSError *error = nil;
        NSString *response = [_client sendCommand:command toHost:host port:port timeout:5.0 error:&error];
        NSString *line = response;
        if (line == nil) {
            line = [NSString stringWithFormat:@"ERR %@\n", [error localizedDescription]];
        }
        [line retain];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self appendLog:line];
            [line release];
        });
        [pool drain];
    });
}

@end

@implementation CCAppDelegate

@synthesize window = _window;

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    (void)application;
    (void)launchOptions;

    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    CCRootViewController *root = [[[CCRootViewController alloc] init] autorelease];
    UINavigationController *nav = [[[UINavigationController alloc] initWithRootViewController:root] autorelease];
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
