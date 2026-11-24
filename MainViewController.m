#import "MainViewController.h"
#import "ClickWheelView.h"
#import "ClassicLCDView.h"
#import <MediaPlayer/MediaPlayer.h>
#import <QuartzCore/QuartzCore.h>

@interface MainViewController () <ClickWheelViewDelegate>
@property (nonatomic, strong) ClassicLCDView *lcdView;
@property (nonatomic, strong) ClickWheelView *clickWheel;
@property (nonatomic, strong) NSMutableArray *menuStack;

@property (nonatomic, strong) MPMusicPlayerController *musicPlayer;
@property (nonatomic, strong) NSArray *librarySongs;
@property (nonatomic, assign) BOOL usingDemoLibrary;
@property (nonatomic, strong) NSArray *demoSongs;
@property (nonatomic, assign) NSInteger demoIndex;
@property (nonatomic, assign) BOOL demoPlaying;
@property (nonatomic, assign) NSTimeInterval demoElapsed;
@property (nonatomic, assign) NSInteger demoRating;
@property (nonatomic, strong) NSTimer *playbackTimer;
@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Vỏ máy Piano Black bóng đặc trưng của iPod U2 Special Edition
    self.view.backgroundColor = [UIColor colorWithRed:0.04f green:0.04f blue:0.05f alpha:1.0f];
    CAGradientLayer *bodyGrad = [CAGradientLayer layer];
    bodyGrad.frame = self.view.bounds;
    bodyGrad.colors = @[
        (id)[UIColor colorWithRed:0.09f green:0.09f blue:0.11f alpha:1.0f].CGColor,
        (id)[UIColor colorWithRed:0.03f green:0.03f blue:0.04f alpha:1.0f].CGColor
    ];
    [self.view.layer insertSublayer:bodyGrad atIndex:0];

    CGFloat screenW = self.view.bounds.size.width;
    CGFloat screenH = self.view.bounds.size.height;

    // Nửa trên: Màn hình LCD iPod Classic (tỷ lệ chuẩn cho 320x480)
    CGFloat lcdMarginX = 12.0f;
    CGFloat lcdW = screenW - lcdMarginX * 2.0f;
    CGFloat lcdH = roundf(screenH * 0.43f);
    self.lcdView = [[ClassicLCDView alloc] initWithFrame:CGRectMake(lcdMarginX, 14.0f, lcdW, lcdH)];
    [self.view addSubview:self.lcdView];

    // Nửa dưới: Click Wheel màu đỏ U2
    CGFloat wheelSize = MIN(224.0f, roundf(screenH * 0.46f));
    CGFloat wheelX = roundf((screenW - wheelSize) / 2.0f);
    CGFloat wheelY = lcdH + roundf((screenH - lcdH - wheelSize) / 2.0f) + 6.0f;
    self.clickWheel = [[ClickWheelView alloc] initWithFrame:CGRectMake(wheelX, wheelY, wheelSize, wheelSize)];
    self.clickWheel.delegate = self;
    [self.view addSubview:self.clickWheel];

    [self setupMusicLibrary];
    [self setupRootMenu];

    self.playbackTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                          target:self
                                                        selector:@selector(onTimerTick)
                                                        userInfo:nil
                                                         repeats:YES];
}

