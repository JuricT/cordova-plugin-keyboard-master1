/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at
 http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#import "CDVKeyboard.h"
#import <Cordova/CDVAvailability.h>
#import <objc/runtime.h>

#ifndef __CORDOVA_3_2_0
#warning "The keyboard plugin is only supported in Cordova 3.2 or greater, it may not work properly in an older version. If you do use this plugin in an older version, make sure the HideKeyboardFormAccessoryBar and KeyboardShrinksView preference values are false."
#endif

@interface CDVKeyboard () <UIScrollViewDelegate>

@property (nonatomic, readwrite, assign) BOOL keyboardIsVisible;

@end

@implementation CDVKeyboard

- (id)settingForKey:(NSString*)key
{
    return [self.commandDelegate.settings objectForKey:[key lowercaseString]];
}

#pragma mark Initialize
- (void)updateContent:(CDVInvokedUrlCommand *)command {
      if (@available(iOS 12, *)) {
            self.webView.scrollView.scrollEnabled = !self.disableScrollingInShrinkView; // Order intentionally swapped.
            screen.size.height -= keyboardIntersection.size.height;

            CGSize revisedSize = CGSizeMake(self.webView.scrollView.frame.size.width, self.webView.scrollView.frame.size.height - keyboard.size.height);
            //CGSize revisedSize = CGSizeMake(self.webView.scrollView.frame.size.width, self.webView.scrollView.frame.size.height + keyboard.size.height);
            self.webView.scrollView.contentSize = revisedSize;
      }
        
}
- (void)returnKeyType:(CDVInvokedUrlCommand *)command {
    NSString* echo = [command.arguments objectAtIndex:0];
    NSString* returnKeyType = [command.arguments objectAtIndex:1];
  if([echo isEqualToString:@"returnKeyType"]) {
        IMP darkImp = imp_implementationWithBlock(^(id _s) {
           //return UIKeyboardAppearanceDark;
           //return UIReturnKeyDone;
           //return UIReturnKeyTypeSend;
         //if([returnKeyType isEqualToString:@"send"])
          //  return UIReturnKeySend;
         if([returnKeyType isEqualToString:@"go"]) {
            return UIReturnKeyGo;
         } else if([returnKeyType isEqualToString:@"google"]) {
            return UIReturnKeyGoogle;
         } else if([returnKeyType isEqualToString:@"join"]) {
            return UIReturnKeyJoin;
         } else if([returnKeyType isEqualToString:@"next"]) {
            return UIReturnKeyNext;
         } else if([returnKeyType isEqualToString:@"route"]) {
            return UIReturnKeyRoute;
         } else if([returnKeyType isEqualToString:@"search"]) {
            return UIReturnKeySearch;
         } else if([returnKeyType isEqualToString:@"send"]) {
            return UIReturnKeySend;
         } else if([returnKeyType isEqualToString:@"yahoo"]) {
            return UIReturnKeyYahoo;
         } else if([returnKeyType isEqualToString:@"done"]) {
            return UIReturnKeyDone;
         } else if([returnKeyType isEqualToString:@"emergencycall"]) {
            return UIReturnKeyEmergencyCall;
         }
         return UIReturnKeyDefault;
       });

    for (NSString* classString in @[@"UIWebBrowserView", @"UITextInputTraits"]) {
        Class c = NSClassFromString(classString);
       // Method m = class_getInstanceMethod(c, @selector(keyboardAppearance));
      Method m = class_getInstanceMethod(c, @selector(returnKeyType));

        if (m != NULL) {
            method_setImplementation(m, darkImp);
        } else {
          //  class_addMethod(c, @selector(keyboardAppearance), darkImp, "l@:");
           class_addMethod(c, @selector(returnKeyType), darkImp, "l@:");
        }
    }
    }
}
- (void)pluginInitialize
{
    NSString* setting = nil;
 
    setting = @"HideKeyboardFormAccessoryBar";
    if ([self settingForKey:setting]) {
        self.hideFormAccessoryBar = [(NSNumber*)[self settingForKey:setting] boolValue];
    }

    setting = @"KeyboardShrinksView";
    if ([self settingForKey:setting]) {
        self.shrinkView = [(NSNumber*)[self settingForKey:setting] boolValue];
    }

    setting = @"DisableScrollingWhenKeyboardShrinksView";
    if ([self settingForKey:setting]) {
        self.disableScrollingInShrinkView = [(NSNumber*)[self settingForKey:setting] boolValue];
    }
    
   
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    __weak CDVKeyboard* weakSelf = self;

    _keyboardShowObserver = [nc addObserverForName:UIKeyboardDidShowNotification
                                            object:nil
                                             queue:[NSOperationQueue mainQueue]
                                        usingBlock:^(NSNotification* notification) {
            [weakSelf.commandDelegate evalJs:@"Keyboard.fireOnShow();"];
                                        }];
    _keyboardHideObserver = [nc addObserverForName:UIKeyboardDidHideNotification
                                            object:nil
                                             queue:[NSOperationQueue mainQueue]
                                        usingBlock:^(NSNotification* notification) {
            [weakSelf.commandDelegate evalJs:@"Keyboard.fireOnHide();"];
                                        }];

    _keyboardWillShowObserver = [nc addObserverForName:UIKeyboardWillShowNotification
                                                object:nil
                                                 queue:[NSOperationQueue mainQueue]
                                            usingBlock:^(NSNotification* notification) {
            [weakSelf.commandDelegate evalJs:@"Keyboard.fireOnShowing();"];
            weakSelf.keyboardIsVisible = YES;
                                            }];
    _keyboardWillHideObserver = [nc addObserverForName:UIKeyboardWillHideNotification
                                                object:nil
                                                 queue:[NSOperationQueue mainQueue]
                                            usingBlock:^(NSNotification* notification) {
            [weakSelf.commandDelegate evalJs:@"Keyboard.fireOnHiding();"];
            weakSelf.keyboardIsVisible = NO;
                                            }];

    _shrinkViewKeyboardWillChangeFrameObserver = [nc addObserverForName:UIKeyboardWillChangeFrameNotification
                                                                 object:nil
                                                                  queue:[NSOperationQueue mainQueue]
                                                             usingBlock:^(NSNotification* notification) {
                                                                 [weakSelf performSelector:@selector(shrinkViewKeyboardWillChangeFrame:) withObject:notification afterDelay:0];
                                                                 CGRect screen = [[UIScreen mainScreen] bounds];
                                                                 //CGRect screen = [[[UIApplication sharedApplication] keyWindow] frame];
                                                                 CGRect keyboard = ((NSValue*)notification.userInfo[@"UIKeyboardFrameEndUserInfoKey"]).CGRectValue;
                                                                 CGRect intersection = CGRectIntersection(screen, keyboard);
                                                                 CGFloat height = MIN(intersection.size.width, intersection.size.height);
                                                                 [weakSelf.commandDelegate evalJs: [NSString stringWithFormat:@"cordova.fireWindowEvent('keyboardHeightWillChange', { 'keyboardHeight': %f })", height]];
                                                             }];
 
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_pickerViewWillBeShown:) name: UIKeyboardWillShowNotification object:nil];
 
  
    self.webView.scrollView.delegate = self;
 /*
   // NSString* echo = [command.arguments objectAtIndex:0];
   NSString* returnKeyType = @"go";
  //if([echo isEqualToString:@"returnKeyType"]) {
        IMP darkImp = imp_implementationWithBlock(^(id _s) {
           //return UIKeyboardAppearanceDark;
           //return UIReturnKeyDone;
           //return UIReturnKeyTypeSend;
         //if([returnKeyType isEqualToString:@"send"])
          //  return UIReturnKeySend;
         if([returnKeyType isEqualToString:@"go"]) {
            return UIReturnKeyGo;
         } else if([returnKeyType isEqualToString:@"google"]) {
            return UIReturnKeyGoogle;
         } else if([returnKeyType isEqualToString:@"join"]) {
            return UIReturnKeyJoin;
         } else if([returnKeyType isEqualToString:@"next"]) {
            return UIReturnKeyNext;
         } else if([returnKeyType isEqualToString:@"route"]) {
            return UIReturnKeyRoute;
         } else if([returnKeyType isEqualToString:@"search"]) {
            return UIReturnKeySearch;
         } else if([returnKeyType isEqualToString:@"send"]) {
            return UIReturnKeySend;
         } else if([returnKeyType isEqualToString:@"yahoo"]) {
            return UIReturnKeyYahoo;
         } else if([returnKeyType isEqualToString:@"done"]) {
            return UIReturnKeyDone;
         } else if([returnKeyType isEqualToString:@"emergencycall"]) {
            return UIReturnKeyEmergencyCall;
         }
         return UIReturnKeyDefault;
       });
    for (NSString* classString in @[@"UIWebBrowserView", @"UITextInputTraits"]) {
        Class c = NSClassFromString(classString);
       // Method m = class_getInstanceMethod(c, @selector(keyboardAppearance));
      Method m = class_getInstanceMethod(c, @selector(returnKeyType));
        if (m != NULL) {
            method_setImplementation(m, darkImp);
        } else {
          //  class_addMethod(c, @selector(keyboardAppearance), darkImp, "l@:");
           class_addMethod(c, @selector(returnKeyType), darkImp, "l@:");
        }
    }*/
    //}
  // [self returnKeyType];
  // setting = @"returnKeyType";
   // if ([self settingForKey:setting]) {
  // if([echo isEqualToString:@"returnKeyType"]) {
  /*      IMP darkImp = imp_implementationWithBlock(^(id _s) {
         return UIReturnKeyDefault;
       });
    for (NSString* classString in @[@"UIWebBrowserView", @"UITextInputTraits"]) {
        Class c = NSClassFromString(classString);
       // Method m = class_getInstanceMethod(c, @selector(keyboardAppearance));
      Method m = class_getInstanceMethod(c, @selector(returnKeyType));
        if (m != NULL) {
            method_setImplementation(m, darkImp);
        } else {
          //  class_addMethod(c, @selector(keyboardAppearance), darkImp, "l@:");
           class_addMethod(c, @selector(returnKeyType), darkImp, "l@:");
        }
    }*/
    //}
 
 /*    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate *currentDate = [NSDate date];
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setYear:3];
    NSDate *maxDate = [calendar dateByAddingComponents:comps toDate:currentDate options:0];
    [comps setYear:-3];
    NSDate *minDate = [calendar dateByAddingComponents:comps toDate:currentDate options:0];
    
   UIDatePicker *datePicker = [[UIDatePicker alloc]init];
 
    [datePicker setMaximumDate:maxDate];
    [datePicker setMinimumDate:minDate];
    */
 
