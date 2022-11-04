import FindUtils from "../contracts/FindUtils.cdc"

pub fun main(string: String, prefix:String) : Bool {
	return FindUtils.hasPrefix(string, prefix: prefix)
}