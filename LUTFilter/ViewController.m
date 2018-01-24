//
//  ViewController.m
//  LUTFilter
//
//  Created by zhuyongqing on 2017/12/13.
//  Copyright © 2017年 zhuyongqing. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "ILGLKImageView.h"
#import <GLKit/GLKit.h>
#import "CIFilter+LUT.h"
#import <GPUImage/GPUImage.h>
#import "GpUImageScaleFilter.h"
#import "GPUImageSoulFilter.h"
@interface ViewController (){
    NSInteger _faildCount;
    CIImage *_lastCIImage;    //最后获取到的图片
    CMTime _lastTime;    //最后一次时间
    UIImageView *_show;
    float _scaleCount;
}

@property(nonatomic,strong) AVPlayer *player;

@property(nonatomic,strong) AVPlayerItemVideoOutput *videoOutPut;

@property(nonatomic,strong) ILGLKImageView *glkImageView;

@property(nonatomic,strong) CADisplayLink *disPlayLink;

@property(nonatomic,strong) dispatch_queue_t renderQueue;

@property (nonatomic, strong) GPUImagePicture *picture;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
     _renderQueue = dispatch_queue_create("com.renderQueue", DISPATCH_QUEUE_SERIAL);
    [self setUpUI];

//    self.disPlayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
//    self.disPlayLink.frameInterval = 2;
//    [self.disPlayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
//
//    GPUImageView *imageView = [[GPUImageView alloc] initWithFrame:self.view.bounds];
//    [self.view addSubview:imageView];
    
//    UIImage *image = [UIImage imageNamed:@"test"];
    
//    [filter addTarget:imageView];
    
//    self.picture = picture;
//    self.filter = filter;
    _scaleCount = 1.1;
}



- (void)setUpUI{
    
    AVPlayerItem *item = [[AVPlayerItem alloc] initWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"IMG_0019.mp4" ofType:nil]]];
    self.player = [[AVPlayer alloc] initWithPlayerItem:item];
    
    [self createVideoOutPut];
    
    [self glkImageView];
    
    self.disPlayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(refreshDisplay:)];
//    self.disPlayLink.frameInterval = 2;
    [self.disPlayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
    [self.player play];
}

- (void)refreshDisplay:(CADisplayLink *)sender {
    [self renderCIImageWithCIFilter];
}


#pragma mark - 取出每一帧 渲染
- (void)renderCIImageWithCIFilter{
    
    dispatch_async(_renderQueue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            glClear(GL_COLOR_BUFFER_BIT);
        });
        
        CMTime time = [_videoOutPut itemTimeForHostTime:CACurrentMediaTime()];
        if ([_videoOutPut hasNewPixelBufferForItemTime:time]) {
            
            _faildCount = 0;
            
            CVPixelBufferRef pixelBuffer = NULL;
            
            pixelBuffer = [_videoOutPut copyPixelBufferForItemTime:time itemTimeForDisplay:nil];
            if (!pixelBuffer) {
                return ;
            }
            
            __block CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
            CVPixelBufferRelease(pixelBuffer);
            
            _lastCIImage = ciImage;
            _lastTime = time;
//
            //添加滤镜等效果
            [self renderCIImageWithCIImage:ciImage];
            
            
        }else{
            _faildCount++;
            
            //使用上次的image
            if (CMTimeGetSeconds(time) == CMTimeGetSeconds(_lastTime) && _lastCIImage) {
                
                [self renderCIImageWithCIImage:_lastCIImage];
                
                _faildCount = 0;
                
            }else if (_faildCount == 30){
                _faildCount = 0;
                NSLog(@"------------");
                [self.disPlayLink setPaused:YES];
                [self createVideoOutPut];
            }
            
        }
        
    });
    
}