/* NSDateComponents *dateDelta = [[NSDateComponents alloc] init];
[dateDelta setDay:0];
[dateDelta setHour:1];
[dateDelta setMinute:30];
NSDate *maximumDate = [calendar dateByAddingComponents:dateDelta toDate:currentDate options:0];*/
//[self.datePicker setMaximumDate:maximumDate];
/* 
  NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate *currentDate = [NSDate date];
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setYear:3];
    NSDate *maxDate = [calendar dateByAddingComponents:comps toDate:currentDate options:0];
    [comps setYear:-3];
    NSDate *minDate = [calendar dateByAddingComponents:comps toDate:currentDate options:0];
    
 
   IMP darkImp = imp_implementationWithBlock(^(id _s) {
         return currentDate;
   });
    for (NSString* classString in @[@"UIWebBrowserView", @"UITextInputTraits"]) {
        Class c = NSClassFromString(classString);
       // Method m = class_getInstanceMethod(c, @selector(keyboardAppearance));
      Method m = class_getInstanceMethod(c, @selector(maximumDate));
        if (m != NULL) {
            method_setImplementation(m, darkImp);
        } else {
          //  class_addMethod(c, @selector(keyboardAppearance), darkImp, "l@:");
           class_addMethod(c, @selector(maximumDate), darkImp, "l@:");
        }
    }
 */
   // [UIDatePicker setMaximumDate:maxDate];
   // [UIDatePicker setMinimumDate:minDate];
 
  // [datePicker setMaximumDate:maxDate];
  // [datePicker setMinimumDate:minDate];
 
 
}


