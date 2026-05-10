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
    UIScrollView *_fileBrowserScrollView;
    UISegmentedControl *_fileBrowserModeControl;
    NSArray *_messageItems;
    NSArray *_directoryEntries;
    NSString *_directoryPath;
    BOOL _scrollMessagesToBottomAfterLayout;
    UITextField *_promptField;
    UIButton *_runButton;
    id<CCRemoteControlAdapter> _adapter;
}

- (void)dealloc
{
    [_titleLabel release];
    [_bodyView release];
    [_messageScrollView release];
    [_fileBrowserScrollView release];
    [_fileBrowserModeControl release];
    [_messageItems release];
    [_directoryEntries release];
    [_directoryPath release];
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

    _fileBrowserScrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    _fileBrowserScrollView.backgroundColor = [UIColor whiteColor];
    _fileBrowserScrollView.hidden = YES;
    [self.view addSubview:_fileBrowserScrollView];

    _fileBrowserModeControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Icons", @"List", nil]];
    _fileBrowserModeControl.segmentedControlStyle = UISegmentedControlStyleBar;
    _fileBrowserModeControl.selectedSegmentIndex = 0;
    _fileBrowserModeControl.hidden = YES;
    [_fileBrowserModeControl addTarget:self action:@selector(fileBrowserModeChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_fileBrowserModeControl];

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
    _fileBrowserModeControl.frame = CGRectMake(margin,
                                               48.0,
                                               180.0,
                                               30.0);
    _fileBrowserScrollView.frame = CGRectMake(margin,
                                              88.0,
                                              bounds.size.width - margin * 2.0,
                                              bounds.size.height - 88.0 - composerHeight - 22.0);
    _promptField.frame = CGRectMake(margin,
                                    bounds.size.height - composerHeight - 10.0,
                                    bounds.size.width - margin * 2.0 - runWidth - 8.0,
                                    composerHeight);
    _runButton.frame = CGRectMake(CGRectGetMaxX(_promptField.frame) + 8.0,
                                  bounds.size.height - composerHeight - 10.0,
                                  runWidth,
                                  composerHeight);
    [self layoutMessageItems];
    [self layoutFileBrowser];
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

    [_directoryEntries release];
    _directoryEntries = nil;
    [_directoryPath release];
    _directoryPath = nil;
    [_messageItems release];
    _messageItems = [items retain];
    BOOL hasItems = [items count] > 0;
    _bodyView.hidden = hasItems;
    _messageScrollView.hidden = !hasItems;
    _fileBrowserScrollView.hidden = YES;
    _fileBrowserModeControl.hidden = YES;
    _scrollMessagesToBottomAfterLayout = hasItems;
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
    if (_scrollMessagesToBottomAfterLayout) {
        CGFloat offsetY = MAX(0.0, _messageScrollView.contentSize.height - _messageScrollView.bounds.size.height);
        _messageScrollView.contentOffset = CGPointMake(0.0, offsetY);
        _scrollMessagesToBottomAfterLayout = NO;
    }
}

- (void)clearFileBrowserViews
{
    NSArray *subviews = [[_fileBrowserScrollView subviews] copy];
    for (UIView *view in subviews) {
        [view removeFromSuperview];
    }
    [subviews release];
}

- (NSString *)fileNameForEntry:(NSDictionary *)entry
{
    NSString *name = [self stringValue:[entry objectForKey:@"fileName"]];
    return [name length] > 0 ? name : @"Untitled";
}

- (BOOL)entryIsDirectory:(NSDictionary *)entry
{
    return [[entry objectForKey:@"isDirectory"] boolValue];
}

- (NSString *)pathForEntry:(NSDictionary *)entry
{
    NSString *name = [self fileNameForEntry:entry];
    if ([_directoryPath length] == 0) {
        return name;
    }
    return [_directoryPath stringByAppendingPathComponent:name];
}

- (UIImage *)iconForEntry:(NSDictionary *)entry small:(BOOL)small
{
    NSString *name = [self fileNameForEntry:entry];
    NSString *lower = [name lowercaseString];
    NSString *base = @"document";
    if ([self entryIsDirectory:entry]) {
        base = @"folder";
    } else if ([lower hasSuffix:@".app"]) {
        base = @"application";
    } else if ([lower hasSuffix:@".sh"] || [lower hasSuffix:@".py"] || [lower hasSuffix:@".rb"] ||
               [lower hasSuffix:@".pl"] || [lower hasSuffix:@".command"]) {
        base = @"executable";
    }
    NSString *imageName = small ? [base stringByAppendingString:@"-small.png"] : [base stringByAppendingString:@".png"];
    UIImage *image = [UIImage imageNamed:imageName];
    if (image == nil && ![base isEqualToString:@"document"]) {
        imageName = small ? @"document-small.png" : @"document.png";
        image = [UIImage imageNamed:imageName];
    }
    return image;
}

- (void)openDirectoryPath:(NSString *)path title:(NSString *)title
{
    _titleLabel.text = title;
    self.title = title;
    [self clearFileBrowserViews];
    UILabel *loading = [[[UILabel alloc] initWithFrame:CGRectMake(12.0, 12.0, _fileBrowserScrollView.bounds.size.width - 24.0, 24.0)] autorelease];
    loading.backgroundColor = [UIColor clearColor];
    loading.text = @"Loading...";
    [_fileBrowserScrollView addSubview:loading];

    [path retain];
    [title retain];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSError *error = nil;
        NSDictionary *params = [NSDictionary dictionaryWithObject:path forKey:@"path"];
        CCRemoteControlResult *result = [_adapter performOperation:CCRemoteControlOperationListFiles parameters:params error:&error];
        NSArray *entries = result.items;
        BOOL connected = [result.state isEqualToString:@"connected"];
        NSString *body = [error localizedDescription];
        if ([entries count] == 0 && [body length] == 0) {
            body = @"Empty folder.";
        }
        [entries retain];
        [body retain];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (connected) {
                [self showDirectoryWithTitle:title path:path entries:entries];
            } else {
                [self showTitle:title body:body];
            }
            [entries release];
            [body release];
            [path release];
            [title release];
        });
        [pool drain];
    });
}

