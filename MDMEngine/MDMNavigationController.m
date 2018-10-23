//
//  MDMNavigationController.m
//  MDMEngine
//
//  Created by 李华林 on 15/1/20.
//  Copyright (c) 2015年 李华林. All rights reserved.
/**************************************************************************************************/
/*                                      修改日志                                                    */
/*修改日期：2015年5月22日                                                                            */
/*修改人员：李华林                                                                                   */
/*修改内容：1、shouldAutorotate方法增加viewControl条件判断，防止其它界面旋转                              */
/**************************************************************************************************/
/**************************************************************************************************/
/*                                      修改日志                                                    */
/*修改日期：2015年5月22日                                                                            */
/*修改人员：李华林                                                                                   */
/*修改内容：1、shouldAutorotate方法增加viewControl条件判断，防止其它界面旋转                              */
/**************************************************************************************************/

#import "MDMNavigationController.h"
#import "MDMUltil.h"

@implementation MDMNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (self.navigationBar) {
        self.navigationBar.hidden = YES;
    }
//    if ([self respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
//        [self.interactivePopGestureRecognizer setDelegate:self];
//    }
}

//#pragma mark - Override
//- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
//{
//     // Hijack the push method to disable the gesture
////     if ([self respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
////         self.interactivePopGestureRecognizer.enabled = NO;
////     }
//
//     [super pushViewController:viewController animated:animated];
//}
//
//- (UIViewController *)popViewControllerAnimated:(BOOL)animated
//{
//    return [super popViewControllerAnimated:animated];
//}
//
//#pragma mark - UINavigationControllerDelegate
//- (void)navigationController:(UINavigationController *)navigationController
//        didShowViewController:(UIViewController *)viewController
//                     animated:(BOOL)animate
// {
//     if ([navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
//         navigationController.interactivePopGestureRecognizer.enabled = YES;
//     }
// }


//- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
//{
//    //if (_isOrientationPortrait)
//      //  return UIInterfaceOrientationIsPortrait(interfaceOrientation);
//    //else
//        return UIInterfaceOrientationIsLandscape(interfaceOrientation);
//}
//
//-(NSUInteger)supportedInterfaceOrientations
//{
////    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft;
//    return UIInterfaceOrientationMaskAllButUpsideDown;
//}
//
//- (BOOL)shouldAutorotate
//{
//    return YES;
//}


/*henry add the function*/
- (NSUInteger)supportedInterfaceOrientations
{
    return self.visibleViewController.supportedInterfaceOrientations;
}
- (BOOL)shouldAutorotate
{
    BOOL ret = NO;
    
    if ([self.visibleViewController isKindOfClass:NSClassFromString(@"MDMViewController")]) {
        ret = self.visibleViewController.shouldAutorotate;
    }
    printf("\n------------------->%d\n",ret);
    return ret;
}
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return [self.visibleViewController preferredInterfaceOrientationForPresentation];
}
//- (BOOL)prefersStatusBarHidden
//{
//    return YES; // 返回NO表示要显示，返回YES将hiden
//}
@end
