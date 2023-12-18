import FIND from "../contracts/FIND.cdc"

access(all) main(addr:Address) : String?{

	return FIND.reverseLookup(addr)

}
