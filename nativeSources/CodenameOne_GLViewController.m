/*
 * Copyright (c) 2012, Codename One and/or its affiliates. All rights reserved.
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
 * This code is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 only, as
 * published by the Free Software Foundation.  Codename One designates this
 * particular file as subject to the "Classpath" exception as provided
 * by Oracle in the LICENSE file that accompanied this code.
 *
 * This code is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * version 2 for more details (a copy is included in the LICENSE file that
 * accompanied this code).
 *
 * You should have received a copy of the GNU General Public License version
 * 2 along with this work; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * Please contact Codename One through http://www.codenameone.com/ if you
 * need additional information or have any questions.
 */
#import <QuartzCore/QuartzCore.h>
#import "CodenameOne_GLViewController.h"
#import "EAGLView.h"
#import "ExecutableOp.h"
#import "FillRect.h"
#import "ClipRect.h"
#import "DrawLine.h"
#import "DrawRect.h"
#import "DrawString.h"
#import "DrawImage.h"
#import "TileImage.h"
#import "GLUIImage.h"
#import "ResetAffine.h"
#import "Scale.h"
#import "Rotate.h"
#import <AudioToolbox/AudioToolbox.h>
#import "DrawGradientTextureCache.h"
#import "DrawStringTextureCache.h"
#import <CoreLocation/CoreLocation.h>
//#include "com_codename1_impl_ios_IOSImplementation.h"
#import <MobileCoreServices/UTCoreTypes.h>
//#include "com_codename1_payment_Product.h"
#import "CodenameOne_GLAppDelegate.h"


//int lastWindowSize = -1;
extern void stringEdit(int finished, int cursorPos, NSString* text);

int nextPowerOf2(int val) {
    int i;
    for(i = 8 ; i <= val ; i *= 2);
    return i;
}

int displayWidth = -1;
int displayHeight = -1;
UIView *editingComponent;
int editCompoentX, editCompoentY, editCompoentW, editCompoentH;
BOOL firstTime = YES;
BOOL retinaBug;
float scaleValue = 1;

// 1 for portrait lock, and 2 for landscape lock
int orientationLock = 0;



NSAutoreleasePool *globalCodenameOnePool;
void initVMImpl() {
    // initialize an auto release pool for the CodenameOne main thread
	globalCodenameOnePool = [[NSAutoreleasePool alloc] init];
}

void deinitVMImpl() {
    [globalCodenameOnePool release];
}

extern void pointerPressed(int* x, int* y, int length);
extern void pointerDragged(int* x, int* y, int length);
extern void pointerReleased(int* x, int* y, int length);
extern void screenSizeChanged(int width, int height);

void pointerPressedC(int* x, int* y, int length) {
    //NSLog(@"pointerPressedC started");
    pointerPressed(x, y, length);
    //NSLog(@"pointerPressedC finished");
}

void pointerDraggedC(int* x, int* y, int length) {
    //NSLog(@"pointerDraggedC started");
    pointerDragged(x, y, length);
    //NSLog(@"pointerDraggedC finished");
}
void pointerReleasedC(int* x, int* y, int length) {
    //NSLog(@"pointerReleasedC started");
    pointerReleased(x, y, length);
    //NSLog(@"pointerReleasedC finished");
}
void screenSizeChangedC(int width, int height) {
    //NSLog(@"screenSizeChangedC started");
    screenSizeChanged(width, height);
    //NSLog(@"screenSizeChangedC finished");
}

void* Java_com_codename1_impl_ios_IOSImplementation_createImageImpl
(void* data, int dataLength, int* widthAndHeightReturnValue) {
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_createImageImpl started for dataLength %i", dataLength);
    NSData* nd = [NSData dataWithBytes:data length:dataLength];
    UIImage* img = [UIImage imageWithData:nd];
    widthAndHeightReturnValue[0] = (int)img.size.width;
    widthAndHeightReturnValue[1] = (int)img.size.height;
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_createImageImpl finished width %i, height %i", (int)widthAndHeightReturnValue[0], (int)widthAndHeightReturnValue[1]);
    
    return [[GLUIImage alloc] initWithImage:img];
}

void Java_com_codename1_impl_ios_IOSImplementation_setImageName(void* nativeImage, const char* name) {
    GLUIImage* img = (GLUIImage*)nativeImage;
    if(name != nil) {
        [img setName:[NSString stringWithUTF8String:name]];
    }
}

void Java_com_codename1_impl_ios_IOSImplementation_editStringAtImpl
(int x, int y, int w, int h, void* font, int isSingleLine, int rows, int maxSize,
 int constraint, const char* str, int len) {
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_editStringAtImpl");
    if(editingComponent != nil) {
        [editingComponent resignFirstResponder];
        [editingComponent removeFromSuperview];
        [editingComponent release];
        editingComponent = nil;
        repaintUI();
    }
    dispatch_sync(dispatch_get_main_queue(), ^{
        float scale = scaleValue;
        editCompoentX = x / scale;
        editCompoentY = y / scale;
        editCompoentW = w / scale;
        editCompoentH = h / scale;
        CGRect rect = CGRectMake(editCompoentX, editCompoentY, editCompoentW, editCompoentH);
        if(isSingleLine) {
            UITextField* utf = [[UITextField alloc] initWithFrame:rect];
            editingComponent = utf;
            
            // PASSWORD
            if((constraint & 0x10000) == 0x10000) {
                utf.secureTextEntry = YES;
            }
            
            // EMAILADDR
            int cccc = constraint & 0xff;
            if(cccc == 1) {
                utf.keyboardType = UIKeyboardTypeEmailAddress;
            } else {
                // NUMERIC
                if(cccc == 2) {
                    utf.keyboardType = UIKeyboardTypeNumberPad;
                } else {
                    // PHONENUMBER
                    if(cccc == 3) {
                        utf.keyboardType = UIKeyboardTypePhonePad;
                    } else {
                        // URL
                        if(cccc == 4) {
                            utf.keyboardType = UIKeyboardTypeURL;
                        } else {
                            // DECIMAL
                            if(cccc == 5) {
                                utf.keyboardType = UIKeyboardTypeDecimalPad;
                            }
                        }
                    }
                }
            }
            if(scale != 1) {
                float s = ((UIFont*)font).pointSize / scale;
                utf.font = [((UIFont*)font) fontWithSize:s];
            } else {
                utf.font = (UIFont*)font;
            }
            utf.text = [NSString stringWithUTF8String:str];
            utf.delegate = (EAGLView*)[CodenameOne_GLViewController instance].view;
            utf.backgroundColor = [UIColor whiteColor];
            utf.returnKeyType = UIReturnKeyDone;
            utf.borderStyle = UITextBorderStyleRoundedRect;
            [[NSNotificationCenter defaultCenter]
             addObserver:utf.delegate
             selector:@selector(textFieldDidChange)
             name:UITextFieldTextDidChangeNotification
             object:utf];
        } else {
            UITextView* utv = [[UITextView alloc] initWithFrame:rect];
            editingComponent = utv;
            if(scale != 1) {
                float s = ((UIFont*)font).pointSize / scale;
                utv.font = [((UIFont*)font) fontWithSize:s];
            } else {
                utv.font = (UIFont*)font;
            }
            utv.text = [NSString stringWithUTF8String:str];
            utv.delegate = (EAGLView*)[CodenameOne_GLViewController instance].view;
        }
        editingComponent.opaque = NO;
        [[CodenameOne_GLViewController instance].view addSubview:editingComponent];
        [editingComponent becomeFirstResponder];
        [[CodenameOne_GLViewController instance].view resignFirstResponder];
        [editingComponent setNeedsDisplay];
        
    });
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_editStringAtImpl finished");
}

