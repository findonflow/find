pub contract FindUtils {

	pub fun joinMapToString( _ map:{String:String}) : String {
		var message=""
		for i, key in map.keys {
			if i > 0 {
				message=message.concat(" ")
			}
			message=message.concat(key.concat("=").concat(map[key]!))
		}
		return message
	}

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

	pub fun trimSuffix(_ name: String, suffix: String) : String {
		if !self.hasSuffix(name, suffix:suffix) {
			return name
		}
		let pos = name.length - suffix.length
		return name.slice(from: 0, upTo: pos)
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

    pub fun splitString(_ string: String, sep: Character) : [String] {
        if var index = string.utf8.firstIndex(of: sep.toString().utf8[0]) {
			let first = string.slice(from: 0, upTo: index)
			let second = string.slice(from: index + 1, upTo: string.length)
			let res = [first]
			res.appendAll(self.splitString(second, sep: sep))
			return res
        }
        return [string]
    }

    pub fun toUpper(_ string: String) : String {
        let map = FindUtils.getLowerCaseToUpperCase()
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
        let map = FindUtils.getLowerCaseToUpperCase()
        if let first = map[string[0].toString()] {
            return first.concat(string.slice(from: 1, upTo: string.length))

        }
        return string
    }

    pub fun to_snake_case(_ string: String) : String {
        var res = ""
        var i = 0
        let map = FindUtils.getUpperCaseToLowerCase()
        var spaced = false
        while i < string.length {
            if string[i] == " " {
                res = res.concat("_")
                spaced = true
                i = i + 1
                continue
            }
            if let lowerCase = map[string[i].toString()] {
                if i > 0 && !spaced {
                    res = res.concat("_")
                }
                res = res.concat(lowerCase)
                i = i + 1
                spaced == false
                continue
            }
            res = res.concat(string[i].toString())
            i = i + 1
        }
        return res
    }

    pub fun toCamelCase(_ string: String) : String {
        var res = ""
        var i = 0
        let map = FindUtils.getLowerCaseToUpperCase()
        var upper = false
        let string = string.toLower()
        while i < string.length {
            if string[i] == " " || string[i] == "_" {
                upper = true
                i = i + 1
                continue
            }
            if upper {
                if let upperCase = map[string[i].toString()] {
                    res = res.concat(upperCase)
                    upper = false
                    i = i + 1
                    continue
                }
            }
            res = res.concat(string[i].toString())
            i = i + 1
        }
        return res
    }

    pub fun getLowerCaseToUpperCase() : {String : String} {
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

    pub fun getUpperCaseToLowerCase() : {String : String} {
        return {
            "A" : "a",
            "B" : "b",
            "C" : "c",
            "D" : "d",
            "E" : "e",
            "F" : "f",
            "G" : "g",
            "H" : "h",
            "I" : "i",
            "J" : "j",
            "K" : "k",
            "L" : "l",
            "M" : "m",
            "N" : "n",
            "O" : "o",
            "P" : "p",
            "Q" : "q",
            "R" : "r",
            "S" : "s",
            "T" : "t",
            "U" : "u",
            "V" : "v",
            "W" : "w",
            "X" : "x",
            "Y" : "y",
            "Z" : "z"
        }
    }

}

