//
//  UITableView+GKKeyNavigationSupport.m
//  GKKeySupportTableView
//
//  The MIT License (MIT)
//
//    Copyright (c) 2013, Georg Kitz @gekitz
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in
//    all copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//    THE SOFTWARE.

#import "UITableView+GKKeyNavigationSupport.h"
#import <objc/runtime.h>
#import <objc/message.h>

static NSString *const kGKAddKeySupport = @"gk_addKeySupport";
static NSString *const kGKKeyboardNotification = @"PSPDFKeyboardEventNotification";
static NSString *const kGKKeyboardNotificationKeyCode = @"PSPDFKeyboardEventNotification.KeyCode";
static NSString *const kGKKeyboardNotificationEventFlags = @"PSPDFKeyboardEventNotification.EventFlags";

static NSUInteger kGKKeyboardDirectionDown = 81;
static NSUInteger kGKKeyboardDirectionUp = 82;
static NSUInteger kGKKeyboardEnter = 40;


@implementation UITableView (GKKeyNavigationSupport)

# pragma mark -
# pragma mark Properties

- (void)setGk_addKeyboardSupport:(BOOL)addKeyboardSupport {
    objc_setAssociatedObject(self, (__bridge const void *)(kGKAddKeySupport), @(addKeyboardSupport), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (addKeyboardSupport) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gk_keyboardEventNotification:) name:kGKKeyboardNotification object:nil];
    }
}

- (BOOL)gk_addKeyboardSupport {
    return [objc_getAssociatedObject(self, (__bridge const void *)(kGKAddKeySupport)) boolValue];
}

# pragma mark -
# pragma mark Notifications

- (void)gk_keyboardEventNotification:(NSNotification *)notf {
   
    NSInteger keyCode = [notf.userInfo[kGKKeyboardNotificationKeyCode] integerValue];
    
    if (keyCode == kGKKeyboardDirectionDown || keyCode == kGKKeyboardDirectionUp) {
        
        BOOL isUpDirection = keyCode == kGKKeyboardDirectionUp;
        [self gk_selectItemDirectionUp:isUpDirection];
        
    } else if (keyCode == kGKKeyboardEnter) {
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
            [self.delegate tableView:self didSelectRowAtIndexPath:[self indexPathForSelectedRow]];
        }
    }
}

# pragma mark -
# pragma mark Private Methods

- (void)gk_selectItemDirectionUp:(BOOL)isUpDirection {
    

    if ([self indexPathForSelectedRow] == nil) {
        if ([self numberOfRowsInSection:0] > 0) {
            
            [self gk_selectNewRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        }
        return;
    }
    
    
    NSIndexPath *indexPath = [self indexPathForSelectedRow];
    NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow: isUpDirection ? indexPath.row - 1 : indexPath.row + 1 inSection:indexPath.section];
    
    if (newIndexPath.row < 0 || newIndexPath.row >= [self numberOfRowsInSection:0]) {
        newIndexPath = indexPath;
    }
    
    [self gk_selectNewRowAtIndexPath:newIndexPath];
}

- (void)gk_selectNewRowAtIndexPath:(NSIndexPath *)indexPath {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
    });
}

@end

# pragma mark -
# pragma mark Code borrowed from @steinpete's blog
// http://petersteinberger.com/blog/2013/adding-keyboard-shortcuts-to-uialertview/

#define GSEVENT_TYPE 2
#define GSEVENT_FLAGS 12
#define GSEVENTKEY_KEYCODE 15
#define GSEVENTKEY_KEYCODE_64_BIT 19
#define GSEVENT_TYPE_KEYUP 10

// http://nacho4d-nacho4d.blogspot.co.uk/2012/01/catching-keyboard-events-in-ios.html

void PSPDFReplaceMethod(Class c, SEL orig, SEL newSel, IMP impl);

__attribute__((constructor)) static void PSPDFKitAddKeyboardSupportForUIAlertView(void) {
    
    if (sizeof(NSUInteger) == 8) {
        kGKKeyboardDirectionDown = 31;
        kGKKeyboardDirectionUp = 30;
        kGKKeyboardEnter = 13;
    }
    
    @autoreleasepool {
        // Hook into sendEvent: to get keyboard events.
        SEL sendEventSEL = NSSelectorFromString(@"pspdf_sendEvent:");
        IMP sendEventIMP = imp_implementationWithBlock(^(id _self, UIEvent *event) {
            objc_msgSend(_self, sendEventSEL, event); // call original implementation.
            
            SEL gsEventSEL = NSSelectorFromString([NSString stringWithFormat:@"%@%@Event", @"_", @"gs"]);
            if ([event respondsToSelector:gsEventSEL]) {
                // Key events come in form of UIInternalEvents.
                // They contain a GSEvent object which contains a GSEventRecord among other things.
#       pragma clang diagnostic push
#       pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                void *eventVoid = (__bridge void*)[event performSelector:gsEventSEL];
#		pragma clang diagnostic pop
                NSInteger *eventMem = (NSInteger *)eventVoid;
                if (eventMem) {
                    if (eventMem[GSEVENT_TYPE] == GSEVENT_TYPE_KEYUP) {
                        
                        NSUInteger idx = sizeof(NSInteger) == 8 ? GSEVENTKEY_KEYCODE_64_BIT : GSEVENTKEY_KEYCODE;
                        
                        NSUInteger *keycode = (NSUInteger *)&(eventMem[idx]);
                        NSInteger eventFlags = eventMem[GSEVENT_FLAGS];
                        
                        NSDictionary *userInfo = @{kGKKeyboardNotificationKeyCode : @(*keycode), kGKKeyboardNotificationEventFlags : @(eventFlags)};
                        [[NSNotificationCenter defaultCenter] postNotificationName:kGKKeyboardNotification object:nil userInfo:userInfo];
                    }
                }
            }
        });
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        PSPDFReplaceMethod(UIApplication.class, @selector(handleKeyUIEvent:), sendEventSEL, sendEventIMP);
#		pragma clang diagnostic pop
    }
}

// http://www.mikeash.com/pyblog/friday-qa-2010-01-29-method-replacement-for-fun-and-profit.html
static void PSPDFSwizzleMethod(Class c, SEL orig, SEL new) {
    Method origMethod = class_getInstanceMethod(c, orig);
    Method newMethod = class_getInstanceMethod(c, new);
    if (class_addMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(c, new, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    }else {
        method_exchangeImplementations(origMethod, newMethod);
    }
}

void PSPDFReplaceMethod(Class c, SEL orig, SEL newSel, IMP impl) {
    Method method = class_getInstanceMethod(c, orig);
    if (!class_addMethod(c, newSel, impl, method_getTypeEncoding(method))) {
        NSLog(@"Failed to add method: %@ on %@", NSStringFromSelector(newSel), c);
    }else PSPDFSwizzleMethod(c, orig, newSel);
}