int isIPad() {
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
}


#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

BOOL isRetinaBug() {
    return isIPad() && [[UIScreen mainScreen] scale] == 2 && SYSTEM_VERSION_LESS_THAN(@"6.0");
}

BOOL isRetina() {
    if([[UIScreen mainScreen] scale] == 2) {
        return !isRetinaBug();
    }
    return NO;
}


void* Java_com_codename1_impl_ios_IOSImplementation_createImageFromARGBImpl
(int* buffer, int width, int height) {
    size_t bufferLength = width * height * 4;
    size_t bitsPerComponent = 8;
    size_t bitsPerPixel = 32;
    size_t bytesPerRow = 4 * width;
    
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, bufferLength, NULL);
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    if(colorSpaceRef == NULL) {
        NSLog(@"Error allocating color space");
        CGDataProviderRelease(provider);
        return nil;
    }
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaFirst;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    CGImageRef iref = CGImageCreate(width,
                                    height,
                                    bitsPerComponent,
                                    bitsPerPixel,
                                    bytesPerRow,
                                    colorSpaceRef,
                                    bitmapInfo,
                                    provider,	// data provider
                                    NULL,	// decode
                                    NO,	// should interpolate
                                    renderingIntent);
    
    uint32_t* pixels = (uint32_t*)malloc(bufferLength);
    
    if(pixels == NULL) {
        NSLog(@"Error: Memory not allocated for bitmap");
        CGDataProviderRelease(provider);
        CGColorSpaceRelease(colorSpaceRef);
        CGImageRelease(iref);
        return nil;
    }
    memset(pixels, 0, bufferLength);
    
    CGContextRef context = CGBitmapContextCreate(pixels,
                                                 width,
                                                 height,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpaceRef,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    if(context == NULL) {
        NSLog(@"Error context not created");
        free(pixels);
        return NULL;
    }
    
    UIImage *image = nil;
    if(context) {
        
        CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), iref);
        
        CGImageRef imageRef = CGBitmapContextCreateImage(context);
        
        // Support both iPad 3.2 and iPhone 4 Retina displays with the correct scale
        if([UIImage respondsToSelector:@selector(imageWithCGImage:scale:orientation:)]) {
            float scale = [[UIScreen mainScreen] scale];
            image = [UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
        } else {
            image = [UIImage imageWithCGImage:imageRef];
        }
        
        CGImageRelease(imageRef);
        CGContextRelease(context);
    }
    
    CGColorSpaceRelease(colorSpaceRef);
    CGImageRelease(iref);
    CGDataProviderRelease(provider);
    
    if(pixels) {
        free(pixels);
    }
    
    return [[GLUIImage alloc] initWithImage:image];
}


void* Java_com_codename1_impl_ios_IOSImplementation_scaleImpl
(void* peer, int width, int height) {
    // NOT used
    //UIImage* img = (UIImage*)peer;
    return 0;
}

int maxVal(int a, int b) {
    if(a > b) {
        return a;
    }
    return b;
}

CGContextRef roundRect(int color, int alpha, int x, int y, int width, int height, int arcWidth, int arcHeight) {
    [UIColorFromRGB(color, alpha) set];
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect rrect = CGRectMake(x, y, width, height);
    CGFloat radius = MAX(arcWidth, arcHeight);
    CGFloat minx = CGRectGetMinX(rrect), midx = CGRectGetMidX(rrect), maxx = CGRectGetMaxX(rrect);
    CGFloat miny = CGRectGetMinY(rrect), midy = CGRectGetMidY(rrect), maxy = CGRectGetMaxY(rrect);
    CGContextMoveToPoint(context, minx, midy);
    CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
    CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
    CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
    CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
    CGContextClosePath(context);
    return context;
}

void Java_com_codename1_impl_ios_IOSImplementation_nativeDrawRoundRectMutableImpl
(int color, int alpha, int x, int y, int width, int height, int arcWidth, int arcHeight) {
    CGContextStrokePath(roundRect(color, alpha, x, y, width, height, arcWidth, arcHeight));
}

void Java_com_codename1_impl_ios_IOSImplementation_resetAffineGlobal() {
    ResetAffine* f = [[ResetAffine alloc] init];
    [CodenameOne_GLViewController upcoming:f];
    [f release];
}

void Java_com_codename1_impl_ios_IOSImplementation_scale(float x, float y) {
    Scale* f = [[Scale alloc] initWithArgs:x yy:y];
    [CodenameOne_GLViewController upcoming:f];
    [f release];
}

extern void Java_com_codename1_impl_ios_IOSImplementation_nativeDrawImageGlobalImpl
(void* peer, int alpha, int x, int y, int width, int height);


void Java_com_codename1_impl_ios_IOSImplementation_nativeDrawRoundRectGlobalImpl
(int color, int alpha, int x, int y, int width, int height, int arcWidth, int arcHeight) {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, 1.0);
    CGContextStrokePath(roundRect(color, alpha, 0, 0, width, height, arcWidth, arcHeight));
    UIImage* img = UIGraphicsGetImageFromCurrentImageContext();
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_finishDrawingOnImageImpl %i", ((int)img));
    UIGraphicsEndImageContext();
    
    GLUIImage* glu = [[GLUIImage alloc] initWithImage:img];
    Java_com_codename1_impl_ios_IOSImplementation_nativeDrawImageGlobalImpl(glu, 255, x, y, width, height);
    [glu release];
}


void Java_com_codename1_impl_ios_IOSImplementation_nativeFillRoundRectMutableImpl
(int color, int alpha, int x, int y, int width, int height, int arcWidth, int arcHeight) {
    CGContextFillPath(roundRect(color, alpha, x, y, width, height, arcWidth, arcHeight));
}

void Java_com_codename1_impl_ios_IOSImplementation_nativeFillRoundRectGlobalImpl
(int color, int alpha, int x, int y, int width, int height, int arcWidth, int arcHeight) {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, 1.0);
    CGContextFillPath(roundRect(color, alpha, 0, 0, width, height, arcWidth, arcHeight));
    UIImage* img = UIGraphicsGetImageFromCurrentImageContext();
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_finishDrawingOnImageImpl %i", ((int)img));
    UIGraphicsEndImageContext();
    
    GLUIImage* glu = [[GLUIImage alloc] initWithImage:img];
    Java_com_codename1_impl_ios_IOSImplementation_nativeDrawImageGlobalImpl(glu, 255, x, y, width, height);
    [glu release];
}

#define PI 3.14159265358979323846
CGContextRef drawArc(int color, int alpha, int x, int y, int width, int height, int startAngle, int angle) {
    [UIColorFromRGB(color, alpha) set];
    CGContextRef context = UIGraphicsGetCurrentContext();
    int radius = MIN(width, height) / 2;
    CGContextAddArc (context,
                     x + radius, y + radius,
                     radius,
                     startAngle * PI / 180,
                     (startAngle + angle) * PI / 180,
                     1);
    return context;
}

