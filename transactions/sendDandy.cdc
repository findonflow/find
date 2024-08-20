import "FIND"
import "NonFungibleToken"
import "Dandy"

transaction(user: String, id: UInt64) {

    let address : Address
    let cap : Capability<&{NonFungibleToken.Collection}>
    let senderRef : auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}

    prepare(account: auth(Storage, NonFungibleToken.Withdraw, IssueStorageCapabilityController) &Account) {
        self.address = FIND.resolve(user) ?? panic("Cannot find user with this name / address")
        self.cap = getAccount(self.address).capabilities.get<&{NonFungibleToken.Collection}>(Dandy.CollectionPublicPath)!


        let storagePathIdentifer = Dandy.CollectionStoragePath.toString().split(separator:"/")[1]
        let providerIdentifier = storagePathIdentifer.concat("Provider")
        let providerStoragePath = StoragePath(identifier: providerIdentifier)!

        //if this stores anything but this it will panic, why does it not return nil?
        let existingProvider= account.storage.copy<Capability<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>>(from: providerStoragePath) 
        if existingProvider==nil {
            let provider=account.capabilities.storage.issue<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>(Dandy.CollectionStoragePath)
            //we save it to storage to memoize it
            account.storage.save(provider, to: providerStoragePath)
            log("create new cap")
            self.senderRef=provider.borrow()!
        }else {
            self.senderRef= existingProvider!.borrow()!
            log("existing")
        }
    }

    pre{
        self.cap.check() : "Cannot borrow reference to receiver Collection. Receiver account : ".concat(self.address.toString())
        self.senderRef != nil : "Cannot borrow reference to sender Collection."
    }

    execute{
        self.cap.borrow()!.deposit(token: <- self.senderRef.withdraw(withdrawID: id))
    }
}
