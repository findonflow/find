import FindUtils from "../contracts/FindUtils.cdc"

access(all) main(string: String) : String {
	return FindUtils.toUpper(string)
}