- (void)openFilePath:(NSString *)path title:(NSString *)title
{
    [self showTitle:title body:@"Loading..."];
    [path retain];
    [title retain];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSError *error = nil;
        NSDictionary *params = [NSDictionary dictionaryWithObject:path forKey:@"path"];
        CCRemoteControlResult *result = [_adapter performOperation:CCRemoteControlOperationReadFile parameters:params error:&error];
        NSString *body = result.detail;
        if ([body length] == 0) {
            body = [error localizedDescription];
        }
        [body retain];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showTitle:title body:body];
            [body release];
            [path release];
            [title release];
        });
        [pool drain];
    });
}

- (void)fileBrowserItemTapped:(id)sender
{
    NSInteger index = [sender tag];
    if (index < 0 || index >= (NSInteger)[_directoryEntries count]) {
        return;
    }
    NSDictionary *entry = [_directoryEntries objectAtIndex:(NSUInteger)index];
    NSString *path = [self pathForEntry:entry];
    NSString *name = [self fileNameForEntry:entry];
    if ([self entryIsDirectory:entry]) {
        [self openDirectoryPath:path title:name];
    } else {
        [self openFilePath:path title:name];
    }
}

- (void)addIconItemForEntry:(NSDictionary *)entry index:(NSInteger)index x:(CGFloat)x y:(CGFloat)y width:(CGFloat)width
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(x, y, width, 106.0);
    button.tag = index;
    [button addTarget:self action:@selector(fileBrowserItemTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_fileBrowserScrollView addSubview:button];

    UIImageView *iconView = [[[UIImageView alloc] initWithImage:[self iconForEntry:entry small:NO]] autorelease];
    iconView.frame = CGRectMake((width - 64.0) / 2.0, 4.0, 64.0, 64.0);
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    [button addSubview:iconView];

    UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(4.0, 72.0, width - 8.0, 32.0)] autorelease];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:12.0];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 2;
    label.lineBreakMode = NSLineBreakByTruncatingMiddle;
    label.text = [self fileNameForEntry:entry];
    [button addSubview:label];
}

