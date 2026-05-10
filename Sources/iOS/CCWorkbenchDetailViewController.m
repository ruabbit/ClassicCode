#import "CCWorkbenchDetailViewController.h"
#import "CCConnectionProfile.h"
#import "CCLineRemoteControlAdapter.h"
#import "CCRemoteControl.h"

@interface CCWorkbenchDetailViewController () <UITextFieldDelegate>
@end

@implementation CCWorkbenchDetailViewController {
    UILabel *_titleLabel;
    UITextView *_bodyView;
    UITextField *_promptField;
    UIButton *_runButton;
    id<CCRemoteControlAdapter> _adapter;
}

- (void)dealloc
{
    [_titleLabel release];
    [_bodyView release];
    [_promptField release];
    [_runButton release];
    [_adapter release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    _adapter = [[CCLineRemoteControlAdapter alloc] init];

    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.font = [UIFont boldSystemFontOfSize:18.0];
    [self.view addSubview:_titleLabel];

    _bodyView = [[UITextView alloc] initWithFrame:CGRectZero];
    _bodyView.editable = NO;
    _bodyView.font = [UIFont fontWithName:@"Courier" size:14.0];
    _bodyView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_bodyView];

    _promptField = [[UITextField alloc] initWithFrame:CGRectZero];
    _promptField.borderStyle = UITextBorderStyleRoundedRect;
    _promptField.placeholder = @"Ask Codex in this workspace";
    _promptField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    _promptField.autocorrectionType = UITextAutocorrectionTypeYes;
    _promptField.delegate = self;
    [self.view addSubview:_promptField];

    _runButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
    [_runButton setTitle:@"Run" forState:UIControlStateNormal];
    [_runButton addTarget:self action:@selector(runTask:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_runButton];

    [self showTitle:[CCConnectionProfile workspace] body:@"Select a conversation or file on the left."];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    CGRect bounds = self.view.bounds;
    CGFloat margin = 18.0;
    CGFloat composerHeight = 44.0;
    CGFloat titleHeight = 30.0;
    CGFloat runWidth = 72.0;

    _titleLabel.frame = CGRectMake(margin, 12.0, bounds.size.width - margin * 2.0, titleHeight);
    _bodyView.frame = CGRectMake(margin,
                                 48.0,
                                 bounds.size.width - margin * 2.0,
                                 bounds.size.height - 48.0 - composerHeight - 22.0);
    _promptField.frame = CGRectMake(margin,
                                    bounds.size.height - composerHeight - 10.0,
                                    bounds.size.width - margin * 2.0 - runWidth - 8.0,
                                    composerHeight);
    _runButton.frame = CGRectMake(CGRectGetMaxX(_promptField.frame) + 8.0,
                                  bounds.size.height - composerHeight - 10.0,
                                  runWidth,
                                  composerHeight);
}

- (void)showTitle:(NSString *)title body:(NSString *)body
{
    _titleLabel.text = title;
    _bodyView.text = body;
    self.title = title;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self runTask:textField];
    return YES;
}

- (void)setComposerEnabled:(BOOL)enabled
{
    _promptField.enabled = enabled;
    _runButton.enabled = enabled;
}

- (void)runTask:(id)sender
{
    (void)sender;
    NSString *prompt = [_promptField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([prompt length] == 0) {
        return;
    }

    NSString *workspace = [CCConnectionProfile workspace];
    NSString *title = @"New Task";
    [self setComposerEnabled:NO];
    [self showTitle:title body:@"Starting task..."];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSError *error = nil;
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                prompt, @"prompt",
                                workspace, @"workspace",
                                nil];
        CCRemoteControlResult *result = [_adapter performOperation:CCRemoteControlOperationStartTask parameters:params error:&error];
        NSString *body = result.detail;
        if ([body length] == 0) {
            body = [error localizedDescription];
        }
        [body retain];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showTitle:title body:body];
            _promptField.text = @"";
            [self setComposerEnabled:YES];
            [body release];
        });
        [pool drain];
    });
}

@end
