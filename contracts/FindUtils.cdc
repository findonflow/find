pub contract FindUtils {

    pub fun containsChar(_ string: String, char: Character) : Bool {
        if var index = string.utf8.firstIndex(of: char.toString().utf8[0]) {
            return true
        }
        return false
    }

    pub fun contains(_ string: String, element: String) : Bool {
        if element.length == 0 {
            return true 
        }
        if var index = string.utf8.firstIndex(of: element.utf8[0]) {
            while index <= ( string.length - element.length) {
                if string[index] == element[0] && string.slice(from: index, upTo: index + element.length) == element {
                    return true
                }
                index = index + 1
            }
        }
        
        return false
    }

    pub fun hasSuffix(_ string: String, suffix: String) : Bool {
        if suffix.length > string.length {
            return false
        }
        return string.slice(from: string.length - suffix.length, upTo: string.length) == suffix
    }

    pub fun hasPrefix(_ string: String, prefix: String) : Bool {
        if prefix.length > string.length {
            return false
        }
        return string.slice(from: 0, upTo: prefix.length) == prefix
    }
    
}
 