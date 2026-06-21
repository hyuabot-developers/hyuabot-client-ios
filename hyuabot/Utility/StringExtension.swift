extension String {
    func substring(from: Int, to: Int) -> String {
        guard from >= 0, from < count, to >= 0, to < count, to >= from else { return "" }
        let startIndex = self.index(self.startIndex, offsetBy: from)
        let endIndex = self.index(self.startIndex, offsetBy: to)
        return String(self[startIndex...endIndex])
    }
}
