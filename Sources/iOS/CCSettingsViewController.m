#import "CCSettingsViewController.h"
#import "CCConnectionProfile.h"
#import "CCLineRemoteControlAdapter.h"

@implementation CCSettingsViewController {
    UIScrollView *_scrollView;
    UITextField *_displayNameField;
    UITextField *_hostField;
    UITextField *_portField;
    UILabel *_diagnosticLabel;
    UIButton *_testButton;
    id<CCRemoteControlAdapter> _adapter;
}

- (void)dealloc
{
    [_scrollView release];
    [_displayNameField release];
    [_hostField release];
    [_portField release];
    [_diagnosticLabel release];
    [_testButton release];
    [_adapter release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Settings";
    self.view.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1.0];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save:)] autorelease];
    _adapter = [[CCLineRemoteControlAdapter alloc] init];

    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:_scrollView];

    _displayNameField = [[self newTextFieldWithPlaceholder:@"Display Name"] retain];
    _displayNameField.text = [CCConnectionProfile displayName];
    [_scrollView addSubview:_displayNameField];

    _hostField = [[self newTextFieldWithPlaceholder:@"Host"] retain];
    _hostField.text = [CCConnectionProfile host];
    _hostField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    [_scrollView addSubview:_hostField];

    _portField = [[self newTextFieldWithPlaceholder:@"Port"] retain];
    _portField.text = [NSString stringWithFormat:@"%d", (int)[CCConnectionProfile port]];
    _portField.keyboardType = UIKeyboardTypeNumberPad;
    [_scrollView addSubview:_portField];

    _testButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
    [_testButton setTitle:@"Test Connection" forState:UIControlStateNormal];
    [_testButton addTarget:self action:@selector(testConnection:) forControlEvents:UIControlEventTouchUpInside];
    [_scrollView addSubview:_testButton];

    _diagnosticLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _diagnosticLabel.backgroundColor = [UIColor clearColor];
    _diagnosticLabel.font = [UIFont systemFontOfSize:14.0];
    _diagnosticLabel.textColor = [UIColor darkGrayColor];
    _diagnosticLabel.numberOfLines = 0;
    _diagnosticLabel.text = @"Connection endpoint only. Choose the current workspace on Home.";
    [_scrollView addSubview:_diagnosticLabel];
}

- (UITextField *)newTextFieldWithPlaceholder:(NSString *)placeholder
{
    UITextField *field = [[[UITextField alloc] initWithFrame:CGRectZero] autorelease];
    field.borderStyle = UITextBorderStyleRoundedRect;
    field.placeholder = placeholder;
    field.autocapitalizationType = UITextAutocapitalizationTypeNone;
    field.autocorrectionType = UITextAutocorrectionTypeNo;
    field.delegate = self;
    return field;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    CGRect bounds = self.view.bounds;
    _scrollView.frame = bounds;

    CGFloat margin = 18.0;
    CGFloat width = bounds.size.width - margin * 2.0;
    CGFloat y = 18.0;
    NSArray *fields = [NSArray arrayWithObjects:_displayNameField, _hostField, _portField, nil];
    for (UITextField *field in fields) {
        field.frame = CGRectMake(margin, y, width, 38.0);
        y += 48.0;
    }

    _testButton.frame = CGRectMake(margin, y + 8.0, UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 220.0 : width, 42.0);
    y += 64.0;
    _diagnosticLabel.frame = CGRectMake(margin, y, width, 120.0);
    _scrollView.contentSize = CGSizeMake(bounds.size.width, y + 140.0);
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)save:(id)sender
{
    (void)sender;
    [CCConnectionProfile saveDisplayName:_displayNameField.text
                                    host:_hostField.text
                                    port:[_portField.text integerValue]];
    _diagnosticLabel.text = @"Saved.";
}

- (void)testConnection:(id)sender
{
    (void)sender;
    [self save:nil];
    _diagnosticLabel.text = @"Testing...";

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSError *error = nil;
        CCRemoteControlResult *result = [_adapter performOperation:CCRemoteControlOperationStatus parameters:nil error:&error];
        NSString *text = nil;
        if ([result.detail length] > 0 && [result.state isEqualToString:@"connected"]) {
            text = [NSString stringWithFormat:@"%@\n%@", result.summary, result.detail];
        } else {
            text = [NSString stringWithFormat:@"Failed\n%@", [error localizedDescription]];
        }
        [text retain];
        dispatch_async(dispatch_get_main_queue(), ^{
            _diagnosticLabel.text = text;
            [text release];
        });
        [pool drain];
    });
}

@end
