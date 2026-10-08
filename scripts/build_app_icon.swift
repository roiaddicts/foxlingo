// Package the prepared transparent illustration on the app's exact brand color.
// Usage: swift scripts/build_app_icon.swift INPUT.png OUTPUT.png
import Foundation
import CoreGraphics
import ImageIO

guard CommandLine.arguments.count == 3 else {fatalError("Expected foreground PNG and output PNG paths")}
let input=URL(fileURLWithPath:CommandLine.arguments[1]),output=URL(fileURLWithPath:CommandLine.arguments[2])
guard let source=CGImageSourceCreateWithURL(input as CFURL,nil),let image=CGImageSourceCreateImageAtIndex(source,0,nil),
      let space=CGColorSpace(name:CGColorSpace.sRGB),
      let canvas=CGContext(data:nil,width:1024,height:1024,bitsPerComponent:8,bytesPerRow:4096,space:space,bitmapInfo:CGImageAlphaInfo.noneSkipLast.rawValue) else {fatalError("Could not load the icon foreground or create its canvas")}
canvas.setFillColor(CGColor(colorSpace:space,components:[0,45.0/255,86.0/255,1])!)
canvas.fill(CGRect(x:0,y:0,width:1024,height:1024))
canvas.interpolationQuality = .high
canvas.draw(image,in:CGRect(x:0,y:0,width:1024,height:1024))
guard let result=canvas.makeImage(),let destination=CGImageDestinationCreateWithURL(output as CFURL,"public.png" as CFString,1,nil) else {fatalError("Could not write the app icon")}
CGImageDestinationAddImage(destination,result,nil)
guard CGImageDestinationFinalize(destination) else {fatalError("App icon export failed")}
print("Compiled opaque 1024×1024 icon on #002D56")
