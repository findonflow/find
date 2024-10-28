import "FungibleToken"
import "FlowToken"
import "FIND"
import "Profile"

// map of {User in string (find name or address) : [tag]}
transaction(follows:{String : [String]}) {

    let profile : auth(Profile.Admin) &Profile.User

    prepare(account: auth(BorrowValue, SaveValue, PublishCapability, IssueStorageCapabilityController) &Account) {

        self.profile =account.storage.borrow<auth(Profile.Admin) &Profile.User>(from:Profile.storagePath) ?? panic("Cannot borrow reference to profile")

        var hasFlowWallet=false
        let wallets=self.profile.getWallets()
        for wallet in wallets {
            if wallet.name =="Flow" {
                hasFlowWallet=true
            }
        }

        if !hasFlowWallet {
            let flowWallet=Profile.Wallet(
                name:"Flow",
                receiver:account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver),
                balance:account.capabilities.get<&{FungibleToken.Vault}>(/public/flowTokenBalance),
                accept: Type<@FlowToken.Vault>(),
                tags: ["flow"]
            )
            self.profile.addWallet(flowWallet)
        }
        let leaseCollection = account.capabilities.get<&{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
        if !leaseCollection.check() {
            account.storage.save(<- FIND.createEmptyLeaseCollection(), to: FIND.LeaseStoragePath)
            let cap = account.capabilities.storage.issue<&FIND.LeaseCollection>(FIND.LeaseStoragePath)
            account.capabilities.publish(cap, at: FIND.LeasePublicPath)
        }

    }

    execute{
        for key in follows.keys {
            let user = FIND.resolve(key) ?? panic(key.concat(" cannot be resolved. It is either an invalid .find name or address"))
            let tags = follows[key]!
            self.profile.follow(user, tags: tags)
        }
    }
}

