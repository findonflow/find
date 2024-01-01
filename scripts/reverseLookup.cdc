import FIND from "../contracts/FIND.cdc"

access(all) fun main(addr:Address) : String?{

	return FIND.reverseLookup(addr)

}
