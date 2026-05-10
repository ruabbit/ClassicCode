#import "CCWorkbenchDetailViewController.h"
#import "CCConnectionProfile.h"
#import "CCLineRemoteControlAdapter.h"
#import "CCRemoteControl.h"
#import <QuartzCore/QuartzCore.h>
#include <math.h>

@interface CCWorkbenchDetailViewController () <UITextFieldDelegate>
@end

@implementation CCWorkbenchDetailViewController {
    UILabel *_titleLabel;
    UITextView *_bodyView;
    UIScrollView *_messageScrollView;
    NSArray *_messageItems;
    UITextField *_promptField;
    UIButton *_runButton;
    id<CCRemoteControlAdapter> _adapter;
}

- (void)dealloc
{
    [_titleLabel release];
    [_bodyView release];
    [_messageScrollView release];
    [_messageItems release];
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

    _messageScrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    _messageScrollView.backgroundColor = [UIColor whiteColor];
    _messageScrollView.hidden = YES;
    [self.view addSubview:_messageScrollView];

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
    _messageScrollView.frame = _bodyView.frame;
    _promptField.frame = CGRectMake(margin,
                                    bounds.size.height - composerHeight - 10.0,
                                    bounds.size.width - margin * 2.0 - runWidth - 8.0,
                                    composerHeight);
    _runButton.frame = CGRectMake(CGRectGetMaxX(_promptField.frame) + 8.0,
                                  bounds.size.height - composerHeight - 10.0,
                                  runWidth,
                                  composerHeight);
    [self layoutMessageItems];
}

- (void)showTitle:(NSString *)title body:(NSString *)body
{
    [self showTitle:title body:body items:nil];
}

- (void)showTitle:(NSString *)title body:(NSString *)body items:(NSArray *)items
{
    _titleLabel.text = title;
    _bodyView.text = body;
    self.title = title;

    [_messageItems release];
    _messageItems = [items retain];
    BOOL hasItems = [items count] > 0;
    _bodyView.hidden = hasItems;
    _messageScrollView.hidden = !hasItems;
    [self layoutMessageItems];
}

- (UIColor *)colorForRole:(NSString *)role
{
    if ([role isEqualToString:@"user"]) {
        return [UIColor colorWithRed:0.82 green:0.90 blue:1.0 alpha:1.0];
    }
    if ([role isEqualToString:@"assistant"]) {
        return [UIColor colorWithWhite:0.93 alpha:1.0];
    }
    return [UIColor colorWithRed:0.92 green:0.92 blue:0.86 alpha:1.0];
}

- (BOOL)roleIsUser:(NSString *)role
{
    return [role isEqualToString:@"user"];
}

- (NSString *)stringValue:(id)value
{
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }
    return @"";
}

- (NSDictionary *)attributesWithFont:(UIFont *)font color:(UIColor *)color
{
    NSMutableParagraphStyle *style = [[[NSMutableParagraphStyle alloc] init] autorelease];
    style.lineBreakMode = NSLineBreakByWordWrapping;
    style.paragraphSpacing = 4.0;
    return [NSDictionary dictionaryWithObjectsAndKeys:
            font, NSFontAttributeName,
            color, NSForegroundColorAttributeName,
            style, NSParagraphStyleAttributeName,
            nil];
}

- (void)appendString:(NSString *)string
                font:(UIFont *)font
               color:(UIColor *)color
    toAttributedString:(NSMutableAttributedString *)attributed
{
    if ([string length] == 0) {
        return;
    }
    NSAttributedString *piece = [[[NSAttributedString alloc] initWithString:string
                                                                 attributes:[self attributesWithFont:font color:color]] autorelease];
    [attributed appendAttributedString:piece];
}

- (NSRange)rangeOfString:(NSString *)needle inString:(NSString *)haystack fromIndex:(NSUInteger)index
{
    if (index >= [haystack length]) {
        return NSMakeRange(NSNotFound, 0);
    }
    return [haystack rangeOfString:needle
                           options:0
                             range:NSMakeRange(index, [haystack length] - index)];
}

