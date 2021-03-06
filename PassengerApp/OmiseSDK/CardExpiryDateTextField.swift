import Foundation
import UIKit


/// UITextField subclass used for entering card's expiry date.
/// `CardExpiryDatePicker` will be set as the default input view.
@objc public class CardExpiryDateTextField: OmiseTextField {
    private let maxCreditCardAge = 21
    private let expirationRx = { () -> NSRegularExpression in
        guard let rx = try? NSRegularExpression(pattern: "^(\\d{1,2})/(\\d{1,2})$", options: []) else {
            return NSRegularExpression()
        }
        
        return rx
    }()
    
    /// Currently selected month, `nil` if no month has been selected.
    public private(set) var selectedMonth: Int? = nil
    @objc(selectedMonth) public var __selectedMonth: Int {
        return selectedMonth ?? 0
    }
    
    /// Currently selected year, `nil` if no year has been selected.
    public private(set) var selectedYear: Int? = nil
    @objc(selectedYear) public var __selectedYear: Int {
        return selectedYear ?? 0
    }
    
    /// Boolean indicating wether current input is valid or not.
    public override var isValid: Bool {
        let now = Date()
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let thisMonth = calendar.component(.month, from: now)
        let thisYear = calendar.component(.year, from: now)
        guard let year = self.selectedYear, let month = self.selectedMonth else {
            return false
        }
        
        if (year == thisYear) {
            return thisMonth <= month
        } else {
            return thisYear < year
        }
    }
    
    override public init() {
        super.init(frame: CGRect.zero)
        setup()
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        placeholder = "MM/YY"
        let expiryDatePicker = CardExpiryDatePicker() // TODO: Use normal picker delegate.
        expiryDatePicker.onDateSelected = { [weak self] (month: Int, year: Int) in
            self?.text = String(format: "%02d/%d", month, year-2000)
        }
        inputView = expiryDatePicker
    }
    
    override func textDidChange() {
        super.textDidChange()
        
        let text = self.text ?? ""
        let range = NSRange(location: 0, length: text.characters.count)
        guard let match = expirationRx.firstMatch(in: text, options: [], range: range), match.numberOfRanges >= 3 else {
            selectedMonth = nil
            selectedYear = nil
            return
        }
        
        let monthText = textInRange(match.rangeAt(1))
        let yearText = textInRange(match.rangeAt(2))
        selectedMonth = Int(monthText)
        selectedYear = Int(yearText)?.advanced(by: 2000)
    }
    
    private func textInRange(_ range: NSRange) -> String {
        let text = self.text ?? ""
        let start = text.characters.index(text.startIndex, offsetBy: range.location)
        let end = text.characters.index(start, offsetBy: range.length)
        return text.substring(with: start..<end)
    }
}
