//
//  BageValue.m
//  QQ粘性动画
//
//  Created by 刘斌鹏 on 2018/6/6.
//  Copyright © 2018年 杭城小刘. All rights reserved.
//

#import "BageValue.h"

@interface BageValue()

@property (nonatomic, strong) UIView *smallCircle;
@property (nonatomic, weak) CAShapeLayer *shapeLayer;
@end

@implementation BageValue

//Xib加载
- (void)awakeFromNib{
    [super awakeFromNib];
    [self setup];
}
//代码初始化
- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

//初始化
- (void)setup{
    //设置大圆
    self.layer.cornerRadius = self.bounds.size.width/2;
    self.titleLabel.font = [UIFont systemFontOfSize:12];
    [self setBackgroundColor:[UIColor redColor]];
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self addGestureRecognizer:panGesture];
    
    //设置小圆
    UIView *smallCircle = [[UIView alloc] init];
    smallCircle.frame = self.frame;
    smallCircle.backgroundColor = self.backgroundColor;
    smallCircle.layer.cornerRadius = self.layer.cornerRadius;
    [self.superview insertSubview:smallCircle belowSubview:self];
    self.smallCircle = smallCircle;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.smallCircle.frame = self.frame;
}

- (void)setHighlighted:(BOOL)highlighted{
    //去掉按钮点击的高亮效果
}

- (void)pan:(UIPanGestureRecognizer *)pan{
    //当前移动的偏移量
    CGPoint transP = [pan translationInView:self];
    //改变红点的位置
    //transform并没有修改自身的 center（center 是 layer 的position），只是修改了 frame
    NSLog(@"偏移量:%@",NSStringFromCGPoint(transP));
    CGPoint center = self.center;
    center.x += transP.x;
    center.y += transP.y;
    self.center = center;
    
    //self.transform = CGAffineTransformTranslate(self.transform, transP.x, transP.y);
    //手势复位:设置坐标原点位上次的坐标
    [pan setTranslation:CGPointZero inView:self];
    
    CGFloat distance = [self distanceWith:self.smallCircle bigCircle:self];
    NSLog(@"%f",distance);
    
    
    CGFloat smallCircleRadius = self.bounds.size.width * 0.5;
    smallCircleRadius = smallCircleRadius - distance/10;
    
    if (smallCircleRadius < 3) {
        smallCircleRadius = 3;
    }
    self.smallCircle.bounds = CGRectMake(0, 0, smallCircleRadius*2, smallCircleRadius*2);
    self.smallCircle.layer.cornerRadius = smallCircleRadius;
    
    if (self.smallCircle.hidden == NO) {
        //返回一个不规则的路径
        UIBezierPath *path = [self drawTracertWithSmallCircle:self.smallCircle bigCircle:self];
        //将形状转换为一个形状图层
        self.shapeLayer.path = path.CGPath;//根据路径生成形状
    }
    //创建形状图层
    [self.superview.layer insertSublayer:self.shapeLayer atIndex:0];
    
    if (distance > 60) {
        self.smallCircle.hidden = YES;
        [self.shapeLayer removeFromSuperlayer];
    }
    
    if (pan.state == UIGestureRecognizerStateEnded) {
        //结束手势
        if (distance < 60) {
            [self.shapeLayer removeFromSuperlayer];
            self.center = self.smallCircle.center;
            self.smallCircle.hidden = NO;
        }
        else{
            //手势拖拽超过60则播放一个动画
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.bounds];
            
            NSMutableArray *images = [NSMutableArray array];
            
            for (int i=0; i<8; i++) {
                NSString *imageName = [NSString stringWithFormat:@"%d",i+1];
                UIImage *image = [UIImage imageNamed:imageName];
                [images addObject:image];
            }
            imageView.animationImages = images;
            [imageView setAnimationDuration:1];
            [imageView startAnimating];
            [self addSubview:imageView];
            //动画结束移除本身
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self removeFromSuperview];
            });
        }
    }
    
}


- (CGFloat )distanceWith:(UIView *)smallCircle bigCircle:(UIView *)bigScirle{
    CGFloat offsetX = bigScirle.frame.origin.x - smallCircle.frame.origin.x;
    CGFloat offsetY = bigScirle.frame.origin.y - smallCircle.frame.origin.y;
    return sqrt( pow(offsetX, 2) + pow(offsetY, 2));
}

//将2个圆运行的变化轨迹用代码模拟
- (UIBezierPath *)drawTracertWithSmallCircle:(UIView *)smallCircle bigCircle:(UIView *)bigCircle{
    
    CGFloat X1 = smallCircle.center.x;
    CGFloat X2 = bigCircle.center.x;
    CGFloat Y1 = smallCircle.center.y;
    CGFloat Y2 = bigCircle.center.y;
    
    CGFloat r1 = smallCircle.bounds.size.width/2;
    CGFloat r2 = bigCircle.bounds.size.width/2;
    
    CGFloat d = [self distanceWith:smallCircle bigCircle:bigCircle];
    //Ø 代表角度
    CGFloat SinØ = (X2 - X1)/d;
    CGFloat CosØ = (Y2 - Y1)/d;
    
    CGPoint pointA = CGPointMake(X1 - r1*CosØ, Y1 + r1*SinØ);

    CGPoint pointB = CGPointMake(X1 + r1*CosØ, Y1 - r1*SinØ);
    
    CGPoint pointC = CGPointMake(X2 + r2*CosØ, Y2 - r2*SinØ);
    
    CGPoint pointD = CGPointMake(X2 - r2*CosØ, Y2 + r2*SinØ);
    
    CGPoint pointO = CGPointMake(X1 + SinØ *d/2, Y1 + CosØ*d/2);
    
    CGPoint pointP = CGPointMake(X1 + SinØ *d/2,Y1 + CosØ*d/2 );

    //描述路径
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    //AB
    [path moveToPoint:pointA];
    [path addLineToPoint:pointB];
    
    //BC(曲线)
    [path addQuadCurveToPoint:pointC controlPoint:pointP];
    
    //CD
    [path addLineToPoint:pointD];
    
    //DA(曲线)
    [path addQuadCurveToPoint:pointA controlPoint:pointO];
    
    return path;
}

#pragma mark -- getter

- (CAShapeLayer *)shapeLayer{
    if (!_shapeLayer) {
        CAShapeLayer *shapelayer = [CAShapeLayer layer];
        shapelayer.fillColor = [UIColor redColor].CGColor;
        _shapeLayer = shapelayer;
    }
    return _shapeLayer;
}

@end
