import FindUtils from "../contracts/FindUtils.cdc"

access(all) fun main(string: String) : String {
	return FindUtils.toUpper(string)
}
