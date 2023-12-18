import FindUtils from "../contracts/FindUtils.cdc"

pub fun main(string: String) : String {
	return FindUtils.toUpper(string)
}
