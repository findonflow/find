import "FungibleToken"
import "FUSD"
import "FlowToken"
import "FIND"
import "Profile"

// map of {User in string (find name or address) : [tag]}
transaction(follows:{String : [String]}) {

    let profile : auth(Profile.Admin) &Profile.User

    prepare(account: auth(BorrowValue, SaveValue, PublishCapability, IssueStorageCapabilityController) &Account) {

        self.profile =account.storage.borrow<auth(Profile.Admin) &Profile.User>(from:Profile.storagePath) ?? panic("Cannot borrow reference to profile")


        let fusdReceiver = account.capabilities.get<&{FungibleToken.Receiver}>(/public/fusdReceiver)
        if fusdReceiver == nil {
            let fusd <- FUSD.createEmptyVault()
            account.storage.save(<- fusd, to: /storage/fusdVault)
            var cap = account.capabilities.storage.issue<&{FungibleToken.Receiver}>(/storage/fusdVault)
            account.capabilities.publish(cap, at: /public/fusdReceiver)
            let capb = account.capabilities.storage.issue<&{FungibleToken.Vault}>(/storage/fusdVault)
            account.capabilities.publish(capb, at: /public/fusdBalance)
        }

        var hasFusdWallet=false
        var hasFlowWallet=false
        let wallets=self.profile.getWallets()
        for wallet in wallets {
            if wallet.name=="FUSD" {
                hasFusdWallet=true
            }

            if wallet.name =="Flow" {
                hasFlowWallet=true
            }
        }

        if !hasFlowWallet {
            let flowWallet=Profile.Wallet(
                name:"Flow",
                receiver:account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!,
                balance:account.capabilities.get<&{FungibleToken.Vault}>(/public/flowTokenBalance)!,
                accept: Type<@FlowToken.Vault>(),
                tags: ["flow"]
            )
            self.profile.addWallet(flowWallet)
        }

        if !hasFusdWallet {
            let fusdWallet=Profile.Wallet(
                name:"FUSD",
                receiver:account.capabilities.get<&{FungibleToken.Receiver}>(/public/fusdReceiver)!,
                balance:account.capabilities.get<&{FungibleToken.Vault}>(/public/fusdBalance)!,
                accept: Type<@FUSD.Vault>(),
                tags: ["fusd", "stablecoin"]
            )
            self.profile.addWallet(fusdWallet)
        }

        let leaseCollection = account.capabilities.get<&{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)!
        if leaseCollection == nil {
            account.storage.save(<- FIND.createEmptyLeaseCollection(), to: FIND.LeaseStoragePath)
            let cap = account.capabilities.storage.issue<&FIND.LeaseCollection>(FIND.LeaseStoragePath)
            account.capabilities.publish(cap, at: FIND.LeasePublicPath)
        }

        let bidCollection = account.capabilities.get<&FIND.BidCollection>(FIND.BidPublicPath)
        if bidCollection == nil {
            let fr = account.capabilities.get<&{FungibleToken.Receiver}>(/public/fusdReceiver)!
            let lc = account.capabilities.get<&FIND.LeaseCollection>(FIND.LeasePublicPath)!
            account.storage.save(<- FIND.createEmptyBidCollection(receiver: fr, leases: lc), to: FIND.BidStoragePath)
            let cap = account.capabilities.storage.issue<&FIND.BidCollection>(FIND.BidStoragePath)
            account.capabilities.publish(cap, at: FIND.BidPublicPath)
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

