import Dandy from "../contracts/Dandy.cdc"
import FIND from "../contracts/FIND.cdc"

access(all) 
fun main(user: String, minter: String) : [UInt64] {
    let address = FIND.resolve(user)
    if address == nil {
        return []
    }
    let account = getAccount(address!)
    if account.balance == 0.0 {
        return []
    }
    let cap = account.capabilities.get<&Dandy.Collection>(Dandy.CollectionPublicPath)!
    let ref = cap.borrow() ?? panic("Cannot borrow reference to Dandy Collection. Account address : ".concat(address!.toString()))

    return ref.getIDsFor(minter: minter)
}