- (void)addListItemForEntry:(NSDictionary *)entry index:(NSInteger)index y:(CGFloat)y width:(CGFloat)width
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0.0, y, width, 44.0);
    button.tag = index;
    [button addTarget:self action:@selector(fileBrowserItemTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_fileBrowserScrollView addSubview:button];

    UIImageView *iconView = [[[UIImageView alloc] initWithImage:[self iconForEntry:entry small:YES]] autorelease];
    iconView.frame = CGRectMake(8.0, 6.0, 32.0, 32.0);
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    [button addSubview:iconView];

    UILabel *nameLabel = [[[UILabel alloc] initWithFrame:CGRectMake(50.0, 2.0, width - 62.0, 24.0)] autorelease];
    nameLabel.backgroundColor = [UIColor clearColor];
    nameLabel.font = [UIFont systemFontOfSize:14.0];
    nameLabel.text = [self fileNameForEntry:entry];
    [button addSubview:nameLabel];

    UILabel *typeLabel = [[[UILabel alloc] initWithFrame:CGRectMake(50.0, 24.0, width - 62.0, 16.0)] autorelease];
    typeLabel.backgroundColor = [UIColor clearColor];
    typeLabel.font = [UIFont systemFontOfSize:11.0];
    typeLabel.textColor = [UIColor darkGrayColor];
    typeLabel.text = [self entryIsDirectory:entry] ? @"Folder" : @"File";
    [button addSubview:typeLabel];

    UIView *line = [[[UIView alloc] initWithFrame:CGRectMake(50.0, 43.0, width - 50.0, 1.0)] autorelease];
    line.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1.0];
    [button addSubview:line];
}

- (void)layoutFileBrowser
{
    if (_fileBrowserScrollView == nil || _fileBrowserScrollView.hidden || _directoryEntries == nil) {
        return;
    }
    [self clearFileBrowserViews];

    CGFloat width = _fileBrowserScrollView.bounds.size.width;
    if (width <= 0.0) {
        return;
    }

    if (_fileBrowserModeControl.selectedSegmentIndex == 1) {
        CGFloat y = 0.0;
        for (NSUInteger index = 0; index < [_directoryEntries count]; index++) {
            [self addListItemForEntry:[_directoryEntries objectAtIndex:index]
                                index:(NSInteger)index
                                    y:y
                                width:width];
            y += 44.0;
        }
        _fileBrowserScrollView.contentSize = CGSizeMake(width, y);
        return;
    }

    CGFloat itemWidth = 112.0;
    NSInteger columns = MAX(1, (NSInteger)floorf(width / itemWidth));
    CGFloat gutter = (width - columns * itemWidth) / (columns + 1);
    CGFloat y = 8.0;
    for (NSUInteger index = 0; index < [_directoryEntries count]; index++) {
        NSInteger column = (NSInteger)(index % (NSUInteger)columns);
        NSInteger row = (NSInteger)(index / (NSUInteger)columns);
        CGFloat x = gutter + column * (itemWidth + gutter);
        y = 8.0 + row * 116.0;
        [self addIconItemForEntry:[_directoryEntries objectAtIndex:index]
                            index:(NSInteger)index
                                x:x
                                y:y
                            width:itemWidth];
    }
    NSInteger rows = ((NSInteger)[_directoryEntries count] + columns - 1) / columns;
    _fileBrowserScrollView.contentSize = CGSizeMake(width, 8.0 + rows * 116.0);
}

- (void)fileBrowserModeChanged:(id)sender
{
    (void)sender;
    [self layoutFileBrowser];
}

- (void)showDirectoryWithTitle:(NSString *)title path:(NSString *)path entries:(NSArray *)entries
{
    _titleLabel.text = title;
    _bodyView.text = @"";
    self.title = title;

    [_messageItems release];
    _messageItems = nil;
    [_directoryEntries release];
    _directoryEntries = [entries retain];
    [_directoryPath release];
    _directoryPath = [path retain];

    _bodyView.hidden = YES;
    _messageScrollView.hidden = YES;
    _fileBrowserScrollView.hidden = NO;
    _fileBrowserModeControl.hidden = NO;
    [self layoutFileBrowser];
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
