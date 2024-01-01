import FindUtils from "../contracts/FindUtils.cdc"

access(all) fun main(string: String, char:Character) : Bool {
	return FindUtils.containsChar(string, char: char)
}