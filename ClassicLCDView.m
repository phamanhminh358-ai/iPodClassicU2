#import "ClassicLCDView.h"
#import <QuartzCore/QuartzCore.h>

@interface ClassicLCDView () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UIView *statusBarView;
@property (nonatomic, strong) UILabel *headerLabel;
@property (nonatomic, strong) UILabel *playIndicatorLabel;
@property (nonatomic, strong) UIView *batteryFillView;

// Split-Screen Menu Container
@property (nonatomic, strong) UIView *menuContainer;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *previewPane;
@property (nonatomic, strong) UIImageView *previewImageView;
@property (nonatomic, strong) UILabel *previewTitleLabel;
@property (nonatomic, strong) UILabel *previewSubLabel;
@property (nonatomic, strong) NSArray *menuItems;
@property (nonatomic, assign) NSInteger selectedRow;

// Now Playing Container
@property (nonatomic, strong) UIView *nowPlayingContainer;
@property (nonatomic, strong) UIImageView *npArtworkView;
@property (nonatomic, strong) UIImageView *npReflectionView;
@property (nonatomic, strong) UILabel *npTrackCountLabel;
@property (nonatomic, strong) UILabel *npTitleLabel;
@property (nonatomic, strong) UILabel *npArtistLabel;
@property (nonatomic, strong) UILabel *npAlbumLabel;
@property (nonatomic, strong) UIView *progressTrackView;
@property (nonatomic, strong) UIView *progressFillView;
@property (nonatomic, strong) UIView *scrubberDiamond;
@property (nonatomic, strong) UILabel *elapsedLabel;
@property (nonatomic, strong) UILabel *remainingLabel;
@property (nonatomic, strong) UILabel *ratingLabel;
@end

@implementation ClassicLCDView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.layer.cornerRadius = 6.0f;
        self.layer.borderWidth = 2.0f;
        self.layer.borderColor = [UIColor colorWithWhite:0.18f alpha:1.0f].CGColor;
        self.clipsToBounds = YES;

        [UIDevice currentDevice].batteryMonitoringEnabled = YES;
        [self buildStatusBar];
        [self buildMenuView];
        [self buildNowPlayingView];
        self.mode = LCDModeMenu;
    }
    return self;
}

- (void)buildStatusBar {
    CGFloat w = self.bounds.size.width;
    self.statusBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 22.0f)];

    CAGradientLayer *grad = [CAGradientLayer layer];
    grad.frame = self.statusBarView.bounds;
    grad.colors = @[
        (id)[UIColor colorWithRed:0.95f green:0.96f blue:0.98f alpha:1.0f].CGColor,
        (id)[UIColor colorWithRed:0.78f green:0.81f blue:0.85f alpha:1.0f].CGColor
    ];
    [self.statusBarView.layer addSublayer:grad];

    UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0, 21.0f, w, 1.0f)];
    bottomLine.backgroundColor = [UIColor colorWithWhite:0.55f alpha:1.0f];
    [self.statusBarView addSubview:bottomLine];

    self.playIndicatorLabel = [[UILabel alloc] initWithFrame:CGRectMake(6, 2, 16, 18)];
    self.playIndicatorLabel.backgroundColor = [UIColor clearColor];
    self.playIndicatorLabel.font = [UIFont boldSystemFontOfSize:11.0f];
    self.playIndicatorLabel.textColor = [UIColor colorWithRed:0.11f green:0.38f blue:0.92f alpha:1.0f];
    self.playIndicatorLabel.text = @"";
    [self.statusBarView addSubview:self.playIndicatorLabel];

    self.headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(26, 1, w - 66, 20)];
    self.headerLabel.backgroundColor = [UIColor clearColor];
    self.headerLabel.textAlignment = NSTextAlignmentCenter;
    self.headerLabel.font = [UIFont boldSystemFontOfSize:13.0f];
    self.headerLabel.textColor = [UIColor colorWithWhite:0.12f alpha:1.0f];
    self.headerLabel.text = @"iPod";
    [self.statusBarView addSubview:self.headerLabel];

    // Icon pin iPod cổ điển
    UIView *batOutline = [[UIView alloc] initWithFrame:CGRectMake(w - 30, 6, 21, 10)];
    batOutline.layer.borderWidth = 1.0f;
    batOutline.layer.borderColor = [UIColor colorWithWhite:0.25f alpha:1.0f].CGColor;
    batOutline.backgroundColor = [UIColor whiteColor];
    [self.statusBarView addSubview:batOutline];

    UIView *batTip = [[UIView alloc] initWithFrame:CGRectMake(w - 9, 8.5f, 2, 5)];
    batTip.backgroundColor = [UIColor colorWithWhite:0.25f alpha:1.0f];
    [self.statusBarView addSubview:batTip];

    float level = [UIDevice currentDevice].batteryLevel;
    if (level < 0.0f) level = 0.88f;
    self.batteryFillView = [[UIView alloc] initWithFrame:CGRectMake(1, 1, roundf(19.0f * level), 8)];
    self.batteryFillView.backgroundColor = [UIColor colorWithRed:0.20f green:0.74f blue:0.24f alpha:1.0f];
    [batOutline addSubview:self.batteryFillView];

    [self addSubview:self.statusBarView];
}

