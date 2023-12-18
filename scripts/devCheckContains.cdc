import FindUtils from "../contracts/FindUtils.cdc"

access(all) main(string: String, element:String) : Bool {
	return FindUtils.contains(string, element: element)
}