- (void)_pickerViewWillBeShown:(NSNotification*)aNotification {
    [self performSelector:@selector(_resetPickerViewBackgroundAfterDelay) withObject:nil afterDelay:0];
}

-(void)_resetPickerViewBackgroundAfterDelay
{
    //UIPickerView *pickerView = nil;
    UIDatePicker *pickerView = nil;
    for (UIWindow *uiWindow in [[UIApplication sharedApplication] windows]) {
        for (UIView *uiView in [uiWindow subviews]) {
          NSLog(@"%@", uiView);
        //   if ([uiView isKindOfClass:NSClassFromString(@"UIDatePicker")] ){
        // if ([uiView isKindOfClass:[UIDatePicker class]] ){
              pickerView = [self _findPickerView:uiView];
          // }
        }
    }

    if (pickerView){
        NSDate *now = [NSDate date];
        NSCalendar *calendar = [[NSCalendar alloc]    initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:now];
        //set for today at 8 am
        [components setHour:8];
        NSDate *todayAtTime = [calendar dateFromComponents:components];
     
       [components setYear:[components year] - 100];
        NSDate *prevYears = [calendar dateFromComponents:components];
        //set max at now + 60 days
      //  NSDate *futureDate = [NSDate dateWithTimeIntervalSinceNow:60 * 60 * 24 * 60];
        //  NSDate *futureDate = [NSDate dateWithTimeIntervalSinceNow:60 * 60 * 24 * 36500];
         NSDate *futureDate = [now dateByAddingTimeInterval:60 * 60 * 24 * 100 * 365];
       // NSDate *prevDate = [now dateByAddingTimeInterval:60 * 60 * 24 * -13 * 365];
        
        [components setYear:[components year] + 86];
        NSDate *hundredYearsAgo = [calendar dateFromComponents:components];
     
        //[self.downArrow setHidden:true];
        //[pickerView.superview setClearButtonMode:@true];
//        [pickerView setBackgroundColor:[UIColor greenColor]];
        [pickerView.superview setValue:@"15" forKey:@"minuteInterval"];
        [pickerView.superview setValue:hundredYearsAgo forKey:@"maximumDate"];
        [pickerView.superview setValue:prevYears forKey:@"minimumDate"];
     
    
     
       /* UIToolbar *toolBar= [[UIToolbar alloc] initWithFrame:CGRectMake(0,0,320,44)];
        [toolBar setBarStyle:UIBarStyleBlackOpaque];
        UIBarButtonItem *barButtonDone = [[UIBarButtonItem alloc] initWithTitle:@"Done" 
        style:UIBarButtonItemStyleBordered target:self action:@selector(changeDateFromLabel:)];
        toolBar.items = @[barButtonDone];
       barButtonDone.tintColor=[UIColor blackColor];
       [pickerView addSubview:toolBar];*/
   /*  
     UIToolbar* keyboardToolbar = [[UIToolbar alloc] init];
[keyboardToolbar sizeToFit];
UIBarButtonItem *flexBarButton = [[UIBarButtonItem alloc]
                                  initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                  target:nil action:nil];
UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc]
                                  initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                  target:self action:@selector(yourTextViewDoneButtonPressed)];
keyboardToolbar.items = @[flexBarButton, doneBarButton];
      [pickerView addSubview:keyboardToolbar];
     */
     
    }
}