void Java_com_codename1_impl_ios_IOSImplementation_nativeDrawArcMutableImpl
(int color, int alpha, int x, int y, int width, int height, int startAngle, int angle) {
    CGContextFillPath(drawArc(color, alpha, x, y, width, height, startAngle, angle));
}

void Java_com_codename1_impl_ios_IOSImplementation_nativeFillArcMutableImpl
(int color, int alpha, int x, int y, int width, int height, int startAngle, int angle) {
    CGContextStrokePath(drawArc(color, alpha, x, y, width, height, startAngle, angle));
}

void Java_com_codename1_impl_ios_IOSImplementation_nativeDrawArcGlobalImpl
(int color, int alpha, int x, int y, int width, int height, int startAngle, int angle) {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, 1.0);
    Java_com_codename1_impl_ios_IOSImplementation_nativeDrawArcMutableImpl(color, alpha, 0, 0, width, height, startAngle, angle);
    UIImage* img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    GLUIImage* glu = [[GLUIImage alloc] initWithImage:img];
    Java_com_codename1_impl_ios_IOSImplementation_nativeDrawImageGlobalImpl(glu, 255, x, y, width, height);
    [glu release];
}

void Java_com_codename1_impl_ios_IOSImplementation_nativeFillArcGlobalImpl
(int color, int alpha, int x, int y, int width, int height, int startAngle, int angle) {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, 1.0);
    Java_com_codename1_impl_ios_IOSImplementation_nativeFillArcMutableImpl(color, alpha, 0, 0, width, height, startAngle, angle);
    UIImage* img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    GLUIImage* glu = [[GLUIImage alloc] initWithImage:img];
    Java_com_codename1_impl_ios_IOSImplementation_nativeDrawImageGlobalImpl(glu, 255, x, y, width, height);
    [glu release];
}


void Java_com_codename1_impl_ios_IOSImplementation_nativeDrawImageMutableImpl
(void* peer, int alpha, int x, int y, int width, int height) {
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_nativeDrawImageMutableImpl %i started at %i, %i", (int)peer, x, y);
    UIImage* i = [(GLUIImage*)peer getImage];
    [i drawInRect:CGRectMake(x, y, width, height)];
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_nativeDrawImageMutableImpl finished");
}

int Java_com_codename1_impl_ios_IOSImplementation_stringWidthNativeImpl
(void* peer, const char* str, int len) {
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_stringWidthNativeImpl started");
    if(len == 0 || str == NULL) {
        return 0;
    }
    UIFont* f = (UIFont*)peer;
	NSString* s = [NSString stringWithUTF8String:str];
    //NSLog(@"String is %@", s);
    //NSLog(@"Font is %i", (int)f);
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_stringWidthNativeImpl finished");
    return (int)[s sizeWithFont:f].width;
}


int Java_com_codename1_impl_ios_IOSImplementation_charWidthNativeImpl
(void* peer, int chr) {
    UIFont* f = (UIFont*)peer;
    return [[NSString stringWithCharacters:&chr length:1] sizeWithFont:f].width;
}


int Java_com_codename1_impl_ios_IOSImplementation_getFontHeightNativeImpl
(void* peer) {
    UIFont* f = (UIFont*)peer;
    return (int)[f lineHeight];
}

void vibrateDevice() {
    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
}

void* Java_com_codename1_impl_ios_IOSImplementation_createSystemFontImpl
(int face, int style, int size) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_createSystemFontImpl started");
    int pSize = 14;
    
    // size small
    if(size == 8) {
        pSize = 11;
    } else {
        // large
        if(size == 16) {
            pSize = 20;
        }
    }
    
    pSize *= scaleValue;
    
    UIFont* fnt;
    // bold
    if((style & 1) == 1) {
        fnt = [UIFont boldSystemFontOfSize:pSize];
    } else {
        // italic
        if((style & 2) == 2) {
            fnt = [UIFont italicSystemFontOfSize:pSize];
        } else {
            fnt = [UIFont systemFontOfSize:pSize];
        }
    }
    [fnt retain];
    [pool release];
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_createSystemFontImpl finished %i", (int)fnt);
    return fnt;
}


/*
 * Class:     com_codename1_impl_ios_IOSImplementation
 * Method:    getDisplayWidth
 * Signature: ()I
 */
int Java_com_codename1_impl_ios_IOSImplementation_getDisplayWidthImpl() {
    if(displayWidth <= 0) {
        displayWidth = [CodenameOne_GLViewController instance].view.bounds.size.width * scaleValue;
    }
    //NSLog(@"Display width %i", displayWidth);
    return displayWidth;
}

/*
 * Class:     com_codename1_impl_ios_IOSImplementation
 * Method:    getDisplayHeight
 * Signature: ()I
 */
int
Java_com_codename1_impl_ios_IOSImplementation_getDisplayHeightImpl() {
    if(displayHeight <= 0) {
        displayHeight = [CodenameOne_GLViewController instance].view.bounds.size.height * scaleValue;
    }
    return displayHeight;
}


void Java_com_codename1_impl_ios_IOSImplementation_flushBufferImpl
(void* peer, int x, int y, int width, int height) {
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_flushBufferImpl started");
    [[CodenameOne_GLViewController instance] flushBuffer:peer x:x y:y width:width height:height];
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_flushBufferImpl finished");
}


void Java_com_codename1_impl_ios_IOSImplementation_setNativeClippingMutableImpl
(int x, int y, int width, int height, int clipApplied) {
    CGContextRef context = UIGraphicsGetCurrentContext();
    //NSLog(@"Native mutable clipping applied %i on context %i x: %i y: %i width: %i height: %i", clipApplied, (int)context, x, y, width, height);
    //if(clipApplied) {
    CGContextRestoreGState(context);
    //}
    CGContextSaveGState(context);
    UIRectClip(CGRectMake(x, y, width, height));
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_setNativeClippingMutableImpl finished");
}

void Java_com_codename1_impl_ios_IOSImplementation_setNativeClippingGlobalImpl
(int x, int y, int width, int height, int clipApplied) {
    //    NSLog(@"Native global clipping applied: %i x: %i y: %i width: %i height: %i", clipApplied, x, y, width, height);
    ClipRect* f = [[ClipRect alloc] initWithArgs:x ypos:y w:width h:height f:clipApplied];
    [CodenameOne_GLViewController upcoming:f];
    [f release];
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_setNativeClippingGlobalImpl finished");
}

void Java_com_codename1_impl_ios_IOSImplementation_nativeDrawLineMutableImpl
(int color, int alpha, int x1, int y1, int x2, int y2) {
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_nativeDrawLineMutableImpl started");
    [UIColorFromRGB(color, alpha) set];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextMoveToPoint(context, x1, y1);
    CGContextAddLineToPoint(context, x2, y1);
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_nativeDrawLineMutableImpl finished");
}

void Java_com_codename1_impl_ios_IOSImplementation_nativeDrawLineGlobalImpl
(int color, int alpha, int x1, int y1, int x2, int y2) {
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_nativeDrawLineGlobalImpl started");
    DrawLine* f = [[DrawLine alloc] initWithArgs:color a:alpha xpos1:x1 ypos1:y1 xpos2:x2 ypos2:y2];
    [CodenameOne_GLViewController upcoming:f];
    [f release];
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_nativeDrawLineGlobalImpl finished");
}

