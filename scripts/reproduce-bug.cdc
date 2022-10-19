pub fun main() : [String] {
    let dictionary : {String : Bool} = {}

    dictionary["user1"] = true 
    dictionary["name1"] = true 
    dictionary["name2"] = true 

    return dictionary.keys
}