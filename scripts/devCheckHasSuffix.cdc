import FindUtils from "../contracts/FindUtils.cdc"

access(all) main(string: String, suffix:String) : Bool {
	return FindUtils.hasSuffix(string, suffix: suffix)
}