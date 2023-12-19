import FIND from "../contracts/FIND.cdc"

access(all)
fun main() : &[FIND.NetworkLease] {
    return FIND.getLeases()
}
