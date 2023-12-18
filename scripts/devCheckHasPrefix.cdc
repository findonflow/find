import FindUtils from "../contracts/FindUtils.cdc"

access(all) main(string: String, prefix:String) : Bool {
	return FindUtils.hasPrefix(string, prefix: prefix)
}