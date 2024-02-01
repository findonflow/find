import FIND from "../contracts/FIND.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import Dandy from "../contracts/Dandy.cdc"

transaction(user: String, id: UInt64) {

    let address : Address
    let cap : Capability<&{NonFungibleToken.Collection}>
    let senderRef : auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}

    prepare(account: auth(BorrowValue, NonFungibleToken.Withdraw) &Account) {
        self.address = FIND.resolve(user) ?? panic("Cannot find user with this name / address")
        self.cap = getAccount(self.address).capabilities.get<&{NonFungibleToken.Collection}>(Dandy.CollectionPublicPath)!

        self.senderRef=account.storage.borrow<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>(from: Dandy.CollectionStoragePath) ?? panic("Cannot borrow reference to sender Collection from path ".concat(Dandy.CollectionStoragePath.toString()))



    }

    pre{
        self.cap.check() : "Cannot borrow reference to receiver Collection. Receiver account : ".concat(self.address.toString())
        self.senderRef != nil : "Cannot borrow reference to sender Collection."
    }

    execute{
        self.cap.borrow()!.deposit(token: <- self.senderRef.withdraw(withdrawID: id))
    }
}