- (void)appendInlineMarkdown:(NSString *)text
                       font:(UIFont *)font
                      color:(UIColor *)color
         toAttributedString:(NSMutableAttributedString *)attributed
{
    NSUInteger index = 0;
    while (index < [text length]) {
        NSRange codeRange = [self rangeOfString:@"`" inString:text fromIndex:index];
        NSRange boldRange = [self rangeOfString:@"**" inString:text fromIndex:index];
        NSRange italicRange = [self rangeOfString:@"*" inString:text fromIndex:index];

        NSRange tokenRange = NSMakeRange(NSNotFound, 0);
        NSString *token = nil;
        UIFont *tokenFont = nil;
        if (codeRange.location != NSNotFound) {
            tokenRange = codeRange;
            token = @"`";
            tokenFont = [UIFont fontWithName:@"Courier" size:font.pointSize - 1.0];
        }
        if (boldRange.location != NSNotFound &&
            (tokenRange.location == NSNotFound || boldRange.location < tokenRange.location)) {
            tokenRange = boldRange;
            token = @"**";
            tokenFont = [UIFont boldSystemFontOfSize:font.pointSize];
        }
        if (italicRange.location != NSNotFound &&
            italicRange.location + 1 < [text length] &&
            ![[text substringWithRange:NSMakeRange(italicRange.location, 2)] isEqualToString:@"**"] &&
            (tokenRange.location == NSNotFound || italicRange.location < tokenRange.location)) {
            tokenRange = italicRange;
            token = @"*";
            tokenFont = [UIFont italicSystemFontOfSize:font.pointSize];
        }

        if (tokenRange.location == NSNotFound) {
            [self appendString:[text substringFromIndex:index] font:font color:color toAttributedString:attributed];
            break;
        }

        if (tokenRange.location > index) {
            [self appendString:[text substringWithRange:NSMakeRange(index, tokenRange.location - index)]
                          font:font
                         color:color
            toAttributedString:attributed];
        }

        NSUInteger contentStart = tokenRange.location + [token length];
        NSRange closeRange = [self rangeOfString:token inString:text fromIndex:contentStart];
        if (closeRange.location == NSNotFound) {
            [self appendString:[text substringFromIndex:tokenRange.location] font:font color:color toAttributedString:attributed];
            break;
        }

        NSString *content = [text substringWithRange:NSMakeRange(contentStart, closeRange.location - contentStart)];
        [self appendString:content
                      font:(tokenFont != nil ? tokenFont : font)
                     color:([token isEqualToString:@"`"] ? [UIColor colorWithWhite:0.20 alpha:1.0] : color)
        toAttributedString:attributed];
        index = closeRange.location + [token length];
    }
}