void Java_com_codename1_impl_ios_IOSImplementation_nativeRotateGlobalImpl
(float angle, int x, int y) {
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_nativeDrawLineGlobalImpl started");
    Rotate* f = [[Rotate alloc] initWithArgs:angle xx:x yy:y];
    [CodenameOne_GLViewController upcoming:f];
    [f release];
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_nativeDrawLineGlobalImpl finished");
}

void Java_com_codename1_impl_ios_IOSImplementation_nativeFillRectMutableImpl
(int color, int alpha, int x, int y, int width, int height) {
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_nativeFillRectMutableImpl started");
    [UIColorFromRGB(color, alpha) set];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextFillRect(context, CGRectMake(x, y, width, height));
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_nativeFillRectMutableImpl finished");
}

void Java_com_codename1_impl_ios_IOSImplementation_nativeFillRectGlobalImpl
(int color, int alpha, int x, int y, int width, int height) {
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_nativeFillRectGlobalImpl started");
    FillRect* f = [[FillRect alloc] initWithArgs:color a:alpha xpos:x ypos:y w:width h:height];
    [CodenameOne_GLViewController upcoming:f];
    [f release];
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_nativeFillRectGlobalImpl finished");
}

void Java_com_codename1_impl_ios_IOSImplementation_nativeDrawRectMutableImpl
(int color, int alpha, int x, int y, int width, int height) {
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_nativeDrawRectMutableImpl started");
    [UIColorFromRGB(color, alpha) set];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextStrokeRect(context, CGRectMake(x, y, width, height));
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_nativeDrawRectMutableImpl finished");
}

void Java_com_codename1_impl_ios_IOSImplementation_nativeDrawRectGlobalImpl
(int color, int alpha, int x, int y, int width, int height) {
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_nativeDrawRectImpl started");
    DrawRect* f = [[DrawRect alloc] initWithArgs:color a:alpha xpos:x ypos:y w:width h:height];
    [CodenameOne_GLViewController upcoming:f];
    [f release];
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_nativeDrawRectImpl finished");
}

void Java_com_codename1_impl_ios_IOSImplementation_nativeDrawStringMutableImpl
(int color, int alpha, void* fontPeer, const char* str, int strLen, int x, int y) {
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_nativeDrawStringMutableImpl started");
    [[CodenameOne_GLViewController instance] drawString:color alpha:alpha font:(UIFont*)fontPeer text:str length:strLen x:x y:y];
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_nativeDrawStringMutableImpl finished");
}

void Java_com_codename1_impl_ios_IOSImplementation_nativeDrawStringGlobalImpl
(int color, int alpha, void* fontPeer, const char* str, int strLen, int x, int y) {
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_nativeDrawStringImpl started");
    DrawString* f = [[DrawString alloc] initWithArgs:color a:alpha xpos:x ypos:y s:[NSString stringWithUTF8String:str] f:(UIFont*)fontPeer];
    [CodenameOne_GLViewController upcoming:f];
    [f release];
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_nativeDrawStringImpl finished");
}

void* Java_com_codename1_impl_ios_IOSImplementation_createNativeMutableImageImpl
(int width, int height, int argb) {
    if((argb & 0xff000000) == 0) {
        return NULL;
    }
    //NSLog(@"createNativeMutableImageImpl");
    BOOL opaque = ((argb & 0xff000000) == 0xff000000);
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), opaque, 1.0);
    [UIColorFromARGB(argb) set];
    UIRectFill(CGRectMake(0, 0, width, height));
    UIImage* img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    //[img retain];
    //NSLog(@"createNativeMutableImageImpl finished %i ", (int)img);
    GLUIImage* gl = [[GLUIImage alloc] initWithImage:img];
    return gl;
}

void Java_com_codename1_impl_ios_IOSImplementation_startDrawingOnImageImpl
(int width, int height, void *peer) {
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_startDrawingOnImageImpl");
    UIImage* original = [(GLUIImage*)peer getImage];
    // TODO!!! Pass information on whether the image is opaque!
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), true, 1.0);
    if(original != NULL) {
        [original drawAtPoint:CGPointZero];
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    [CodenameOne_GLViewController instance].currentMutableImage = (GLUIImage*)peer;
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_startDrawingOnImageImpl finished");
}

void* Java_com_codename1_impl_ios_IOSImplementation_finishDrawingOnImageImpl() {
    UIImage* img = UIGraphicsGetImageFromCurrentImageContext();
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_finishDrawingOnImageImpl %i", ((int)img));
    UIGraphicsEndImageContext();
    GLUIImage *gl = [CodenameOne_GLViewController instance].currentMutableImage;
    [gl setImage:img];
    [CodenameOne_GLViewController instance].currentMutableImage = nil;
    return gl;
}

