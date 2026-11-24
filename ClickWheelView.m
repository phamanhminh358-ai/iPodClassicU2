#import "ClickWheelView.h"
#import <QuartzCore/QuartzCore.h>
#import <AudioToolbox/AudioToolbox.h>
#include <math.h>

@interface ClickWheelView ()
@property (nonatomic, assign) CGFloat lastAngle;
@property (nonatomic, assign) CGFloat accumulatedAngle;
@property (nonatomic, assign) BOOL didScroll;
@property (nonatomic, assign) BOOL touchActive;
@property (nonatomic, strong) UIView *centerButtonView;
@end

@implementation ClickWheelView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.soundEnabled = YES;
        self.multipleTouchEnabled = NO;
        [self setupSublayers];
    }
    return self;
}

- (void)setupSublayers {
    CGFloat size = MIN(self.bounds.size.width, self.bounds.size.height);
    CGFloat centerSize = roundf(size * 0.35f);
    CGFloat offset = roundf((size - centerSize) / 2.0f);

    self.centerButtonView = [[UIView alloc] initWithFrame:CGRectMake(offset, offset, centerSize, centerSize)];
    self.centerButtonView.backgroundColor = [UIColor colorWithRed:0.06f green:0.06f blue:0.07f alpha:1.0f];
    self.centerButtonView.layer.cornerRadius = centerSize / 2.0f;
    self.centerButtonView.layer.borderWidth = 1.5f;
    self.centerButtonView.layer.borderColor = [UIColor colorWithWhite:0.0f alpha:0.65f].CGColor;
    self.centerButtonView.userInteractionEnabled = NO;

    CAGradientLayer *gloss = [CAGradientLayer layer];
    gloss.frame = self.centerButtonView.bounds;
    gloss.cornerRadius = centerSize / 2.0f;
    gloss.colors = @[
        (id)[UIColor colorWithWhite:0.18f alpha:1.0f].CGColor,
        (id)[UIColor colorWithWhite:0.05f alpha:1.0f].CGColor,
        (id)[UIColor colorWithWhite:0.10f alpha:1.0f].CGColor
    ];
    gloss.locations = @[@0.0, @0.55, @1.0];
    [self.centerButtonView.layer addSublayer:gloss];

    [self addSubview:self.centerButtonView];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGFloat size = MIN(rect.size.width, rect.size.height);
    CGRect wheelRect = CGRectInset(CGRectMake(0, 0, size, size), 2.0f, 2.0f);

    // Đổ bóng viền ngoài Click Wheel
    CGContextSaveGState(ctx);
    CGContextAddEllipseInRect(ctx, wheelRect);
    CGContextClip(ctx);

    // Màu đỏ đặc trưng của iPod U2 Special Edition
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    NSArray *colors = @[
        (id)[UIColor colorWithRed:0.86f green:0.08f blue:0.20f alpha:1.0f].CGColor,
        (id)[UIColor colorWithRed:0.74f green:0.05f blue:0.15f alpha:1.0f].CGColor,
        (id)[UIColor colorWithRed:0.60f green:0.03f blue:0.11f alpha:1.0f].CGColor
    ];
    CGFloat locations[] = {0.0f, 0.65f, 1.0f};
    CGGradientRef gradient = CGGradientCreateWithColors(space, (__bridge CFArrayRef)colors, locations);
    CGPoint start = CGPointMake(size * 0.3f, size * 0.15f);
    CGPoint end = CGPointMake(size * 0.7f, size * 0.9f);
    CGContextDrawLinearGradient(ctx, gradient, start, end, 0);
    CGGradientRelease(gradient);
    CGColorSpaceRelease(space);
    CGContextRestoreGState(ctx);

    // Viền mảnh phân cách vỏ đen và vòng đỏ
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithWhite:0.0f alpha:0.8f].CGColor);
    CGContextSetLineWidth(ctx, 2.0f);
    CGContextStrokeEllipseInRect(ctx, wheelRect);

    // Vẽ chữ và biểu tượng 4 hướng màu trắng sắc nét
    [[UIColor colorWithWhite:0.96f alpha:0.95f] setFill];
    UIFont *menuFont = [UIFont boldSystemFontOfSize:12.5f];
    NSString *menuText = @"MENU";
    CGSize menuSize = [menuText sizeWithFont:menuFont];
    [menuText drawAtPoint:CGPointMake((size - menuSize.width) / 2.0f, 15.0f) withFont:menuFont];

    UIFont *iconFont = [UIFont boldSystemFontOfSize:13.0f];
    NSString *prevText = @"|<<";
    CGSize prevSize = [prevText sizeWithFont:iconFont];
    [prevText drawAtPoint:CGPointMake(14.0f, (size - prevSize.height) / 2.0f) withFont:iconFont];

    NSString *nextText = @">>|";
    CGSize nextSize = [nextText sizeWithFont:iconFont];
    [nextText drawAtPoint:CGPointMake(size - nextSize.width - 14.0f, (size - nextSize.height) / 2.0f) withFont:iconFont];

    NSString *playText = @"> ||";
    CGSize playSize = [playText sizeWithFont:iconFont];
    [playText drawAtPoint:CGPointMake((size - playSize.width) / 2.0f, size - playSize.height - 14.0f) withFont:iconFont];
}

