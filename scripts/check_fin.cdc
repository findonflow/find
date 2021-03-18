// This script checks that the accounts are set up correctly for the marketplace tutorial.
//

//testnet
//import FungibleToken from 0x9a0766d93b6608b7
//import NonFungibleToken from 0x631e88ae7f1d7c20
//import Art from 0x1ff7e32d71183db0

//emulator
import FIN from 0xf8d6e0586b0a20c7


/*
  This script will check an address and print out its FT, NFT and Versus resources
 */
pub fun main() :UFix64 {

    log(FIN.status("0xb"))
    return FIN.calculateCost("0xb")
}
