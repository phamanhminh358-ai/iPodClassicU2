#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ClickWheelButton) {
    ClickWheelButtonMenu,
    ClickWheelButtonNext,
    ClickWheelButtonPrev,
    ClickWheelButtonPlayPause,
    ClickWheelButtonSelect
};

@protocol ClickWheelViewDelegate <NSObject>
- (void)clickWheelDidScroll:(NSInteger)steps;
- (void)clickWheelDidPressButton:(ClickWheelButton)button;
@end

@interface ClickWheelView : UIView

@property (nonatomic, weak) id<ClickWheelViewDelegate> delegate;
@property (nonatomic, assign) BOOL soundEnabled;

@end