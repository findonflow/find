import FindUtils from "../contracts/FindUtils.cdc"

pub fun main(string: String, char:Character) : Bool {
	return FindUtils.containsChar(string, char: char)
}