void Java_com_codename1_impl_ios_IOSImplementation_imageRgbToIntArrayImpl
(void* peer, int* arr, int x, int y, int width, int height) {
    if([CodenameOne_GLViewController instance].currentMutableImage == peer) {
        Java_com_codename1_impl_ios_IOSImplementation_finishDrawingOnImageImpl();
    }
    UIImage* img = [(GLUIImage*)peer getImage];
    CGColorSpaceRef coloSpaceRgb = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(arr, width, height, 8, width * 4,
                                                 coloSpaceRgb,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGRect r = CGRectMake(-x, -(img.size.height - y - height), img.size.width, img.size.height);
    CGImageRef cgImg = [img CGImage];
    CGContextDrawImage(context, r, cgImg);
    CGColorSpaceRelease(coloSpaceRgb);
    CGContextRelease(context);
}


void Java_com_codename1_impl_ios_IOSImplementation_nativeDrawImageGlobalImpl
(void* peer, int alpha, int x, int y, int width, int height) {
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_nativeDrawImageGlobalImpl %i started at %i, %i", (int)peer, x, y);
    if([CodenameOne_GLViewController instance].currentMutableImage == peer) {
        Java_com_codename1_impl_ios_IOSImplementation_finishDrawingOnImageImpl();
    }
    DrawImage* f = [[DrawImage alloc] initWithArgs:alpha xpos:x ypos:y i:(GLUIImage*)peer w:width h:height];
    [CodenameOne_GLViewController upcoming:f];
    [f release];
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_nativeDrawImageGlobalImpl finished");
}

void Java_com_codename1_impl_ios_IOSImplementation_nativeTileImageGlobalImpl
(void* peer, int alpha, int x, int y, int width, int height) {
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_nativeTileImageGlobalImpl %i started at %i, %i", (int)peer, x, y);
    if([CodenameOne_GLViewController instance].currentMutableImage == peer) {
        Java_com_codename1_impl_ios_IOSImplementation_finishDrawingOnImageImpl();
    }
    TileImage* f = [[TileImage alloc] initWithArgs:alpha xpos:x ypos:y i:(GLUIImage*)peer w:width h:height];
    [CodenameOne_GLViewController upcoming:f];
    [f release];
    //NSLog(@"Java_com_codename1_impl_ios_IOSImplementation_nativeTileImageGlobalImpl finished");
}

void Java_com_codename1_impl_ios_IOSImplementation_deleteNativePeerImpl(void* peer) {
    GLUIImage* original = (GLUIImage*)peer;
    //NSLog(@"deleteNativePeerImpl retainCount: %i", [original retainCount]);
    [original release];
}

void Java_com_codename1_impl_ios_IOSImplementation_deleteNativeFontPeerImpl(void* peer) {
    UIFont* original = (UIFont*)peer;
    //NSLog(@"deleteNativeFontPeerImpl retainCount: %i", [original retainCount]);
    [original release];
}

void loadResourceFile
(const char* name, int nameLen, const char* type, int typeLen, void* data) {
    NSLog(@"loadResourceFile started");
    NSString* path = [[NSBundle mainBundle] pathForResource:[NSString stringWithUTF8String:name] ofType:[NSString stringWithUTF8String:type]];
    NSData* iData = [NSData dataWithContentsOfFile:path];
    [iData getBytes:data];
    NSLog(@"loadResourceFile finished");
}

int getResourceSize(const char* name, int nameLen, const char* type, int typeLen) {
    NSString* nameNS = [NSString stringWithUTF8String:name];
    NSString* typeNS = [NSString stringWithUTF8String:type];
    NSLog(@"getResourceSize %@ %@ started", nameNS, typeNS);
    NSString* path = [[NSBundle mainBundle] pathForResource:nameNS ofType:typeNS];
    if(path == nil) {
        return -1;
    }
    NSData* iData = [NSData dataWithContentsOfFile:path];
    int size = [iData length];
    NSLog(@"getResourceSize %i finished", size);
    return size;
}


int isPainted() {
    if([[CodenameOne_GLViewController instance] isPaintFinished]) {
        return 1;
    }
    return 0;
}

// Uniform index.
enum {
    UNIFORM_TRANSLATE,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum {
    ATTRIB_VERTEX,
    ATTRIB_COLOR,
    NUM_ATTRIBUTES
};

@interface CodenameOne_GLViewController ()
@property (nonatomic, retain) EAGLContext *context;
@property (nonatomic, assign) CADisplayLink *displayLink;
- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
@end

@implementation CodenameOne_GLViewController

@synthesize context, displayLink, currentMutableImage, animating;
static CodenameOne_GLViewController *sharedSingleton;
+(BOOL)isDrawTextureSupported {
    return sharedSingleton->drawTextureSupported;
}

- (void)awakeFromNib
{
    retinaBug = isRetinaBug();
    if(retinaBug) {
        scaleValue = 1;
    } else {
        scaleValue = [UIScreen mainScreen].scale;
    }
    sharedSingleton = self;
    [self initVars];
    EAGLContext *aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    
    if (!aContext) {
        aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    }
    
    if (!aContext)
        NSLog(@"Failed to create ES context");
    else if (![EAGLContext setCurrentContext:aContext])
        NSLog(@"Failed to set ES context current");
    
	self.context = aContext;
	[aContext release];
	
    [(EAGLView *)self.view setContext:context];
    [(EAGLView *)self.view setFramebuffer];
    //self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    //self.view.autoresizesSubviews = YES;
    
    if ([context API] == kEAGLRenderingAPIOpenGLES2)
        [self loadShaders];
    
    animating = FALSE;
    animationFrameInterval = 1;
    self.displayLink = nil;
    
    const char* extensions = (const char*)glGetString(GL_EXTENSIONS);
    drawTextureSupported = strstr(extensions, "OES_draw_texture") != 0;
    //NSLog(@"Draw texture extension %i", (int)drawTextureSupported);
    
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:self.view.window];
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:self.view.window];
    
    UIImage *img = nil;
    if(isIPad()) {
        if(scaleValue > 1) {
            if(Java_com_codename1_impl_ios_IOSImplementation_getDisplayWidthImpl() >
               Java_com_codename1_impl_ios_IOSImplementation_getDisplayHeightImpl()) {
                img = [UIImage imageNamed:@"Default-Landscape@2x.png"];
            } else {
                img = [UIImage imageNamed:@"Default-Portrait@2x.png"];
            }
        } else {
            if(Java_com_codename1_impl_ios_IOSImplementation_getDisplayWidthImpl() >
               Java_com_codename1_impl_ios_IOSImplementation_getDisplayHeightImpl()) {
                NSString* str = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Default-Landscape.png"];
                NSData* iData = [NSData dataWithContentsOfFile:str];
                img = [[UIImage alloc] initWithData:iData];
            } else {
                NSString* str = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Default-Portrait.png"];
                NSData* iData = [NSData dataWithContentsOfFile:str];
                img = [[UIImage alloc] initWithData:iData];
            }
        }
    } else {
        /*if([UIScreen mainScreen].scale > 1) {
            if(Java_com_codename1_impl_ios_IOSImplementation_getDisplayHeightImpl() > 960) {
                img = [UIImage imageNamed:@"Default@2x.png"];
            } else {
                img = [UIImage imageNamed:@"Default@2x.png"];
            }
        } else {
            img = [UIImage imageNamed:@"Default.png"];
        }*/
        if(Java_com_codename1_impl_ios_IOSImplementation_getDisplayHeightImpl() > 960) {
            // workaround for stupid iphone 5 behavior where image named just DOESN'T WORK!
            img = [UIImage imageNamed:@"Default-568h@2x.png"];
        } else {
            img = [UIImage imageNamed:@"Default.png"];
        }
    }
    [self.view setMultipleTouchEnabled:YES];
    if(img != nil) {
        float scale = scaleValue;
        DrawImage* dr;
        GLUIImage* gl;
        /*if(isRetinaBug()) {
         CGImageRef imageRef = CGImageCreateWithImageInRect([img CGImage], CGRectMake(0, 20 * scale, img.size.width * 2, img.size.height * 2 - 20 * scale));
         img = [UIImage imageWithCGImage:imageRef];
         CGImageRelease(imageRef);
         
         gl = [[GLUIImage alloc] initWithImage:img];
         dr = [[DrawImage alloc] initWithArgs:255 xpos:0 ypos:0 i:gl w:img.size.width / 2 h:img.size.height / 2];
         } else {*/
        CGImageRef imageRef = CGImageCreateWithImageInRect([img CGImage], CGRectMake(0, 20 * scale, Java_com_codename1_impl_ios_IOSImplementation_getDisplayWidthImpl(), Java_com_codename1_impl_ios_IOSImplementation_getDisplayHeightImpl()));
        img = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
        
        gl = [[GLUIImage alloc] initWithImage:img];
        dr = [[DrawImage alloc] initWithArgs:255 xpos:0 ypos:0 i:gl w:img.size.width h:img.size.height];
        //}
        
        [(EAGLView *)self.view setFramebuffer];
        GLErrorLog;
        
        glScalef(1, -1, 1);
        GLErrorLog;
        glTranslatef(0, -Java_com_codename1_impl_ios_IOSImplementation_getDisplayHeightImpl(), 0);
        GLErrorLog;
        
        [dr execute];
        [gl release];
        
        glTranslatef(0, Java_com_codename1_impl_ios_IOSImplementation_getDisplayHeightImpl(), 0);
        GLErrorLog;
        
        glScalef(1, -1, 1);
        GLErrorLog;
        
        [(EAGLView *)self.view presentFramebuffer];
        GLErrorLog;
    }
}

