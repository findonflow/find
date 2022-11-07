import FindUtils from "../contracts/FindUtils.cdc"

pub fun main(string: String, suffix:String) : Bool {
	return FindUtils.hasSuffix(string, suffix: suffix)
}