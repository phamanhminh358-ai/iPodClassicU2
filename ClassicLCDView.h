#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, LCDMode) {
    LCDModeMenu,
    LCDModeNowPlaying
};

typedef NS_ENUM(NSInteger, NowPlayingSubMode) {
    NowPlayingSubModeNormal,
    NowPlayingSubModeScrub,
    NowPlayingSubModeRating
};

@interface ClassicLCDView : UIView

@property (nonatomic, assign) LCDMode mode;
@property (nonatomic, assign) NowPlayingSubMode subMode;

- (void)setHeaderTitle:(NSString *)title isPlaying:(BOOL)playing;
- (void)updateMenuItems:(NSArray *)items
          selectedIndex:(NSInteger)index
           previewImage:(UIImage *)image
           previewTitle:(NSString *)pTitle
        previewSubtitle:(NSString *)pSub
       animateDirection:(NSInteger)dir;

- (void)updateNowPlayingTitle:(NSString *)title
                       artist:(NSString *)artist
                        album:(NSString *)album
                      artwork:(UIImage *)artwork
                    trackInfo:(NSString *)trackInfo
                      elapsed:(NSTimeInterval)elapsed
                     duration:(NSTimeInterval)duration
                       rating:(NSInteger)rating;

@end