- (void)keyboardWillHide:(NSNotification *)n
{
    keyboardIsShown = NO;
    if(!modifiedViewHeight) {
        return;
    }
    NSDictionary* userInfo = [n userInfo];
    
    // get the size of the keyboard
    NSValue* boundsValue = [userInfo objectForKey:UIKeyboardBoundsUserInfoKey];
    CGSize keyboardSize = [boundsValue CGRectValue].size;
    
    
    // resize the scrollview
    CGRect viewFrame = self.view.frame;
    // I'm also subtracting a constant kTabBarHeight because my UIScrollView was offset by the UITabBar so really only the portion of the keyboard that is leftover pass the UITabBar is obscuring my UIScrollView.
    
    if(displayHeight > displayWidth) {
        viewFrame.origin.y += keyboardSize.height;
    } else {
        viewFrame.origin.x -= keyboardSize.height;
    }
    /*float y = editingComponent.frame.origin.y;
     y += keyboardSize.height;
     editingComponent.frame = CGRectMake(editCompoentX, y, editCompoentW, editCompoentH);*/
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3];
    [self.view setFrame:viewFrame];
    [UIView commitAnimations];
}

- (void)keyboardWillShow:(NSNotification *)n
{
    // This is an ivar I'm using to ensure that we do not do the frame size adjustment on the UIScrollView if the keyboard is already shown.  This can happen if the user, after fixing editing a UITextField, scrolls the resized UIScrollView to another UITextField and attempts to edit the next UITextField.  If we were to resize the UIScrollView again, it would be disastrous.  NOTE: The keyboard notification will fire even when the keyboard is already shown.
    if (keyboardIsShown) {
        return;
    }
    NSDictionary* userInfo = [n userInfo];
    
    // get the size of the keyboard
    NSValue* boundsValue = [userInfo objectForKey:UIKeyboardBoundsUserInfoKey];
    CGSize keyboardSize = [boundsValue CGRectValue].size;
    
    // resize the noteView
    CGRect viewFrame = self.view.frame;
    // I'm also subtracting a constant kTabBarHeight because my UIScrollView was offset by the UITabBar so really only the portion of the keyboard that is leftover pass the UITabBar is obscuring my UIScrollView.
    
    if(editCompoentY + (editCompoentH / 2) < displayHeight / scaleValue - keyboardSize.height) {
        modifiedViewHeight = NO;
        return;
    }
    modifiedViewHeight = YES;
    
    if(displayHeight > displayWidth) {
        viewFrame.origin.y -= keyboardSize.height;
    } else {
        viewFrame.origin.x += keyboardSize.height;
    }
    
    /*float y = editingComponent.frame.origin.y;
     y -= keyboardSize.height;
     editingComponent.frame = CGRectMake(editCompoentX, y, editCompoentW, editCompoentH);*/
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3];
    [self.view setFrame:viewFrame];
    [UIView commitAnimations];
    
    keyboardIsShown = YES;
}


