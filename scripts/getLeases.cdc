import FIND from "../contracts/FIND.cdc"

pub fun main() : [FIND.NetworkLease] {
	return FIND.getLeases()
}