-(UIPickerView *) _findPickerView:(UIView *)uiView
{
       //if ([uiView isKindOfClass:[UIPickerView class]] ){
        if ([uiView isKindOfClass:objc_getClass("_UIDatePickerView")] || [uiView isKindOfClass:objc_getClass("UIDatePickerView")]) {
           // return (UIDatePicker*) uiView;
           // [(UITextField *)uiView setClearButtonMode:UITextFieldViewModeNever];
           // [(UIPickerView *)uiView setClearButtonMode:UITextFieldViewModeNever];
         
        // for (UIView *sub in uiView) {
              //[self hideKeyboardShortcutBar:sub];
         /*     if ([NSStringFromClass([uiView class]) isEqualToString:@"UIWebBrowserView"]) {
                  Method method = class_getInstanceMethod(uiView.class, @selector(inputAccessoryView));
                  IMP newImp = imp_implementationWithBlock(^(id _s) {
                      if ([uiView respondsToSelector:@selector(inputAssistantItem)]) {
                          UITextInputAssistantItem *inputAssistantItem = [uiView inputAssistantItem];
                          inputAssistantItem.leadingBarButtonGroups = @[];
                          inputAssistantItem.trailingBarButtonGroups = @[];
                      }
                      return nil;
                  });
                  method_setImplementation(method, newImp);
              }*/
        //  }
         
         
            return (UIPickerView*) uiView;
        }
 
      // if ([uiView isKindOfClass:NSClassFromString(@"UIDatePicker")] ){
      /* if ([uiView isKindOfClass:[UIDatePicker class]] ){
            return (UIDatePicker*) uiView;
       }*/

        if ([uiView subviews].count > 0) {
            for (UIView *subview in [uiView subviews]){
                UIPickerView* view = [self _findPickerView:subview];
                if (view)
                    return view;
            }
        }
        return nil;
}
#pragma mark HideFormAccessoryBar