- (void)playClickSound {
    if (self.soundEnabled) {
        AudioServicesPlaySystemSound(1104);
    }
}

- (CGPoint)wheelCenter {
    return CGPointMake(self.bounds.size.width / 2.0f, self.bounds.size.height / 2.0f);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self];
    CGPoint c = [self wheelCenter];
    CGFloat dx = p.x - c.x;
    CGFloat dy = p.y - c.y;
    CGFloat dist = sqrtf(dx * dx + dy * dy);
    CGFloat outerR = self.bounds.size.width / 2.0f;

    if (dist > outerR) {
        self.touchActive = NO;
        return;
    }

    self.touchActive = YES;
    self.didScroll = NO;
    self.accumulatedAngle = 0.0f;
    self.lastAngle = atan2f(dy, dx);

    CGFloat innerR = self.centerButtonView.bounds.size.width / 2.0f;
    if (dist <= innerR) {
        self.centerButtonView.alpha = 0.75f;
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!self.touchActive) return;

    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self];
    CGPoint c = [self wheelCenter];
    CGFloat dx = p.x - c.x;
    CGFloat dy = p.y - c.y;
    CGFloat dist = sqrtf(dx * dx + dy * dy);
    CGFloat innerR = self.centerButtonView.bounds.size.width / 2.0f;

    // Bỏ qua xoay nếu ngón tay đang nằm trong nút giữa
    if (dist < innerR * 0.9f) return;

    CGFloat currentAngle = atan2f(dy, dx);
    CGFloat delta = currentAngle - self.lastAngle;

    while (delta > M_PI) delta -= 2.0f * M_PI;
    while (delta < -M_PI) delta += 2.0f * M_PI;

    self.accumulatedAngle += delta;
    self.lastAngle = currentAngle;

    // Mỗi 14 độ xoay tương ứng 1 nấc danh sách
    CGFloat stepThreshold = 14.0f * (M_PI / 180.0f);
    NSInteger steps = 0;

    while (self.accumulatedAngle >= stepThreshold) {
        steps++;
        self.accumulatedAngle -= stepThreshold;
    }
    while (self.accumulatedAngle <= -stepThreshold) {
        steps--;
        self.accumulatedAngle += stepThreshold;
    }

    if (steps != 0) {
        self.didScroll = YES;
        self.centerButtonView.alpha = 1.0f;
        [self playClickSound];
        if ([self.delegate respondsToSelector:@selector(clickWheelDidScroll:)]) {
            [self.delegate clickWheelDidScroll:steps];
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    self.centerButtonView.alpha = 1.0f;
    if (!self.touchActive) return;
    self.touchActive = NO;

    if (self.didScroll) return;

    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self];
    CGPoint c = [self wheelCenter];
    CGFloat dx = p.x - c.x;
    CGFloat dy = p.y - c.y;
    CGFloat dist = sqrtf(dx * dx + dy * dy);
    CGFloat outerR = self.bounds.size.width / 2.0f;
    CGFloat innerR = self.centerButtonView.bounds.size.width / 2.0f;

    if (dist > outerR) return;

    [self playClickSound];

    ClickWheelButton pressed;
    if (dist <= innerR) {
        pressed = ClickWheelButtonSelect;
    } else {
        CGFloat angle = atan2f(dy, dx); // -PI tới PI
        if (angle >= -3.0f * M_PI / 4.0f && angle < -M_PI / 4.0f) {
            pressed = ClickWheelButtonMenu;
        } else if (angle >= -M_PI / 4.0f && angle < M_PI / 4.0f) {
            pressed = ClickWheelButtonNext;
        } else if (angle >= M_PI / 4.0f && angle < 3.0f * M_PI / 4.0f) {
            pressed = ClickWheelButtonPlayPause;
        } else {
            pressed = ClickWheelButtonPrev;
        }
    }

    if ([self.delegate respondsToSelector:@selector(clickWheelDidPressButton:)]) {
        [self.delegate clickWheelDidPressButton:pressed];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    self.centerButtonView.alpha = 1.0f;
    self.touchActive = NO;
}

@end