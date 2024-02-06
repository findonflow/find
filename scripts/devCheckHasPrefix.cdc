import "FindUtils"

access(all) fun main(string: String, prefix:String) : Bool {
	return FindUtils.hasPrefix(string, prefix: prefix)
}
