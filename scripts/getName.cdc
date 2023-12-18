import FIND from "../contracts/FIND.cdc"

access(all)
fun main(address: Address) : String?{
    return FIND.reverseLookup(address)
}
