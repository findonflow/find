import FIND from "../contracts/FIND.cdc"


/*
  This script will check an address and print out its FT, NFT and Versus resources
 */
pub fun main() :UFix64 {

    log(FIND.status("0xb"))
    return FIND.calculateCost("0xb")
}