- (void)buildMenuView {
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height - 22.0f;
    self.menuContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 22.0f, w, h)];
    self.menuContainer.backgroundColor = [UIColor whiteColor];

    CGFloat leftW = roundf(w * 0.54f);
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, leftW, h) style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 26.0f;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.userInteractionEnabled = NO;
    [self.menuContainer addSubview:self.tableView];

    UIView *divider = [[UIView alloc] initWithFrame:CGRectMake(leftW, 0, 1.0f, h)];
    divider.backgroundColor = [UIColor colorWithWhite:0.84f alpha:1.0f];
    [self.menuContainer addSubview:divider];

    CGFloat rightW = w - leftW - 1.0f;
    self.previewPane = [[UIView alloc] initWithFrame:CGRectMake(leftW + 1.0f, 0, rightW, h)];
    self.previewPane.backgroundColor = [UIColor colorWithRed:0.96f green:0.97f blue:0.99f alpha:1.0f];

    CGFloat imgSize = 86.0f;
    self.previewImageView = [[UIImageView alloc] initWithFrame:CGRectMake(roundf((rightW - imgSize) / 2.0f), 14.0f, imgSize, imgSize)];
    self.previewImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.previewImageView.clipsToBounds = YES;
    self.previewImageView.layer.borderWidth = 1.0f;
    self.previewImageView.layer.borderColor = [UIColor colorWithWhite:0.75f alpha:1.0f].CGColor;
    [self.previewPane addSubview:self.previewImageView];

    self.previewTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(6, 106, rightW - 12, 18)];
    self.previewTitleLabel.backgroundColor = [UIColor clearColor];
    self.previewTitleLabel.font = [UIFont boldSystemFontOfSize:11.5f];
    self.previewTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.previewTitleLabel.textColor = [UIColor colorWithWhite:0.15f alpha:1.0f];
    [self.previewPane addSubview:self.previewTitleLabel];

    self.previewSubLabel = [[UILabel alloc] initWithFrame:CGRectMake(6, 124, rightW - 12, 32)];
    self.previewSubLabel.backgroundColor = [UIColor clearColor];
    self.previewSubLabel.font = [UIFont systemFontOfSize:10.5f];
    self.previewSubLabel.textAlignment = NSTextAlignmentCenter;
    self.previewSubLabel.numberOfLines = 2;
    self.previewSubLabel.textColor = [UIColor colorWithWhite:0.45f alpha:1.0f];
    [self.previewPane addSubview:self.previewSubLabel];

    [self.menuContainer addSubview:self.previewPane];
    [self addSubview:self.menuContainer];
}