static IMP UIOriginalImp;
static IMP WKOriginalImp;

- (void)setHideFormAccessoryBar:(BOOL)hideFormAccessoryBar
{
    if (hideFormAccessoryBar == _hideFormAccessoryBar) {
        return;
    }

    NSString* UIClassString = [@[@"UI", @"Web", @"Browser", @"View"] componentsJoinedByString:@""];
    NSString* WKClassString = [@[@"WK", @"Content", @"View"] componentsJoinedByString:@""];

    Method UIMethod = class_getInstanceMethod(NSClassFromString(UIClassString), @selector(inputAccessoryView));
    Method WKMethod = class_getInstanceMethod(NSClassFromString(WKClassString), @selector(inputAccessoryView));

    if (hideFormAccessoryBar) {
        UIOriginalImp = method_getImplementation(UIMethod);
        WKOriginalImp = method_getImplementation(WKMethod);

        IMP newImp = imp_implementationWithBlock(^(id _s) {
            return nil;
        });

        method_setImplementation(UIMethod, newImp);
        method_setImplementation(WKMethod, newImp);
    } else {
        method_setImplementation(UIMethod, UIOriginalImp);
        method_setImplementation(WKMethod, WKOriginalImp);
    }

    _hideFormAccessoryBar = hideFormAccessoryBar;
}

#pragma mark KeyboardShrinksView

- (void)setShrinkView:(BOOL)shrinkView
{
    // When the keyboard shows, WKWebView shrinks window.innerHeight. This isn't helpful when we are already shrinking the frame
    // They removed this behavior is iOS 10, but for 8 and 9 we need to prevent the webview from listening on keyboard events
    // Even if you later set shrinkView to false, the observers will not be added back
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    if ([self.webView isKindOfClass:NSClassFromString(@"WKWebView")]
        && ![[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 10, .minorVersion = 0, .patchVersion = 0 }]) {
        [nc removeObserver:self.webView name:UIKeyboardWillHideNotification object:nil];
        [nc removeObserver:self.webView name:UIKeyboardWillShowNotification object:nil];
        [nc removeObserver:self.webView name:UIKeyboardWillChangeFrameNotification object:nil];
        [nc removeObserver:self.webView name:UIKeyboardDidChangeFrameNotification object:nil];
    }
    _shrinkView = shrinkView;
}

