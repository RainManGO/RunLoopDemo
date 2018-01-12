//
//  ViewController.m
//  RunLoopDemo
//
//  Created by apple on 2017/5/18.
//  Copyright © 2017年 ZY. All rights reserved.
//

//苹果用 RunLoop 实现的功能
//AutoreleasePool
//事件响应
//手势识别
//界面更新
//定时器
//PerformSelecter
//关于GCD
//关于网络请求
//RunLoop 的实际应用举例
//AFNetworking
//AsyncDisplayKit

#import "ViewController.h"
#import "ZYThread.h"
@interface ViewController ()
//dispatch_source_t  必须强引用一个，不然在队列里会被释放。
@property(nonatomic,strong)dispatch_source_t  time;
@end

@implementation ViewController
{
    BOOL  isFinished;
}
- (void)viewDidLoad {
    [super viewDidLoad];
   
    [self runloopTimeExample];
   
    
}

/**
 Time时间源例子
 */
-(void)runloopTimeExample{
/**方式一 timeMethod会执行。
 *  scheduledTimerWithTimeInterval已经把time加到runloop中了，所以会执行。
 */
    
//   [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(timeMethod) userInfo:nil repeats:YES];
    
    
    
//方式二
    
//第一步：创建Timer 并启动
//结果：单独的创建time  [time fire] 之后，time并不会触发，
//原因：因为time的触发是依靠runloop的死循环机制
    
//    NSTimer  *  time  = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(timeMethod) userInfo:nil repeats:YES];
//    [time fire];

//第二步:将timer添加到runloop中
//结果：timer触发，
//原因：runloop循环执行timer方法
//未解决问题：有UI时间的时候，timer就会不执行。
    
//    NSTimer  *  time  = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(timeMethod) userInfo:nil   repeats:YES];
//    [[NSRunLoop currentRunLoop] addTimer:time forMode:NSDefaultRunLoopMode];
//    [time fire];


//第三步：拖动UI定时器会暂停的原因是因为runloop去执行UI模式的事件，没有时间去做默认模式的事情，我们可以把time源添加到ui模式，那么time可以在runloop在UI模式的时候执行timer，如果将timer加入两者的模式的时候，不论拖动或者不拖动UI都可以进行timer时间。
//结果：timer在UI拖动的时候依旧可以执行timer源，
//原因：runloop在两个模式都执行该时间源
    
//        NSTimer  *  time  = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(timeMethod) userInfo:nil   repeats:YES];
//#if 0
//        [[NSRunLoop currentRunLoop] addTimer:time forMode:NSDefaultRunLoopMode];
//        [[NSRunLoop currentRunLoop] addTimer:time forMode:UITrackingRunLoopMode];
//#else
//        [[NSRunLoop currentRunLoop] addTimer:time forMode:NSRunLoopCommonModes];
//#endif
//        [time fire];
    

//第四步解决：

    //处理一: NSThread开辟新线程   新的线程runLoop默认是不启动的 所以要进行线程保活
    /*   ZYThread  *  thread  = [[ZYThread  alloc]initWithBlock:^{
       NSTimer  *  time  = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(timeMethod) userInfo:nil   repeats:YES];
#if 0
       [[NSRunLoop currentRunLoop] addTimer:time forMode:NSDefaultRunLoopMode];
       [[NSRunLoop currentRunLoop] addTimer:time forMode:UITrackingRunLoopMode];
#else
       [[NSRunLoop currentRunLoop] addTimer:time forMode:NSRunLoopCommonModes];
#endif
       while (!isFinished) {
           [[NSRunLoop currentRunLoop] runUntilDate:[NSDate  dateWithTimeIntervalSinceNow:0.0001]];
       }
       //       [[NSRunLoop currentRunLoop] run];
       [time fire];
   }];
    
    [thread start];
     */
    
    
//方式三:GCD   解决time分析底层
    //第一步：首先创建源调用dispatch_source_create函数
           /*第一个参数：dispatch_source_type_t   是一个dispatch_source_type_s结构体参数，有各种类型例如：DISPATCH_SOURCE_TYPE_DATA_ADD  DISPATCH_SOURCE_TYPE_MACH_SEND
             DISPATCH_SOURCE_TYPE_SIGNAL  等等，不同的类型代表创建不同的源，功能也是不一样的。本例主要介绍时间源定时器功能。
             第二个参数：handle 句柄。源的回调方法设置，一般在下面单独设置，便于操作。
             第三个参数：mask  vm_address_t 关于地址的，一般不去操作默认0
             第四个参数：queue 源加入的队列
            */
    self.time   =   dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(0, 0));
    //设置事件源:dispatch_source_set_timer
            /*第一个参数：要设置的那个时间源
             第二个参数：开始时间。 DISPATCH_TIME_NOW 立即开始  dispatch_walltime计算开始时间
             第三个参数：间隔时间  NSEC_PER_SEC GCD的精度非常高 1*NSEC_PER_SEC 为一秒。自己算精度。NSTimer精度比较低
             第四个参数：leewayInSeconds精准度:允许的误差: 0 表示绝对精准
             */
    dispatch_source_set_timer(self.time, DISPATCH_TIME_NOW, 1.0*NSEC_PER_SEC, 0);
    //设置时间源的回调方法  回调方法还是在全局队列开辟的线程中
    dispatch_source_set_event_handler(self.time, ^{
        NSLog(@"1---%@",[NSThread currentThread]);
        //UI更新放在主线程中
        dispatch_async(dispatch_get_main_queue(), ^{
        });
    });
    //时间源默认状态是挂起的 dispatch_suspend  dispatch_resume恢复状态继续运行
    dispatch_resume(self.time);
}

-(void)timeMethod{
//第四步加：如果线程中加耗时操作 主线程还是卡顿，耗时操作还是要开线程
    NSLog(@"Thread--%@",[NSThread currentThread]);
#if 0
    [NSThread  sleepForTimeInterval:1.0];
#endif
    static int num = 0;
    NSLog(@"%d",num);
    num++;
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    isFinished   =  YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