- (void)buildNowPlayingView {
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height - 22.0f;
    self.nowPlayingContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 22.0f, w, h)];
    self.nowPlayingContainer.backgroundColor = [UIColor whiteColor];
    self.nowPlayingContainer.hidden = YES;

    // Ảnh bìa Album nghiêng 3D đặc trưng iPod Classic
    self.npArtworkView = [[UIImageView alloc] initWithFrame:CGRectMake(14, 14, 102, 102)];
    self.npArtworkView.contentMode = UIViewContentModeScaleAspectFill;
    self.npArtworkView.clipsToBounds = YES;
    self.npArtworkView.layer.borderWidth = 1.0f;
    self.npArtworkView.layer.borderColor = [UIColor colorWithWhite:0.7f alpha:1.0f].CGColor;

    CATransform3D tilt = CATransform3DIdentity;
    tilt.m34 = -1.0f / 420.0f;
    tilt = CATransform3DRotate(tilt, 15.0f * (M_PI / 180.0f), 0.0f, 1.0f, 0.0f);
    self.npArtworkView.layer.transform = tilt;
    [self.nowPlayingContainer addSubview:self.npArtworkView];

    // Bóng phản chiếu dưới bìa đĩa
    self.npReflectionView = [[UIImageView alloc] initWithFrame:CGRectMake(14, 117, 102, 22)];
    self.npReflectionView.contentMode = UIViewContentModeScaleAspectFill;
    self.npReflectionView.clipsToBounds = YES;
    self.npReflectionView.alpha = 0.22f;
    CATransform3D flip = CATransform3DScale(tilt, 1.0f, -1.0f, 1.0f);
    self.npReflectionView.layer.transform = flip;
    [self.nowPlayingContainer addSubview:self.npReflectionView];

    CGFloat infoX = 126.0f;
    CGFloat infoW = w - infoX - 10.0f;

    self.npTrackCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(infoX, 12, infoW, 15)];
    self.npTrackCountLabel.backgroundColor = [UIColor clearColor];
    self.npTrackCountLabel.font = [UIFont boldSystemFontOfSize:10.5f];
    self.npTrackCountLabel.textColor = [UIColor colorWithWhite:0.45f alpha:1.0f];
    [self.nowPlayingContainer addSubview:self.npTrackCountLabel];

    self.npTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(infoX, 30, infoW, 20)];
    self.npTitleLabel.backgroundColor = [UIColor clearColor];
    self.npTitleLabel.font = [UIFont boldSystemFontOfSize:13.5f];
    self.npTitleLabel.textColor = [UIColor blackColor];
    [self.nowPlayingContainer addSubview:self.npTitleLabel];

    self.npArtistLabel = [[UILabel alloc] initWithFrame:CGRectMake(infoX, 52, infoW, 18)];
    self.npArtistLabel.backgroundColor = [UIColor clearColor];
    self.npArtistLabel.font = [UIFont boldSystemFontOfSize:11.5f];
    self.npArtistLabel.textColor = [UIColor colorWithWhite:0.35f alpha:1.0f];
    [self.nowPlayingContainer addSubview:self.npArtistLabel];

    self.npAlbumLabel = [[UILabel alloc] initWithFrame:CGRectMake(infoX, 70, infoW, 18)];
    self.npAlbumLabel.backgroundColor = [UIColor clearColor];
    self.npAlbumLabel.font = [UIFont systemFontOfSize:11.0f];
    self.npAlbumLabel.textColor = [UIColor colorWithWhite:0.45f alpha:1.0f];
    [self.nowPlayingContainer addSubview:self.npAlbumLabel];

    self.ratingLabel = [[UILabel alloc] initWithFrame:CGRectMake(infoX, 94, infoW, 20)];
    self.ratingLabel.backgroundColor = [UIColor clearColor];
    self.ratingLabel.font = [UIFont boldSystemFontOfSize:14.0f];
    self.ratingLabel.textColor = [UIColor colorWithRed:0.12f green:0.42f blue:0.92f alpha:1.0f];
    self.ratingLabel.hidden = YES;
    [self.nowPlayingContainer addSubview:self.ratingLabel];

    // Thanh tiến trình (Scrubber Bar) phía dưới
    CGFloat barY = h - 34.0f;
    CGFloat barX = 46.0f;
    CGFloat barW = w - 92.0f;

    self.progressTrackView = [[UIView alloc] initWithFrame:CGRectMake(barX, barY, barW, 10.0f)];
    self.progressTrackView.backgroundColor = [UIColor colorWithWhite:0.90f alpha:1.0f];
    self.progressTrackView.layer.cornerRadius = 5.0f;
    self.progressTrackView.layer.borderWidth = 1.0f;
    self.progressTrackView.layer.borderColor = [UIColor colorWithWhite:0.65f alpha:1.0f].CGColor;
    self.progressTrackView.clipsToBounds = YES;
    [self.nowPlayingContainer addSubview:self.progressTrackView];

    self.progressFillView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 10.0f)];
    self.progressFillView.backgroundColor = [UIColor colorWithRed:0.13f green:0.46f blue:0.96f alpha:1.0f];
    [self.progressTrackView addSubview:self.progressFillView];

    self.scrubberDiamond = [[UIView alloc] initWithFrame:CGRectMake(barX - 4, barY + 1, 8, 8)];
    self.scrubberDiamond.backgroundColor = [UIColor colorWithRed:0.82f green:0.08f blue:0.18f alpha:1.0f];
    self.scrubberDiamond.transform = CGAffineTransformMakeRotation(M_PI_4);
    self.scrubberDiamond.hidden = YES;
    [self.nowPlayingContainer addSubview:self.scrubberDiamond];

    self.elapsedLabel = [[UILabel alloc] initWithFrame:CGRectMake(6, barY - 3, 36, 16)];
    self.elapsedLabel.backgroundColor = [UIColor clearColor];
    self.elapsedLabel.font = [UIFont boldSystemFontOfSize:10.0f];
    self.elapsedLabel.textAlignment = NSTextAlignmentRight;
    self.elapsedLabel.textColor = [UIColor colorWithWhite:0.25f alpha:1.0f];
    [self.nowPlayingContainer addSubview:self.elapsedLabel];

    self.remainingLabel = [[UILabel alloc] initWithFrame:CGRectMake(w - 42, barY - 3, 38, 16)];
    self.remainingLabel.backgroundColor = [UIColor clearColor];
    self.remainingLabel.font = [UIFont boldSystemFontOfSize:10.0f];
    self.remainingLabel.textAlignment = NSTextAlignmentLeft;
    self.remainingLabel.textColor = [UIColor colorWithWhite:0.25f alpha:1.0f];
    [self.nowPlayingContainer addSubview:self.remainingLabel];

    [self addSubview:self.nowPlayingContainer];
}