- (NSString *)trimmedMarkdownLine:(NSString *)line
{
    return [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (NSString *)listPrefixForLine:(NSString *)line contentStart:(NSUInteger *)contentStart
{
    if ([line length] >= 2) {
        NSString *prefix = [line substringToIndex:2];
        if ([prefix isEqualToString:@"- "] || [prefix isEqualToString:@"* "] || [prefix isEqualToString:@"+ "]) {
            if (contentStart != NULL) {
                *contentStart = 2;
            }
            return @"- ";
        }
    }

    NSUInteger index = 0;
    while (index < [line length]) {
        unichar ch = [line characterAtIndex:index];
        if (ch < '0' || ch > '9') {
            break;
        }
        index++;
    }
    if (index > 0 && index + 1 < [line length] &&
        [line characterAtIndex:index] == '.' &&
        [line characterAtIndex:index + 1] == ' ') {
        if (contentStart != NULL) {
            *contentStart = index + 2;
        }
        return [line substringToIndex:index + 2];
    }
    return nil;
}

- (NSAttributedString *)attributedBodyForText:(NSString *)text role:(NSString *)role
{
    UIFont *baseFont = [role isEqualToString:@"tool"] ? [UIFont fontWithName:@"Courier" size:12.0] : [UIFont systemFontOfSize:14.0];
    UIColor *baseColor = [UIColor blackColor];
    NSMutableAttributedString *attributed = [[[NSMutableAttributedString alloc] init] autorelease];

    if ([role isEqualToString:@"tool"]) {
        [self appendString:text font:baseFont color:baseColor toAttributedString:attributed];
        return attributed;
    }

    NSArray *lines = [text componentsSeparatedByString:@"\n"];
    BOOL inCodeBlock = NO;
    for (NSString *rawLine in lines) {
        NSString *line = rawLine;
        NSString *trimmed = [self trimmedMarkdownLine:line];
        if ([trimmed hasPrefix:@"```"]) {
            inCodeBlock = !inCodeBlock;
            continue;
        }

        if (inCodeBlock) {
            [self appendString:line
                          font:[UIFont fontWithName:@"Courier" size:12.0]
                         color:[UIColor colorWithWhite:0.15 alpha:1.0]
            toAttributedString:attributed];
            [self appendString:@"\n" font:baseFont color:baseColor toAttributedString:attributed];
            continue;
        }

        NSUInteger headingLevel = 0;
        while (headingLevel < [trimmed length] && headingLevel < 3 &&
               [trimmed characterAtIndex:headingLevel] == '#') {
            headingLevel++;
        }
        if (headingLevel > 0 && headingLevel + 1 < [trimmed length] &&
            [trimmed characterAtIndex:headingLevel] == ' ') {
            CGFloat size = (headingLevel == 1) ? 18.0 : (headingLevel == 2 ? 16.0 : 15.0);
            [self appendString:[trimmed substringFromIndex:headingLevel + 1]
                          font:[UIFont boldSystemFontOfSize:size]
                         color:baseColor
            toAttributedString:attributed];
            [self appendString:@"\n" font:baseFont color:baseColor toAttributedString:attributed];
            continue;
        }

        if ([trimmed hasPrefix:@">"]) {
            NSString *quote = [[trimmed substringFromIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            [self appendString:@"| "
                          font:[UIFont italicSystemFontOfSize:baseFont.pointSize]
                         color:[UIColor darkGrayColor]
            toAttributedString:attributed];
            [self appendInlineMarkdown:quote
                                  font:[UIFont italicSystemFontOfSize:baseFont.pointSize]
                                 color:[UIColor darkGrayColor]
                    toAttributedString:attributed];
            [self appendString:@"\n" font:baseFont color:baseColor toAttributedString:attributed];
            continue;
        }

        NSUInteger contentStart = 0;
        NSString *listPrefix = [self listPrefixForLine:trimmed contentStart:&contentStart];
        if (listPrefix != nil) {
            [self appendString:listPrefix font:baseFont color:baseColor toAttributedString:attributed];
            [self appendInlineMarkdown:[trimmed substringFromIndex:contentStart]
                                  font:baseFont
                                 color:baseColor
                    toAttributedString:attributed];
            [self appendString:@"\n" font:baseFont color:baseColor toAttributedString:attributed];
            continue;
        }

        [self appendInlineMarkdown:line font:baseFont color:baseColor toAttributedString:attributed];
        [self appendString:@"\n" font:baseFont color:baseColor toAttributedString:attributed];
    }

    return attributed;
}

- (CGSize)sizeForAttributedString:(NSAttributedString *)attributed width:(CGFloat)width fallbackFont:(UIFont *)font
{
    if ([attributed length] == 0) {
        return CGSizeMake(0.0, font.lineHeight);
    }
    CGRect rect = [attributed boundingRectWithSize:CGSizeMake(width, 10000.0)
                                           options:NSStringDrawingUsesLineFragmentOrigin
                                           context:nil];
    return CGSizeMake(ceilf(rect.size.width), ceilf(rect.size.height));
}

- (void)clearMessageViews
{
    NSArray *subviews = [[_messageScrollView subviews] copy];
    for (UIView *view in subviews) {
        [view removeFromSuperview];
    }
    [subviews release];
}

- (void)layoutMessageItems
{
    if (_messageScrollView == nil || [_messageItems count] == 0) {
        return;
    }

    [self clearMessageViews];

    CGFloat width = _messageScrollView.bounds.size.width;
    if (width <= 0.0) {
        return;
    }

    CGFloat y = 0.0;
    CGFloat margin = 10.0;
    CGFloat maxBubbleWidth = width * 0.78;
    CGFloat labelInset = 10.0;
    for (NSDictionary *item in _messageItems) {
        NSString *role = [self stringValue:[item objectForKey:@"role"]];
        NSString *title = [self stringValue:[item objectForKey:@"title"]];
        NSString *text = [self stringValue:[item objectForKey:@"text"]];
        if ([text length] == 0) {
            text = title;
        }

        UIFont *titleFont = [UIFont boldSystemFontOfSize:11.0];
        UIFont *bodyFont = [role isEqualToString:@"tool"] ? [UIFont fontWithName:@"Courier" size:12.0] : [UIFont systemFontOfSize:14.0];
        NSAttributedString *bodyAttributed = [self attributedBodyForText:text role:role];
        CGSize titleSize = [title sizeWithFont:titleFont constrainedToSize:CGSizeMake(maxBubbleWidth - labelInset * 2.0, 18.0)];
        CGSize bodySize = [self sizeForAttributedString:bodyAttributed width:maxBubbleWidth - labelInset * 2.0 fallbackFont:bodyFont];
        CGFloat bubbleWidth = MAX(titleSize.width, bodySize.width) + labelInset * 2.0;
        bubbleWidth = MIN(maxBubbleWidth, MAX(96.0, bubbleWidth));
        CGFloat bubbleHeight = titleSize.height + bodySize.height + 18.0;
        CGFloat x = [self roleIsUser:role] ? width - bubbleWidth - margin : margin;

        UIView *bubble = [[[UIView alloc] initWithFrame:CGRectMake(x, y + margin, bubbleWidth, bubbleHeight)] autorelease];
        bubble.backgroundColor = [self colorForRole:role];
        bubble.layer.cornerRadius = 8.0;
        bubble.layer.borderWidth = 1.0;
        bubble.layer.borderColor = [[UIColor colorWithWhite:0.82 alpha:1.0] CGColor];
        [_messageScrollView addSubview:bubble];

        UILabel *titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(labelInset, 6.0, bubbleWidth - labelInset * 2.0, titleSize.height)] autorelease];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.font = titleFont;
        titleLabel.textColor = [UIColor darkGrayColor];
        titleLabel.text = title;
        [bubble addSubview:titleLabel];

        UILabel *bodyLabel = [[[UILabel alloc] initWithFrame:CGRectMake(labelInset, 8.0 + titleSize.height, bubbleWidth - labelInset * 2.0, bodySize.height)] autorelease];
        bodyLabel.backgroundColor = [UIColor clearColor];
        bodyLabel.font = bodyFont;
        bodyLabel.numberOfLines = 0;
        bodyLabel.lineBreakMode = NSLineBreakByWordWrapping;
        if ([bodyLabel respondsToSelector:@selector(setAttributedText:)]) {
            bodyLabel.attributedText = bodyAttributed;
        } else {
            bodyLabel.text = [bodyAttributed string];
        }
        [bubble addSubview:bodyLabel];

        y += bubbleHeight + margin;
    }
    _messageScrollView.contentSize = CGSizeMake(width, y + margin);
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
