//
//  UIImage+AverageColor.m
//  Decktracker
//
//  Created by Jovit Royeca on 11/15/14.
//  Copyright (c) 2014 Jovito Royeca. All rights reserved.
//

#import "UIImage+AverageColor.h"

@implementation UIImage (AverageColor)

- (UIColor *) averageColor {
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char rgba[4];
    CGContextRef context = CGBitmapContextCreate(rgba, 1, 1, 8, 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGContextDrawImage(context, CGRectMake(0, 0, 1, 1), self.CGImage);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    if(rgba[3] > 0) {
        CGFloat alpha = ((CGFloat)rgba[3])/255.0;
        CGFloat multiplier = alpha/255.0;
        return [UIColor colorWithRed:((CGFloat)rgba[0])*multiplier
                               green:((CGFloat)rgba[1])*multiplier
                                blue:((CGFloat)rgba[2])*multiplier
                               alpha:alpha];
    }
    else {
        return [UIColor colorWithRed:((CGFloat)rgba[0])/255.0
                               green:((CGFloat)rgba[1])/255.0
                                blue:((CGFloat)rgba[2])/255.0
                               alpha:((CGFloat)rgba[3])/255.0];
    }
}

-(UIColor *) patternColor:(UIColor*) averageColor
{
    CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
    [averageColor getRed:&red green:&green blue:&blue alpha:&alpha];
    
    int threshold = 105;
    int bgDelta = ((red * 0.299) + (green * 0.587) + (blue * 0.114));
    
    return (255 - bgDelta < threshold) ? [UIColor blackColor] : [UIColor whiteColor];
}

-(UIColor*) inverseColor:(UIColor*) color
{
    CGFloat r,g,b,a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    return [UIColor colorWithRed:1.-r green:1.-g blue:1.-b alpha:a];
}

- (UIColor*) contrastColor:(UIColor*) color
{
    int d = 0;
    CGFloat r,g,b,a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    
    // Counting the perceptive luminance - human eye favors green color... 
    double luminance = 1 - ( 0.299 * r + 0.587 * g + 0.114 * b) / 255;

    if (luminance < 0.5)
       d = 0; // bright colors - black font
    else
       d = 255; // dark colors - white font

    return [UIColor colorWithRed:d green:d blue:d alpha:a];
}

@end