- (void)renderCIImageWithCIImage:(CIImage *)ciImage{
    //    CGSize imageSize = CGSizeMake(ciImage.extent.size.width/2, ciImage.extent.size.height/2);
    //    if (!CGSizeEqualToSize(imageSize, _videoManager.currentVideoInfo.videoSize)) {
    //        _videoManager.currentVideoInfo.videoSize = imageSize;
    //        [self setPreImageViewSize];
    //    }
    
    
    CIContext *content = [CIContext contextWithOptions:nil];
    CGImageRef img = [content createCGImage:ciImage fromRect:[ciImage extent]];
    GPUImagePicture *picture = [[GPUImagePicture alloc] initWithImage:[[UIImage alloc] initWithCGImage:img]];
    CGImageRelease(img);
    
    GpUImageScaleFilter *scaleFilter = [[GpUImageScaleFilter alloc] init];
    
    _scaleCount += 0.005;
    if (_scaleCount >= 1.2) {
        _scaleCount = 1.1;
    }
    
    scaleFilter.scale = _scaleCount;
    
    [scaleFilter useNextFrameForImageCapture];
    [picture addTarget:scaleFilter];
    
    [picture processImageWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            self.glkImageView.ciImage = [[CIImage alloc] initWithCGImage:[scaleFilter imageFromCurrentFramebuffer].CGImage];
        });
    }];
    
    
//    [self changCIImageWithciImage:ciImage];
    //    CIImage *play = [[ILEditVideoTool shareInstance] blurFilterImageWithCIImage:ciImage];
//    dispatch_async(dispatch_get_main_queue(), ^{
//        self.glkImageView.ciImage = ciImage;
//    });
}

- (void)changCIImageWithciImage:(CIImage *)ciImage{
    
    // Create filter
//    CIFilter *lutFilter = [CIFilter filterWithLUT:@"lookup_glitch" dimension:64];
//    // Set parameter
//    [lutFilter setValue:ciImage forKey:@"inputImage"];
////
//    CIFilter *lutFilter2 = [CIFilter filterWithLUT:@"lookup_vertigo" dimension:64];
//    [lutFilter2 setValue:lutFilter.outputImage forKey:kCIInputImageKey];
//
//    CIFilter *lutFilter3 = [CIFilter filterWithLUT:@"oldmovie" dimension:64];
//    [lutFilter3 setValue:ciImage forKey:kCIInputImageKey];
    
//    CIFilter *lutFilter4 = [CIFilter filterWithLUT:@"noise" dimension:64];
//    [lutFilter4 setValue:lutFilter3.outputImage forKey:kCIInputImageKey];
    
//    UIImage *image = [UIImage imageNamed:@"123.jpg"];
    // 初始化一个GPUImagePicture
    // GPUImagePicture是一个GPUImage的输出源(GPUImageOutput)
//    GPUImagePicture *picture  = [[GPUImagePicture alloc] initWithImage:[UIImage imageNamed:@"test"]];
//    // 使用我们自定义的3D滤镜
//    GPUImage3DFilter *filter = [[GPUImage3DFilter alloc] init];
//
//    // 告诉GPUImageFilter我们传输的下一帧数据是来自Image
//    [filter useNextFrameForImageCapture];
//
//    // picture添加他的输出目标
//    [picture addTarget:filter];
//
//    // picture开始处理图片
//    [picture processImageWithCompletionHandler:^{
//        // 从效果链的最后一级取出结果，这里的效果链最后一级是3DFilter
//        UIImage *image1 = [filter imageFromCurrentFramebuffer];
//        self.glkImageView.ciImage = [CIImage imageWithCGImage:image1.CGImage];
//    }];
    
//    return lutFilter3.outputImage;
}

- (ILGLKImageView *)glkImageView{
    if (!_glkImageView) {
        _glkImageView = [[ILGLKImageView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.frame)/2 - CGRectGetWidth(self.view.frame)/2, CGRectGetWidth(self.view.frame), CGRectGetWidth(self.view.frame))];
        [self.view addSubview:_glkImageView];
    }
    return _glkImageView;
}


- (void)createVideoOutPut{
    //
    
    //    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange),kCVPixelBufferPixelFormatTypeKey,
                             nil];
    
    
    if (_videoOutPut) {
        [_player.currentItem removeOutput:_videoOutPut];
    }
    _videoOutPut = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:options];
    [_player.currentItem addOutput:_videoOutPut];
    
    [self.disPlayLink setPaused:NO];
    
    //    });
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