- (UIImage *)generateU2ArtworkWithText:(NSString *)badge {
    CGSize sz = CGSizeMake(180, 180);
    UIGraphicsBeginImageContextWithOptions(sz, YES, 0.0f);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    [[UIColor colorWithRed:0.06f green:0.06f blue:0.07f alpha:1.0f] setFill];
    CGContextFillRect(ctx, CGRectMake(0, 0, sz.width, sz.height));

    [[UIColor colorWithRed:0.80f green:0.07f blue:0.18f alpha:1.0f] setFill];
    CGContextFillEllipseInRect(ctx, CGRectMake(30, 30, 120, 120));

    [[UIColor colorWithRed:0.06f green:0.06f blue:0.07f alpha:1.0f] setFill];
    CGContextFillEllipseInRect(ctx, CGRectMake(68, 68, 44, 44));

    [[UIColor whiteColor] setFill];
    UIFont *f = [UIFont boldSystemFontOfSize:14.0f];
    CGSize ts = [badge sizeWithFont:f];
    [badge drawAtPoint:CGPointMake((sz.width - ts.width) / 2.0f, 154.0f) withFont:f];

    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

- (void)setupMusicLibrary {
    MPMediaQuery *songsQuery = [MPMediaQuery songsQuery];
    self.librarySongs = songsQuery.items;

    if (self.librarySongs.count > 0) {
        self.usingDemoLibrary = NO;
        self.musicPlayer = [MPMusicPlayerController iPodMusicPlayer];
        [self.musicPlayer beginGeneratingPlaybackNotifications];
    } else {
        self.usingDemoLibrary = YES;
        self.demoRating = 4;
        self.demoSongs = @[
            @{@"title": @"Vertigo", @"artist": @"U2", @"album": @"How to Dismantle an Atomic Bomb", @"duration": @194.0},
            @{@"title": @"With or Without You", @"artist": @"U2", @"album": @"The Joshua Tree", @"duration": @296.0},
            @{@"title": @"Beautiful Day", @"artist": @"U2", @"album": @"All That You Can't Leave Behind", @"duration": @248.0},
            @{@"title": @"Sunday Bloody Sunday", @"artist": @"U2", @"album": @"War", @"duration": @279.0},
            @{@"title": @"One", @"artist": @"U2", @"album": @"Achtung Baby", @"duration": @276.0}
        ];
    }
}

- (void)setupRootMenu {
    self.menuStack = [NSMutableArray array];
    NSArray *rootItems = @[
        @{@"title": @"Music", @"action": @"music", @"arrow": @YES},
        @{@"title": @"Songs", @"action": @"songs", @"arrow": @YES},
        @{@"title": @"Artists", @"action": @"artists", @"arrow": @YES},
        @{@"title": @"Albums", @"action": @"albums", @"arrow": @YES},
        @{@"title": @"Shuffle Songs", @"action": @"shuffle", @"arrow": @NO},
        @{@"title": @"Settings", @"action": @"settings", @"arrow": @YES},
        @{@"title": @"Now Playing", @"action": @"now_playing", @"arrow": @YES}
    ];
    [self.menuStack addObject:[@{
        @"title": @"iPod",
        @"items": rootItems,
        @"selectedIndex": @0
    } mutableCopy]];

    [self refreshCurrentMenuWithAnimation:0];
}

- (void)refreshCurrentMenuWithAnimation:(NSInteger)dir {
    NSMutableDictionary *top = [self.menuStack lastObject];
    NSArray *items = top[@"items"];
    NSInteger idx = [top[@"selectedIndex"] integerValue];
    if (items.count == 0) idx = 0;

    NSDictionary *currentItem = (items.count > 0) ? items[idx] : nil;
    UIImage *art = [self generateU2ArtworkWithText:@"U2 EDITION"];
    NSString *pTitle = currentItem[@"title"] ?: @"iPod Classic";
    NSUInteger count = self.usingDemoLibrary ? self.demoSongs.count : self.librarySongs.count;
    NSString *pSub = [NSString stringWithFormat:@"%lu Songs\n%@",
                      (unsigned long)count,
                      self.usingDemoLibrary ? @"Demo Library" : @"iPod Library"];

    if (currentItem[@"mediaItem"]) {
        MPMediaItem *mItem = currentItem[@"mediaItem"];
        MPMediaItemArtwork *mArt = [mItem valueForProperty:MPMediaItemPropertyArtwork];
        UIImage *realImg = [mArt imageWithSize:CGSizeMake(140, 140)];
        if (realImg) art = realImg;
        pTitle = [mItem valueForProperty:MPMediaItemPropertyTitle] ?: pTitle;
        pSub = [mItem valueForProperty:MPMediaItemPropertyArtist] ?: @"";
    } else if (currentItem[@"demoIndex"]) {
        NSInteger dIdx = [currentItem[@"demoIndex"] integerValue];
        NSDictionary *d = self.demoSongs[dIdx];
        pTitle = d[@"title"];
        pSub = d[@"album"];
    }

    self.lcdView.mode = LCDModeMenu;
    [self.lcdView setHeaderTitle:top[@"title"] isPlaying:[self isCurrentlyPlaying]];
    [self.lcdView updateMenuItems:items
                    selectedIndex:idx
                     previewImage:art
                     previewTitle:pTitle
                  previewSubtitle:pSub
                 animateDirection:dir];
}

- (BOOL)isCurrentlyPlaying {
    if (self.usingDemoLibrary) return self.demoPlaying;
    return (self.musicPlayer.playbackState == MPMusicPlaybackStatePlaying);
}

#pragma mark - ClickWheelViewDelegate

- (void)clickWheelDidScroll:(NSInteger)steps {
    if (self.lcdView.mode == LCDModeMenu) {
        NSMutableDictionary *top = [self.menuStack lastObject];
        NSArray *items = top[@"items"];
        if (items.count == 0) return;

        NSInteger idx = [top[@"selectedIndex"] integerValue] + steps;
        if (idx < 0) idx = 0;
        if (idx >= (NSInteger)items.count) idx = items.count - 1;
        top[@"selectedIndex"] = @(idx);
        [self refreshCurrentMenuWithAnimation:0];
    } else {
        if (self.lcdView.subMode == NowPlayingSubModeScrub) {
            if (self.usingDemoLibrary) {
                NSDictionary *d = self.demoSongs[self.demoIndex];
                NSTimeInterval dur = [d[@"duration"] doubleValue];
                self.demoElapsed = MIN(dur, MAX(0.0, self.demoElapsed + steps * 4.0));
            } else {
                NSTimeInterval cur = self.musicPlayer.currentPlaybackTime + steps * 4.0;
                self.musicPlayer.currentPlaybackTime = MAX(0.0, cur);
            }
            [self updateNowPlayingUI];
        } else if (self.lcdView.subMode == NowPlayingSubModeRating) {
            self.demoRating = MIN(5, MAX(0, self.demoRating + steps));
            [self updateNowPlayingUI];
        }
    }
}

- (void)clickWheelDidPressButton:(ClickWheelButton)button {
    switch (button) {
        case ClickWheelButtonMenu:
            if (self.lcdView.mode == LCDModeNowPlaying) {
                self.lcdView.subMode = NowPlayingSubModeNormal;
                [self refreshCurrentMenuWithAnimation:-1];
            } else if (self.menuStack.count > 1) {
                [self.menuStack removeLastObject];
                [self refreshCurrentMenuWithAnimation:-1];
            }
            break;

        case ClickWheelButtonSelect:
            if (self.lcdView.mode == LCDModeNowPlaying) {
                if (self.lcdView.subMode == NowPlayingSubModeNormal) {
                    self.lcdView.subMode = NowPlayingSubModeScrub;
                } else if (self.lcdView.subMode == NowPlayingSubModeScrub) {
                    self.lcdView.subMode = NowPlayingSubModeRating;
                } else {
                    self.lcdView.subMode = NowPlayingSubModeNormal;
                }
                [self updateNowPlayingUI];
            } else {
                [self handleMenuSelection];
            }
            break;

        case ClickWheelButtonPlayPause:
            [self togglePlayPause];
            break;

        case ClickWheelButtonNext:
            [self skipNext];
            break;

        case ClickWheelButtonPrev:
            [self skipPrev];
            break;
    }
}

- (void)handleMenuSelection {
    NSMutableDictionary *top = [self.menuStack lastObject];
    NSArray *items = top[@"items"];
    if (items.count == 0) return;
    NSInteger idx = [top[@"selectedIndex"] integerValue];
    NSDictionary *selected = items[idx];
    NSString *action = selected[@"action"];

    if ([action isEqualToString:@"music"]) {
        NSArray *sub = @[
            @{@"title": @"All Songs", @"action": @"songs", @"arrow": @YES},
            @{@"title": @"Artists", @"action": @"artists", @"arrow": @YES},
            @{@"title": @"Albums", @"action": @"albums", @"arrow": @YES}
        ];
        [self.menuStack addObject:[@{@"title": @"Music", @"items": sub, @"selectedIndex": @0} mutableCopy]];
        [self refreshCurrentMenuWithAnimation:1];

    } else if ([action isEqualToString:@"songs"]) {
        NSMutableArray *songItems = [NSMutableArray array];
        if (self.usingDemoLibrary) {
            for (NSInteger i = 0; i < (NSInteger)self.demoSongs.count; i++) {
                [songItems addObject:@{
                    @"title": self.demoSongs[i][@"title"],
                    @"action": @"play_demo",
                    @"demoIndex": @(i),
                    @"arrow": @NO
                }];
            }
        } else {
            for (MPMediaItem *m in self.librarySongs) {
                NSString *t = [m valueForProperty:MPMediaItemPropertyTitle] ?: @"Untitled";
                [songItems addObject:@{
                    @"title": t,
                    @"action": @"play_media",
                    @"mediaItem": m,
                    @"arrow": @NO
                }];
            }
        }
        [self.menuStack addObject:[@{@"title": @"Songs", @"items": songItems, @"selectedIndex": @0} mutableCopy]];
        [self refreshCurrentMenuWithAnimation:1];

    } else if ([action isEqualToString:@"artists"]) {
        NSMutableArray *artistItems = [NSMutableArray array];
        if (self.usingDemoLibrary) {
            [artistItems addObject:@{@"title": @"U2", @"action": @"songs", @"arrow": @YES}];
        } else {
            MPMediaQuery *q = [MPMediaQuery artistsQuery];
            for (MPMediaItemCollection *col in q.collections) {
                NSString *name = [col.representativeItem valueForProperty:MPMediaItemPropertyArtist] ?: @"Unknown";
                [artistItems addObject:@{
                    @"title": name,
                    @"action": @"collection",
                    @"collection": col,
                    @"arrow": @YES
                }];
            }
        }
        [self.menuStack addObject:[@{@"title": @"Artists", @"items": artistItems, @"selectedIndex": @0} mutableCopy]];
        [self refreshCurrentMenuWithAnimation:1];

    } else if ([action isEqualToString:@"albums"]) {
        NSMutableArray *albumItems = [NSMutableArray array];
        if (self.usingDemoLibrary) {
            [albumItems addObject:@{@"title": @"How to Dismantle an Atomic Bomb", @"action": @"songs", @"arrow": @YES}];
        } else {
            MPMediaQuery *q = [MPMediaQuery albumsQuery];
            for (MPMediaItemCollection *col in q.collections) {
                NSString *name = [col.representativeItem valueForProperty:MPMediaItemPropertyAlbumTitle] ?: @"Unknown";
                [albumItems addObject:@{
                    @"title": name,
                    @"action": @"collection",
                    @"collection": col,
                    @"arrow": @YES
                }];
            }
        }
        [self.menuStack addObject:[@{@"title": @"Albums", @"items": albumItems, @"selectedIndex": @0} mutableCopy]];
        [self refreshCurrentMenuWithAnimation:1];

    } else if ([action isEqualToString:@"collection"]) {
        MPMediaItemCollection *col = selected[@"collection"];
        NSMutableArray *subSongs = [NSMutableArray array];
        for (MPMediaItem *m in col.items) {
            NSString *t = [m valueForProperty:MPMediaItemPropertyTitle] ?: @"Untitled";
            [subSongs addObject:@{@"title": t, @"action": @"play_media", @"mediaItem": m, @"arrow": @NO}];
        }
        [self.menuStack addObject:[@{@"title": selected[@"title"], @"items": subSongs, @"selectedIndex": @0} mutableCopy]];
        [self refreshCurrentMenuWithAnimation:1];

    } else if ([action isEqualToString:@"shuffle"]) {
        if (self.usingDemoLibrary) {
            self.demoIndex = arc4random_uniform((uint32_t)self.demoSongs.count);
            self.demoElapsed = 0;
            self.demoPlaying = YES;
        } else if (self.librarySongs.count > 0) {
            [self.musicPlayer setQueueWithQuery:[MPMediaQuery songsQuery]];
            self.musicPlayer.shuffleMode = MPMusicShuffleModeSongs;
            [self.musicPlayer play];
        }
        [self openNowPlaying];

    } else if ([action isEqualToString:@"settings"]) {
        NSString *clickStatus = self.clickWheel.soundEnabled ? @"Clicker: ON" : @"Clicker: OFF";
        NSArray *setItems = @[
            @{@"title": clickStatus, @"action": @"toggle_click", @"arrow": @NO},
            @{@"title": @"Model: U2 Special Ed.", @"action": @"noop", @"arrow": @NO}
        ];
        [self.menuStack addObject:[@{@"title": @"Settings", @"items": setItems, @"selectedIndex": @0} mutableCopy]];
        [self refreshCurrentMenuWithAnimation:1];

    } else if ([action isEqualToString:@"toggle_click"]) {
        self.clickWheel.soundEnabled = !self.clickWheel.soundEnabled;
        NSString *clickStatus = self.clickWheel.soundEnabled ? @"Clicker: ON" : @"Clicker: OFF";
        top[@"items"] = @[
            @{@"title": clickStatus, @"action": @"toggle_click", @"arrow": @NO},
            @{@"title": @"Model: U2 Special Ed.", @"action": @"noop", @"arrow": @NO}
        ];
        [self refreshCurrentMenuWithAnimation:0];

    } else if ([action isEqualToString:@"play_demo"]) {
        self.demoIndex = [selected[@"demoIndex"] integerValue];
        self.demoElapsed = 0;
        self.demoPlaying = YES;
        [self openNowPlaying];

    } else if ([action isEqualToString:@"play_media"]) {
        MPMediaItem *m = selected[@"mediaItem"];
        [self.musicPlayer setQueueWithQuery:[MPMediaQuery songsQuery]];
        self.musicPlayer.nowPlayingItem = m;
        [self.musicPlayer play];
        [self openNowPlaying];

    } else if ([action isEqualToString:@"now_playing"]) {
        [self openNowPlaying];
    }
}

- (void)openNowPlaying {
    self.lcdView.mode = LCDModeNowPlaying;
    self.lcdView.subMode = NowPlayingSubModeNormal;
    [self updateNowPlayingUI];
}

- (void)togglePlayPause {
    if (self.usingDemoLibrary) {
        self.demoPlaying = !self.demoPlaying;
    } else {
        if (self.musicPlayer.playbackState == MPMusicPlaybackStatePlaying) {
            [self.musicPlayer pause];
        } else {
            [self.musicPlayer play];
        }
    }
    if (self.lcdView.mode == LCDModeNowPlaying) {
        [self updateNowPlayingUI];
    } else {
        NSMutableDictionary *top = [self.menuStack lastObject];
        [self.lcdView setHeaderTitle:top[@"title"] isPlaying:[self isCurrentlyPlaying]];
    }
}

- (void)skipNext {
    if (self.usingDemoLibrary) {
        self.demoIndex = (self.demoIndex + 1) % self.demoSongs.count;
        self.demoElapsed = 0;
    } else {
        [self.musicPlayer skipToNextItem];
    }
    if (self.lcdView.mode == LCDModeNowPlaying) [self updateNowPlayingUI];
}

- (void)skipPrev {
    if (self.usingDemoLibrary) {
        self.demoIndex = (self.demoIndex - 1 + self.demoSongs.count) % self.demoSongs.count;
        self.demoElapsed = 0;
    } else {
        [self.musicPlayer skipToPreviousItem];
    }
    if (self.lcdView.mode == LCDModeNowPlaying) [self updateNowPlayingUI];
}

- (void)onTimerTick {
    if (self.usingDemoLibrary && self.demoPlaying) {
        NSDictionary *d = self.demoSongs[self.demoIndex];
        NSTimeInterval dur = [d[@"duration"] doubleValue];
        self.demoElapsed += 0.5;
        if (self.demoElapsed >= dur) {
            [self skipNext];
        }
    }
    if (self.lcdView.mode == LCDModeNowPlaying) {
        [self updateNowPlayingUI];
    }
}

- (void)updateNowPlayingUI {
    [self.lcdView setHeaderTitle:@"Now Playing" isPlaying:[self isCurrentlyPlaying]];

    if (self.usingDemoLibrary) {
        NSDictionary *d = self.demoSongs[self.demoIndex];
        NSString *trackStr = [NSString stringWithFormat:@"%ld of %lu",
                              (long)(self.demoIndex + 1), (unsigned long)self.demoSongs.count];
        [self.lcdView updateNowPlayingTitle:d[@"title"]
                                     artist:d[@"artist"]
                                      album:d[@"album"]
                                    artwork:[self generateU2ArtworkWithText:@"U2"]
                                  trackInfo:trackStr
                                    elapsed:self.demoElapsed
                                   duration:[d[@"duration"] doubleValue]
                                     rating:self.demoRating];
    } else {
        MPMediaItem *item = self.musicPlayer.nowPlayingItem ?: [self.librarySongs firstObject];
        if (!item) return;

        NSString *title = [item valueForProperty:MPMediaItemPropertyTitle];
        NSString *artist = [item valueForProperty:MPMediaItemPropertyArtist];
        NSString *album = [item valueForProperty:MPMediaItemPropertyAlbumTitle];
        NSTimeInterval dur = [[item valueForProperty:MPMediaItemPropertyPlaybackDuration] doubleValue];
        NSTimeInterval cur = self.musicPlayer.currentPlaybackTime;
        MPMediaItemArtwork *mArt = [item valueForProperty:MPMediaItemPropertyArtwork];
        UIImage *img = [mArt imageWithSize:CGSizeMake(180, 180)] ?: [self generateU2ArtworkWithText:@"U2"];

        NSUInteger idx = [self.librarySongs indexOfObject:item];
        NSString *trackStr = (idx != NSNotFound)
            ? [NSString stringWithFormat:@"%lu of %lu", (unsigned long)(idx + 1), (unsigned long)self.librarySongs.count]
            : @"1 of 1";

        [self.lcdView updateNowPlayingTitle:title
                                     artist:artist
                                      album:album
                                    artwork:img
                                  trackInfo:trackStr
                                    elapsed:cur
                                   duration:dur
                                     rating:self.demoRating];
    }
}

@end