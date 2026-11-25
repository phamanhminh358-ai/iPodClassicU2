#import "ClickWheelView.h"
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#include <math.h>

@interface ClickWheelView ()
@property (nonatomic, assign) CGFloat lastAngle;
@property (nonatomic, assign) CGFloat accumulatedAngle;
@property (nonatomic, assign) BOOL didScroll;
@property (nonatomic, assign) BOOL touchActive;
@property (nonatomic, strong) UIView *centerButtonView;
@property (nonatomic, strong) NSArray *clickPlayers;
@property (nonatomic, assign) NSUInteger playerIndex;
@end

@implementation ClickWheelView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = NO;
        self.opaque = NO;
        self.soundEnabled = YES;
        self.multipleTouchEnabled = NO;
        [self setupSublayers];
        [self setupAudioClicker];
    }
    return self;
}

- (void)setupAudioClicker {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryAmbient error:nil];
    [session setActive:YES error:nil];

    // Tạo mẫu âm thanh click cơ học 12ms (22050Hz, 16-bit mono PCM WAV) ngay trong bộ nhớ
    uint32_t sampleRate = 22050;
    uint32_t numSamples = 264;
    uint32_t dataSize = numSamples * sizeof(int16_t);
    uint32_t fileSize = 36 + dataSize;

    NSMutableData *wavData = [NSMutableData dataWithCapacity:44 + dataSize];
    [wavData appendBytes:"RIFF" length:4];
    [wavData appendBytes:&fileSize length:4];
    [wavData appendBytes:"WAVE" length:4];
    [wavData appendBytes:"fmt " length:4];

    uint32_t fmtSize = 16;
    uint16_t audioFormat = 1;
    uint16_t numChannels = 1;
    uint32_t byteRate = sampleRate * 2;
    uint16_t blockAlign = 2;
    uint16_t bitsPerSample = 16;

    [wavData appendBytes:&fmtSize length:4];
    [wavData appendBytes:&audioFormat length:2];
    [wavData appendBytes:&numChannels length:2];
    [wavData appendBytes:&sampleRate length:4];
    [wavData appendBytes:&byteRate length:4];
    [wavData appendBytes:&blockAlign length:2];
    [wavData appendBytes:&bitsPerSample length:2];
    [wavData appendBytes:"data" length:4];
    [wavData appendBytes:&dataSize length:4];

    for (uint32_t i = 0; i < numSamples; i++) {
        float t = (float)i / (float)sampleRate;
        float env = expf(-t * 420.0f);
        float wave = sinf(2.0f * (float)M_PI * 2400.0f * t) * 0.65f
                   + sinf(2.0f * (float)M_PI * 950.0f * t) * 0.35f;
        if (i < 6) {
            wave += (i % 2 == 0) ? 0.4f : -0.4f;
        }
        float val = wave * env;
        if (val > 1.0f) val = 1.0f;
        if (val < -1.0f) val = -1.0f;
        int16_t sample = (int16_t)(val * 28000.0f);
        [wavData appendBytes:&sample length:2];
    }

    NSMutableArray *pool = [NSMutableArray arrayWithCapacity:4];
    for (int i = 0; i < 4; i++) {
        AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithData:wavData error:nil];
        if (player) {
            player.volume = 0.9f;
            [player prepareToPlay];
            [pool addObject:player];
        }
    }
    self.clickPlayers = [pool copy];
    self.playerIndex = 0;
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
    CGFloat size = MIN(self.bounds.size.width, self.bounds.size.height);
    CGRect wheelRect = CGRectInset(CGRectMake(0.0f, 0.0f, size, size), 3.0f, 3.0f);

    UIBezierPath *wheelPath = [UIBezierPath bezierPathWithOvalInRect:wheelRect];

    CGContextSaveGState(ctx);
    [wheelPath addClip];

    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    NSArray *colors = @[
        (id)[UIColor colorWithRed:0.86f green:0.08f blue:0.20f alpha:1.0f].CGColor,
        (id)[UIColor colorWithRed:0.74f green:0.05f blue:0.15f alpha:1.0f].CGColor,
        (id)[UIColor colorWithRed:0.60f green:0.03f blue:0.11f alpha:1.0f].CGColor
    ];
    CGFloat locations[] = {0.0f, 0.65f, 1.0f};
    CGGradientRef gradient = CGGradientCreateWithColors(space, (__bridge CFArrayRef)colors, locations);
    CGPoint start = CGPointMake(size * 0.5f, 0.0f);
    CGPoint end = CGPointMake(size * 0.5f, size);
    CGContextDrawLinearGradient(ctx, gradient, start, end, 0);
    CGGradientRelease(gradient);
    CGColorSpaceRelease(space);
    CGContextRestoreGState(ctx);

    UIBezierPath *borderPath = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(wheelRect, 1.0f, 1.0f)];
    borderPath.lineWidth = 2.0f;
    [[UIColor colorWithWhite:0.0f alpha:0.8f] setStroke];
    [borderPath stroke];

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
    if (!self.soundEnabled || self.clickPlayers.count == 0) return;
    AVAudioPlayer *player = self.clickPlayers[self.playerIndex];
    self.playerIndex = (self.playerIndex + 1) % self.clickPlayers.count;
    if (player.isPlaying) {
        [player stop];
    }
    player.currentTime = 0.0;
    [player play];
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

    if (dist < innerR * 0.9f) return;

    CGFloat currentAngle = atan2f(dy, dx);
    CGFloat delta = currentAngle - self.lastAngle;

    while (delta > M_PI) delta -= 2.0f * M_PI;
    while (delta < -M_PI) delta += 2.0f * M_PI;

    self.accumulatedAngle += delta;
    self.lastAngle = currentAngle;

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
        CGFloat angle = atan2f(dy, dx);
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