- (void)shrinkViewKeyboardWillChangeFrame:(NSNotification*)notif
{
    // No-op on iOS 7.0.  It already resizes webview by default, and this plugin is causing layout issues
    // with fixed position elements.  We possibly should attempt to implement shrinkview = false on iOS7.0.
    // iOS 7.1+ behave the same way as iOS 6
    if (NSFoundationVersionNumber < NSFoundationVersionNumber_iOS_7_1 && NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        return;
    }

    // If the view is not visible, we should do nothing. E.g. if the inappbrowser is open.
    if (!(self.viewController.isViewLoaded && self.viewController.view.window)) {
        return;
    }

    self.webView.scrollView.scrollEnabled = YES;

    CGRect screen = [[UIScreen mainScreen] bounds];
    //CGRect screen = [[[UIApplication sharedApplication] keyWindow] frame];
    CGRect statusBar = [[UIApplication sharedApplication] statusBarFrame];
    CGRect keyboard = ((NSValue*)notif.userInfo[@"UIKeyboardFrameEndUserInfoKey"]).CGRectValue;

    // Work within the webview's coordinate system
    keyboard = [self.webView convertRect:keyboard fromView:nil];
    statusBar = [self.webView convertRect:statusBar fromView:nil];
    screen = [self.webView convertRect:screen fromView:nil];

    // if the webview is below the status bar, offset and shrink its frame
    if ([self settingForKey:@"StatusBarOverlaysWebView"] != nil && ![[self settingForKey:@"StatusBarOverlaysWebView"] boolValue]) {
        CGRect full, remainder;
        CGRectDivide(screen, &remainder, &full, statusBar.size.height, CGRectMinYEdge);
        screen = full;
    }

    // Get the intersection of the keyboard and screen and move the webview above it
    // Note: we check for _shrinkView at this point instead of the beginning of the method to handle
    // the case where the user disabled shrinkView while the keyboard is showing.
    // The webview should always be able to return to full size
    CGRect keyboardIntersection = CGRectIntersection(screen, keyboard);
    if (CGRectContainsRect(screen, keyboardIntersection) && !CGRectIsEmpty(keyboardIntersection) && _shrinkView && self.keyboardIsVisible) {
        screen.size.height -= keyboardIntersection.size.height;
        self.webView.scrollView.scrollEnabled = !self.disableScrollingInShrinkView;
    }

    // A view's frame is in its superview's coordinate system so we need to convert again
    self.webView.frame = [self.webView.superview convertRect:screen fromView:self.webView];
    /*
    // I'm sure there's a better way...
    if (@available(iOS 12, *)) {
        CGSize revisedSize = CGSizeMake(self.webView.frame.size.width, self.webView.frame.size.height - keyboard.size.height);
        //CGSize revisedSize = CGSizeMake(self.webView.frame.size.width, self.webView.frame.size.height + keyboard.size.height);
        self.webView.scrollView.contentSize = revisedSize;
    }
    */
}


#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView*)scrollView
{
    if (_shrinkView && _keyboardIsVisible) {
        CGFloat maxY = scrollView.contentSize.height - scrollView.bounds.size.height;
        if (scrollView.bounds.origin.y > maxY) {
            scrollView.bounds = CGRectMake(scrollView.bounds.origin.x, maxY,
                                           scrollView.bounds.size.width, scrollView.bounds.size.height);
        }
    } 
}

#pragma mark Plugin interface

- (void)shrinkView:(CDVInvokedUrlCommand*)command
{
    id value = [command.arguments objectAtIndex:0];
    if (!([value isKindOfClass:[NSNumber class]])) {
        value = [NSNumber numberWithBool:NO];
    }

    self.shrinkView = [value boolValue];
}

- (void)disableScrollingInShrinkView:(CDVInvokedUrlCommand*)command
{
    id value = [command.arguments objectAtIndex:0];
    if (!([value isKindOfClass:[NSNumber class]])) {
        value = [NSNumber numberWithBool:NO];
    }

    self.disableScrollingInShrinkView = [value boolValue];
}

- (void)hideFormAccessoryBar:(CDVInvokedUrlCommand*)command
{
    id value = [command.arguments objectAtIndex:0];
    if (!([value isKindOfClass:[NSNumber class]])) {
        value = [NSNumber numberWithBool:NO];
    }

    self.hideFormAccessoryBar = [value boolValue];
}

- (void)hide:(CDVInvokedUrlCommand*)command
{
    [self.webView endEditing:YES];
}

#pragma mark dealloc

- (void)dealloc
{
    // since this is ARC, remove observers only
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];

    [nc removeObserver:_keyboardShowObserver];
    [nc removeObserver:_keyboardHideObserver];
    [nc removeObserver:_keyboardWillShowObserver];
    [nc removeObserver:_keyboardWillHideObserver];
    [nc removeObserver:_shrinkViewKeyboardWillChangeFrameObserver];
}

@end
