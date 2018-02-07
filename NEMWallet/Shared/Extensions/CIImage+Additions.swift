import UIKit

extension CIImage {
    
    /**
        Creates a UI image from a provided CI image.

        - Parameter image: The CI image that should get converted into a UI image.
        - Parameter scale: The scale of the new UI image.

        - Returns: The converted UI image.
     */
    func createNonInterpolatedUIImage(scale: CGFloat) -> UIImage {

        let cgImage: CGImage = CIContext(options: nil).createCGImage(self, from: self.extent)!

        UIGraphicsBeginImageContext(CGSize(width: self.extent.size.width * scale, height: self.extent.size.height * scale ))
        let context: CGContext = UIGraphicsGetCurrentContext()!

        context.interpolationQuality = CGInterpolationQuality.none
        context.draw(cgImage, in: context.boundingBoxOfClipPath)

        let scaledImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!

        UIGraphicsEndImageContext()

        return scaledImage
    }
}
