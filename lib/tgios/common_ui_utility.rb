
include SugarCube::CoreGraphics
module Tgios
  class CommonUIUtility
    def self.imageFromColor(color)

      rect=Rect(0,0,1,1)
      UIGraphicsBeginImageContext(rect.size)
      context=UIGraphicsGetCurrentContext()
      uicolor = color.is_a?(UIColor) ? color : color.uicolor
      CGContextSetFillColorWithColor(context, uicolor.CGColor)
      CGContextFillRect(context, rect)
      image=UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()
      image
    end

    def self.fix_orientation(image)
      if image.imageOrientation == UIImageOrientationUp
        image
      else
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.drawInRect([[0,0], image.size])
        normalized_image = UIImage.UIGraphicsGetImageFromCurrentImageContext
        UIGraphicsEndImageContext()
        normalized_image
      end
    end
  end
end