- (void)dealloc
{
    if (program) {
        glDeleteProgram(program);
        program = 0;
    }
    
    // Tear down context.
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
    
    [context release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    JNIEnv *env = [CodenameOne_GLAppDelegate jniEnv];
    jclass IOSImplementation = (*env)->FindClass(env, "com/codename1/impl/ios/IOSImplementation");
    jmethodID flushSoftRefMap = (*env)->GetStaticMethodID(env, IOSImplementation, "flushSoftRefMap", "()V");
    (*env)->CallStaticVoidMethod(env, IOSImplementation, flushSoftRefMap);
    
    //GC_gcollect_and_unmap();
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewWillAppear:(BOOL)animated
{
    [self startAnimation];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self stopAnimation];
    
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	
    if (program) {
        glDeleteProgram(program);
        program = 0;
    }
    
    // Tear down context.
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
	self.context = nil;
}

- (NSInteger)animationFrameInterval
{
    return animationFrameInterval;
}

- (void)setAnimationFrameInterval:(NSInteger)frameInterval
{
    if (frameInterval >= 1) {
        animationFrameInterval = frameInterval;
        
        if (animating) {
            [self stopAnimation];
            [self startAnimation];
        }
    }
}

- (void)startAnimation
{
    /*if (!animating) {
     CADisplayLink *aDisplayLink = [[UIScreen mainScreen] displayLinkWithTarget:self selector:@selector(drawScreen)];
     [aDisplayLink setFrameInterval:animationFrameInterval];
     [aDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
     self.displayLink = aDisplayLink;
     
     animating = TRUE;
     }*/
}

- (void)stopAnimation
{
    if (animating) {
        [self.displayLink invalidate];
        self.displayLink = nil;
        animating = FALSE;
    }
}

- (void)drawScreen {
    [self drawFrame:[CodenameOne_GLViewController instance].view.bounds];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    switch (orientationLock) {
        case 0:
            return YES;
            
        case 1:
            if(interfaceOrientation == UIInterfaceOrientationPortrait) {
                return YES;
            }
            return NO;
            
        default:
            if(interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
                return YES;
            }
    }
    return NO;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [(EAGLView *)self.view updateFrameBufferSize:(int)self.view.bounds.size.width h:(int)self.view.bounds.size.height];
    displayWidth = (int)self.view.bounds.size.width * scaleValue;
    displayHeight = (int)self.view.bounds.size.height * scaleValue;
    screenSizeChanged(displayWidth, displayHeight);
}

//static UIImage *img = nil;
//static GLUIImage* glut = nil;

- (void)drawFrame:(CGRect)rect
{
    [(EAGLView *)self.view setFramebuffer];
    GLErrorLog;
    if(currentTarget != nil) {
        if([currentTarget count] > 0) {
            [ClipRect setDrawRect:rect];
            //NSLog(@"Clipping rect to: %i, %i, %i %i", (int)rect.origin.x, (int)rect.origin.y, (int)rect.size.width, (int)rect.size.height );
            glScalef(1, -1, 1);
            GLErrorLog;
            glTranslatef(0, -displayHeight, 0);
            GLErrorLog;
            
            /*if(((int)rect.size.width) != displayWidth || ((int)rect.size.height) != displayHeight) {
             glScissor(rect.origin.x, displayHeight - rect.origin.y - rect.size.height, rect.size.width, rect.size.height);
             glEnable(GL_SCISSOR_TEST);
             glClearColor(1, 1, 1, 1);
             glClear(GL_COLOR_BUFFER_BIT);
             }*/
            
            //NSLog(@"self.view.bounds.size.height %i displayHeight %i", (int)self.view.bounds.size.height, displayHeight);
            NSMutableArray* cp = nil;
            @synchronized([CodenameOne_GLViewController instance]) {
                cp = [currentTarget copy];
                [currentTarget removeAllObjects];
            }
            GLErrorLog;
            for(ExecutableOp* ex in cp) {
                [ex executeWithClipping];
                //[ex executeWithLog];
                GLErrorLog;
            }
            //NSLog(@"Total memory is: %i", [ExecutableOp get_free_memory]);
            [cp release];
            glTranslatef(0, displayHeight, 0);
            GLErrorLog;
            glScalef(1, -1, 1);
            GLErrorLog;
            
            [DrawGradientTextureCache flushDeleted];
            [DrawStringTextureCache flushDeleted];
            if(firstTime) {
                //GC_enable();
                firstTime = NO;
            }
        }
    }
    GLErrorLog;
    
    [(EAGLView *)self.view presentFramebuffer];
    GLErrorLog;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source)
    {
        NSLog(@"Failed to load vertex shader");
        return FALSE;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0)
    {
        glDeleteShader(*shader);
        return FALSE;
    }
    
    return TRUE;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0)
        return FALSE;
    
    return TRUE;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0)
        return FALSE;
    
    return TRUE;
}

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname])
    {
        NSLog(@"Failed to compile vertex shader");
        return FALSE;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname])
    {
        NSLog(@"Failed to compile fragment shader");
        return FALSE;
    }
    
    // Attach vertex shader to program.
    glAttachShader(program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(program, ATTRIB_COLOR, "color");
    
    // Link program.
    if (![self linkProgram:program])
    {
        NSLog(@"Failed to link program: %d", program);
        
        if (vertShader)
        {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader)
        {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (program)
        {
            glDeleteProgram(program);
            program = 0;
        }
        
        return FALSE;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_TRANSLATE] = glGetUniformLocation(program, "translate");
    
    // Release vertex and fragment shaders.
    if (vertShader)
        glDeleteShader(vertShader);
    if (fragShader)
        glDeleteShader(fragShader);
    
    return TRUE;
}


-(BOOL)isPaintFinished {
    return painted;
}

-(void)flushBuffer:(UIImage *)buff x:(int)x y:(int)y width:(int)width height:(int)height {
    /*if(editingComponent != nil) {
     return;
     }*/
    //currentBackBuffer = buff;
    __block CGRect rect = CGRectMake(x, y, width, height);
    painted = NO;
	//[self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:0 waitUntilDone:NO];
    dispatch_sync(dispatch_get_main_queue(), ^{
        @synchronized([CodenameOne_GLViewController instance]) {
            if([currentTarget count] > 0) {
                [currentTarget addObjectsFromArray:upcomingTarget];
                [upcomingTarget removeAllObjects];
            } else {
                NSMutableArray* tmp = currentTarget;
                currentTarget = upcomingTarget;
                upcomingTarget = tmp;
            }
            //[layerDelegate updateArray:currentTarget];
        }
        //[self setNeedsDisplayInRect:rect];
        [self drawFrame:rect];
    });
    /*int timeout = 5;
     while (!painted && timeout > 0) {
     sleep(5);
     timeout--;
     }*/
}

-(void)drawString:(int)color alpha:(int)alpha font:(UIFont*)font text:(const char*)text  length:(int)length x:(int)x y:(int)y {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    UIColor* col = UIColorFromRGB(color,alpha);
    [col set];
	NSString* str = [NSString stringWithUTF8String:text];
	[str drawAtPoint:CGPointMake(x, y) withFont:font];
    //NSLog(@"Drawing the string %@ at %i, %i", str, x, y);
	[pool release];
}


+ (void)initialize
{
    static BOOL initialized = NO;
    if(!initialized)
    {
        initialized = YES;
        //sharedSingleton = [[CodenameOne_GLViewController alloc] init];
        //[sharedSingleton initVars];
    }
}

-(void)initVars {
    currentTarget = [[NSMutableArray alloc] init];
    upcomingTarget = [[NSMutableArray alloc] init];
}

+(CodenameOne_GLViewController*)instance {
	return sharedSingleton;
}

+(void)upcoming:(ExecutableOp*)op {
    [sharedSingleton upcomingAdd:op];
}

-(void)upcomingAdd:(ExecutableOp*)op {
    @synchronized([CodenameOne_GLViewController instance]) {
        [upcomingTarget addObject:op];
    }
}

static BOOL skipNextTouch = NO;
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    UITouch* touch = [touches anyObject];
    int xArray[[touches count]];
    int yArray[[touches count]];
    CGPoint point = [touch locationInView:self.view];
    if([touches count] > 1) {
        NSArray *ts = [touches allObjects];
        for(int iter = 0 ; iter < [ts count] ; iter++) {
            UITouch* currentTouch = [ts objectAtIndex:iter];
            CGPoint currentPoint = [currentTouch locationInView:self.view];
            xArray[iter] = (int)currentPoint.x * scaleValue;
            yArray[iter] = (int)currentPoint.y * scaleValue;
        }
    } else {
        xArray[0] = (int)point.x * scaleValue;
        yArray[0] = (int)point.y * scaleValue;
    }
    if(editingComponent != nil) {
        if(!(editCompoentX <= point.x && editCompoentY <= point.y && editCompoentW + editCompoentX >= point.x &&
             editCompoentY + editCompoentH >= point.y)) {
            if([editingComponent isKindOfClass:[UITextView class]]) {
                UITextView* v = (UITextView*)editingComponent;
                stringEdit(YES, -1, v.text);
            } else {
                UITextField* v = (UITextView*)editingComponent;
                stringEdit(YES, -1, v.text);
            }
            [editingComponent resignFirstResponder];
            [editingComponent removeFromSuperview];
            [editingComponent release];
            editingComponent = nil;
            displayWidth = (int)self.view.bounds.size.width * scaleValue;
            displayHeight = (int)self.view.bounds.size.height * scaleValue;
            //screenSizeChanged(displayWidth, displayHeight);
            repaintUI();
            //skipNextTouch = YES;
            //return;
        }
    }
    pointerPressedC(xArray, yArray, [touches count]);
    [pool release];
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    if(skipNextTouch) {
        skipNextTouch = NO;
        return;
    }
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    UITouch* touch = [touches anyObject];
    int xArray[[touches count]];
    int yArray[[touches count]];
    CGPoint point = [touch locationInView:self.view];
    if([touches count] > 1) {
        NSArray *ts = [touches allObjects];
        for(int iter = 0 ; iter < [ts count] ; iter++) {
            UITouch* currentTouch = [ts objectAtIndex:iter];
            CGPoint currentPoint = [currentTouch locationInView:self.view];
            xArray[iter] = (int)currentPoint.x * scaleValue;
            yArray[iter] = (int)currentPoint.y * scaleValue;
        }
    } else {
        xArray[0] = (int)point.x * scaleValue;
        yArray[0] = (int)point.y * scaleValue;
    }
    pointerReleasedC(xArray, yArray, [touches count]);
    [pool release];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if(skipNextTouch) {
        skipNextTouch = NO;
        return;
    }
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    UITouch* touch = [touches anyObject];
    int xArray[[touches count]];
    int yArray[[touches count]];
    CGPoint point = [touch locationInView:self.view];
    if([touches count] > 1) {
        NSArray *ts = [touches allObjects];
        for(int iter = 0 ; iter < [ts count] ; iter++) {
            UITouch* currentTouch = [ts objectAtIndex:iter];
            CGPoint currentPoint = [currentTouch locationInView:self.view];
            xArray[iter] = (int)currentPoint.x * scaleValue;
            yArray[iter] = (int)currentPoint.y * scaleValue;
        }
    } else {
        xArray[0] = (int)point.x * scaleValue;
        yArray[0] = (int)point.y * scaleValue;
    }
    pointerReleasedC(xArray, yArray, [touches count]);
    [pool release];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if(skipNextTouch) {
        return;
    }
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    UITouch* touch = [touches anyObject];
    int xArray[[touches count]];
    int yArray[[touches count]];
    CGPoint point = [touch locationInView:self.view];
    if([touches count] > 1) {
        NSArray *ts = [touches allObjects];
        for(int iter = 0 ; iter < [ts count] ; iter++) {
            UITouch* currentTouch = [ts objectAtIndex:iter];
            CGPoint currentPoint = [currentTouch locationInView:self.view];
            xArray[iter] = (int)currentPoint.x * scaleValue;
            yArray[iter] = (int)currentPoint.y * scaleValue;
        }
    } else {
        xArray[0] = (int)point.x * scaleValue;
        yArray[0] = (int)point.y * scaleValue;
    }
    pointerDraggedC(xArray, yArray, [touches count]);
    [pool release];
}

