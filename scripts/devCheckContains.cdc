import FindUtils from "../contracts/FindUtils.cdc"

pub fun main(string: String, element:String) : Bool {
	return FindUtils.contains(string, element: element)
}