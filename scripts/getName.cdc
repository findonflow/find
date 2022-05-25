import FIND from "../contracts/FIND.cdc"

pub fun main(address: Address) : String?{
	return FIND.reverseLookup(address)
}