- (void) locationManager:(CLLocationManager *)manager
     didUpdateToLocation:(CLLocation *)newLocation
            fromLocation:(CLLocation *)oldLocation{
    JNIEnv *env = [CodenameOne_GLAppDelegate jniEnv];
    jclass IOSImplementation = (*env)->FindClass(env, "com/codename1/impl/ios/IOSImplementation");
    jmethodID locationUpdate = (*env)->GetStaticMethodID(env, IOSImplementation, "locationUpdate", "()V");
    (*env)->CallStaticVoidMethod(env, IOSImplementation, locationUpdate);
    //com_codename1_impl_ios_IOSImplementation_locationUpdate__();
}


extern UIPopoverController* popoverController;
extern int popoverSupported();

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    //[self dismissModalViewControllerAnimated:YES];
    
    JNIEnv* env = [CodenameOne_GLAppDelegate jniEnv];
    jclass IOSImplementation = (*env)->FindClass(env, "com/codename1/impl/ios/IOSImplementation");
    jmethodID capturePictureResult = (*env)->GetStaticMethodID(env, IOSImplementation, "capturePictureResult", "(Ljava/lang/String;)V");
    (*env)->CallStaticVoidMethod(env, IOSImplementation, capturePictureResult, NULL);
    
    [picker dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary*)info {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString* mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
    JNIEnv *env = [CodenameOne_GLAppDelegate jniEnv];
    jclass IOSImplementation = (*env)->FindClass(env, "com/codename1/impl/ios/IOSImplementation");

	if ([mediaType isEqualToString:@"public.image"]) {
		// get the image
		UIImage* image = [info objectForKey:UIImagePickerControllerOriginalImage];
        
        NSData* data = UIImageJPEGRepresentation(image, 90 / 100.0f);
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:@"temp_image.jpg"];
        [data writeToFile:path atomically:YES];
        jmethodID capturePictureResult = (*env)->GetStaticMethodID(env, IOSImplementation, "capturePictureResult", "(Ljava/lang/String;)V");
        
        (*env)->CallStaticVoidMethod(env, IOSImplementation, capturePictureResult,fromNSString(env, path));
        
        
	} else {
        // was movie type
        NSString *moviePath = [[info objectForKey: UIImagePickerControllerMediaURL] absoluteString];
        
        jmethodID captureMovieResult = (*env)->GetStaticMethodID(env, IOSImplementation, "captureMovieResult", "(Ljava/lang/String;)V");
        
        (*env)->CallStaticVoidMethod(env, IOSImplementation, captureMovieResult,fromNSString(env, moviePath));
        
    }
	
	if(popoverSupported() && popoverController != nil) {
		[popoverController dismissPopoverAnimated:YES];
        popoverController.delegate = nil;
        popoverController = nil;
	} else {
		[picker dismissModalViewControllerAnimated:YES];
	}
    
	picker.delegate = nil;
    picker = nil;
    [pool release];
}

-(void) mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	[self dismissModalViewControllerAnimated:YES];
}

-(void) messageComposeViewController:(MFMessageComposeViewController*)controller didFinishWithResult:(MessageComposeResult)result {
	[self dismissModalViewControllerAnimated:YES];
}

extern jobjectArray productsArrayPending;

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    if(productsArrayPending != nil) {
        JNIEnv *env = [CodenameOne_GLAppDelegate jniEnv];
        //org_xmlvm_runtime_XMLVMArray* pArray = productsArrayPending;
        //JAVA_ARRAY_OBJECT* data = (JAVA_ARRAY_OBJECT*)pArray->fields.org_xmlvm_runtime_XMLVMArray.array_;
        NSArray* arr = response.products;
        int count = arr.count;
        
        jclass Product = (*env)->FindClass(env, "com/codename1/payment/Product");
        jmethodID setSku = (*env)->GetMethodID(env, Product, "setSku", "(Ljava/lang/String)V");
        jmethodID setLocalizedPrice = (*env)->GetMethodID(env, Product, "setLocalizedPrice", "(Ljava/lang/String)V");
        jmethodID setDescription = (*env)->GetMethodID(env, Product, "setDescription", "(Ljava/lang/String)V");
        jmethodID setDisplayName = (*env)->GetMethodID(env, Product, "setDisplayName", "(Ljava/lang/String)V");
        
        for(int iter = 0 ; iter < count ; iter++) {
            SKProduct* prod = [arr objectAtIndex:iter];
            jobject thisProd = (*env)->GetObjectArrayElement(env, productsArrayPending, iter);
            NSString* sku = [prod productIdentifier];
            
            (*env)->CallObjectMethod(env, thisProd, setSku, (*env)->NewStringUTF(env, sku.UTF8String));
            NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
            [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
            [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
            [numberFormatter setLocale:prod.priceLocale];
            NSString *formattedString = [numberFormatter stringFromNumber:prod.price];
            
            (*env)->CallObjectMethod(env, thisProd, setLocalizedPrice, (*env)->NewStringUTF(env, formattedString.UTF8String));
            
            
            (*env)->CallObjectMethod(env, thisProd, setDescription, (*env)->NewStringUTF(env, [prod localizedDescription].UTF8String));
            
            (*env)->CallObjectMethod(env, thisProd, setDisplayName, (*env)->NewStringUTF(env, [prod localizedTitle].UTF8String));
        }
        
        (*env)->DeleteGlobalRef(env, productsArrayPending);
    }
    
    productsArrayPending = nil;
    [pool release];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    JNIEnv *env = [CodenameOne_GLAppDelegate jniEnv];
    jclass IOSImplementation = (*env)->FindClass(env, "com/codename1/impl/ios/IOSImplementation");
    jmethodID itemPurchased = (*env)->GetStaticMethodID(env, IOSImplementation, "itemPurchased", "(Ljava/lang/String;)V");
    jmethodID itemPurchaseError = (*env)->GetStaticMethodID(env, IOSImplementation, "itemPurchaseError", "(Ljava/lang/String;Ljava/lang/String;)V");
    
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                (*env)->CallStaticVoidMethod(env, IOSImplementation, itemPurchased, fromNSString(env, transaction.payment.productIdentifier));
               
                break;
            case SKPaymentTransactionStateFailed:
                if (transaction.error.code != SKErrorPaymentCancelled) {
                    (*env)->CallStaticVoidMethod(env, IOSImplementation, itemPurchaseError, fromNSString(env, transaction.payment.productIdentifier), NULL );
                    
                }
                break;
            case SKPaymentTransactionStateRestored:                
                break;
            default:
                break;
        }
        [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    }
}

@end