- (void)setMode:(LCDMode)mode {
    _mode = mode;
    self.menuContainer.hidden = (mode != LCDModeMenu);
    self.nowPlayingContainer.hidden = (mode != LCDModeNowPlaying);
}

- (void)setSubMode:(NowPlayingSubMode)subMode {
    _subMode = subMode;
    self.scrubberDiamond.hidden = (subMode != NowPlayingSubModeScrub);
    self.ratingLabel.hidden = (subMode != NowPlayingSubModeRating);
}

- (void)setHeaderTitle:(NSString *)title isPlaying:(BOOL)playing {
    self.headerLabel.text = title;
    self.playIndicatorLabel.text = playing ? @"▶" : @"";
}

- (void)updateMenuItems:(NSArray *)items
          selectedIndex:(NSInteger)index
           previewImage:(UIImage *)image
           previewTitle:(NSString *)pTitle
        previewSubtitle:(NSString *)pSub
       animateDirection:(NSInteger)dir {
    self.menuItems = items;
    self.selectedRow = index;
    self.previewImageView.image = image;
    self.previewTitleLabel.text = pTitle;
    self.previewSubLabel.text = pSub;

    if (dir != 0) {
        CATransition *transition = [CATransition animation];
        transition.type = kCATransitionPush;
        transition.subtype = (dir > 0) ? kCATransitionFromRight : kCATransitionFromLeft;
        transition.duration = 0.20;
        [self.tableView.layer addAnimation:transition forKey:@"slide"];
    }

    [self.tableView reloadData];
    if (items.count > 0 && index >= 0 && index < (NSInteger)items.count) {
        NSIndexPath *ip = [NSIndexPath indexPathForRow:index inSection:0];
        [self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionNone animated:NO];
    }
}

- (NSString *)formatTime:(NSTimeInterval)seconds {
    if (isnan(seconds) || seconds < 0) seconds = 0;
    NSInteger total = (NSInteger)seconds;
    return [NSString stringWithFormat:@"%ld:%02ld", (long)(total / 60), (long)(total % 60)];
}

- (void)updateNowPlayingTitle:(NSString *)title
                       artist:(NSString *)artist
                        album:(NSString *)album
                      artwork:(UIImage *)artwork
                    trackInfo:(NSString *)trackInfo
                      elapsed:(NSTimeInterval)elapsed
                     duration:(NSTimeInterval)duration
                       rating:(NSInteger)rating {
    self.npTitleLabel.text = title ?: @"Unknown Track";
    self.npArtistLabel.text = artist ?: @"Unknown Artist";
    self.npAlbumLabel.text = album ?: @"";
    self.npArtworkView.image = artwork;
    self.npReflectionView.image = artwork;
    self.npTrackCountLabel.text = trackInfo ?: @"1 of 1";

    CGFloat ratio = (duration > 0.0) ? MIN(1.0f, MAX(0.0f, (CGFloat)(elapsed / duration))) : 0.0f;
    CGFloat barW = self.progressTrackView.bounds.size.width;
    self.progressFillView.frame = CGRectMake(0, 0, roundf(barW * ratio), 10.0f);
    self.scrubberDiamond.center = CGPointMake(self.progressTrackView.frame.origin.x + roundf(barW * ratio),
                                              self.progressTrackView.center.y);

    self.elapsedLabel.text = [self formatTime:elapsed];
    self.remainingLabel.text = [NSString stringWithFormat:@"-%@", [self formatTime:MAX(0, duration - elapsed)]];

    NSMutableString *stars = [NSMutableString string];
    for (NSInteger i = 1; i <= 5; i++) {
        [stars appendString:(i <= rating) ? @"★ " : @"☆ "];
    }
    self.ratingLabel.text = stars;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.menuItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"iPodCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:12.5f];
        cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:12.5f];
    }

    NSDictionary *item = self.menuItems[indexPath.row];
    BOOL isSelected = (indexPath.row == self.selectedRow);
    BOOL hasArrow = [item[@"arrow"] boolValue];

    cell.textLabel.text = item[@"title"];
    cell.accessoryType = hasArrow ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;

    if (isSelected) {
        cell.backgroundColor = [UIColor colorWithRed:0.11f green:0.41f blue:0.93f alpha:1.0f];
        cell.textLabel.textColor = [UIColor whiteColor];
    } else {
        cell.backgroundColor = [UIColor whiteColor];
        cell.textLabel.textColor = [UIColor colorWithWhite:0.10f alpha:1.0f];
    }
    return cell;
}

@end