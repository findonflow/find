import "FungibleToken"
import "FUSD"
import "FlowToken"
import "FIND"
import "Profile"

transaction(name:String, description: String, avatar: String, tags:[String], allowStoringFollowers: Bool, linkTitles : {String: String}, linkTypes: {String:String}, linkUrls : {String:String}, removeLinks : [String]) {

    let profile : auth(Profile.Owner) &Profile.User

    prepare(account: auth(BorrowValue, SaveValue, PublishCapability, IssueStorageCapabilityController) &Account) {

        self.profile =account.storage.borrow<auth(Profile.Owner) &Profile.User>(from:Profile.storagePath) ?? panic("Cannot borrow reference to profile")

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
        self.profile.setName(name)
        self.profile.setDescription(description)
        self.profile.setAvatar(avatar)
        self.profile.setTags(tags)

        for link in removeLinks {
            self.profile.removeLink(link)
        }

        for titleName in linkTitles.keys {
            let title=linkTitles[titleName]!
            let url = linkUrls[titleName]!
            let type = linkTypes[titleName]!

            self.profile.addLinkWithName(name:titleName, link: Profile.Link(title: title, type: type, url: url))
        }
        self.profile.emitUpdatedEvent()
    }
}

