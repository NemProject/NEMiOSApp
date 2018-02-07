import UIKit

extension Double
{
    func format(maximumFractionDigits :Int = 6) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        numberFormatter.decimalSeparator = "."
        numberFormatter.groupingSeparator = " "
        numberFormatter.minimumFractionDigits = 0
        numberFormatter.maximumFractionDigits = maximumFractionDigits
        let finalNumber = numberFormatter.string(from: self as NSNumber)
        return finalNumber!
    }
}
