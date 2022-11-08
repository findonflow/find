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

    pub fun toUpper(_ string: String) : String {
        let map = FindUtils.getUpperCases()
        var res = ""
        var i = 0 
        while i < string.length {
            let c = map[string[i].toString()] ?? string[i].toString()
            res = res.concat(c)
            i = i + 1
        }
        return res
    }

    pub fun firstUpperLetter(_ string: String) : String {
        if string.length < 1 {
            return string
        }
        let map = FindUtils.getUpperCases()
        if let first = map[string[0].toString()] {
            return first.concat(string.slice(from: 1, upTo: string.length))
             
        }
        return string
    }

    pub fun getUpperCases() : {String : String} {
        return {
            "a" : "A",
            "b" : "B",
            "c" : "C",
            "d" : "D",
            "e" : "E",
            "f" : "F",
            "g" : "G",
            "h" : "H",
            "i" : "I",
            "j" : "J",
            "k" : "K",
            "l" : "L",
            "m" : "M",
            "n" : "N",
            "o" : "O",
            "p" : "P",
            "q" : "Q",
            "r" : "R",
            "s" : "S",
            "t" : "T",
            "u" : "U",
            "v" : "V",
            "w" : "W",
            "x" : "X",
            "y" : "Y",
            "z" : "Z"
        }
    }
    
}
 