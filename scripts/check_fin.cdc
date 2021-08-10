import FIN from "../contracts/FIN.cdc"


/*
  This script will check an address and print out its FT, NFT and Versus resources
 */
pub fun main() :UFix64 {

    log(FIN.status("0xb"))
    return FIN.calculateCost("0xb")
}
