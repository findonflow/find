import "Dandy"
import "FIND"

access(all) fun main(user: String) : [String] {
    let address = FIND.resolve(user)
    if address == nil {
        return []
    }
    let account = getAccount(address!)
    if account.balance == 0.0 {
        return []
    }
    let ref = account.capabilities.borrow<&Dandy.Collection>(Dandy.CollectionPublicPath) ?? panic("Cannot borrow reference to Dandy Collection. Account address : ".concat(address!.toString()))

    return ref.getMinters()
}
