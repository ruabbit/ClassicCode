#import "CCWorkbenchDetailViewController.h"

@implementation CCWorkbenchDetailViewController {
    UILabel *_titleLabel;
    UITextView *_bodyView;
}

- (void)dealloc
{
    [_titleLabel release];
    [_bodyView release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.font = [UIFont boldSystemFontOfSize:20.0];
    [self.view addSubview:_titleLabel];

    _bodyView = [[UITextView alloc] initWithFrame:CGRectZero];
    _bodyView.editable = NO;
    _bodyView.font = [UIFont fontWithName:@"Courier" size:14.0];
    _bodyView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_bodyView];

    [self showTitle:@"Overview" body:@"Select an object on the left."];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    CGRect bounds = self.view.bounds;
    CGFloat margin = 18.0;
    _titleLabel.frame = CGRectMake(margin, 16.0, bounds.size.width - margin * 2.0, 28.0);
    _bodyView.frame = CGRectMake(margin, 54.0, bounds.size.width - margin * 2.0, bounds.size.height - 66.0);
}

- (void)showTitle:(NSString *)title body:(NSString *)body
{
    _titleLabel.text = title;
    _bodyView.text = body;
    self.title = title;
}

@end
