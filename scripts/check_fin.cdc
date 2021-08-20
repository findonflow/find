import FiNS from "../contracts/FiNS.cdc"


/*
  This script will check an address and print out its FT, NFT and Versus resources
 */
pub fun main() :UFix64 {

    log(FiNS.status("0xb"))
    return FiNS.calculateCost("0xb")
}
