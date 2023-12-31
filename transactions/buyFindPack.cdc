import FindPack from "../contracts/FindPack.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import Profile from "../contracts/Profile.cdc"

transaction(packTypeName: String, packTypeId:UInt64, numberOfPacks:UInt64, totalAmount: UFix64) {
    let packs: &FindPack.Collection

    let userPacks: Capability<&FindPack.Collection>
    let salePrice: UFix64
    let packsLeft: UInt64

    let userFlowTokenVault: auth(FungibleToken.Withdrawable) &FlowToken.Vault

    let paymentVault: @{FungibleToken.Vault}
    let balanceBeforeTransfer:UFix64

    prepare(account: auth (StorageCapabilities, SaveValue,PublishCapability, BorrowValue, FungibleToken.Withdrawable) &Account) {


        let col = account.storage.borrow<&FindPack.Collection>(from: FindPack.CollectionStoragePath)
        if col == nil {
            account.storage.save( <- FindPack.createEmptyCollection(), to: FindPack.CollectionStoragePath)
            let cap = account.capabilities.storage.issue<&FindPack.Collection>(FindPack.CollectionStoragePath)
            account.capabilities.publish(cap, at: FindPack.CollectionPublicPath)
        }


        let profileCap = account.capabilities.get<&{Profile.Public}>(Profile.publicPath)!
        if !profileCap.check() {
            let profile <-Profile.createUser(name:account.address.toString(), createdAt: "find")

            let fusdReceiver = account.capabilities.get<&{FungibleToken.Receiver}>(/public/fusdReceiver)
            if fusdReceiver == nil {
                let fusd <- FUSD.createEmptyVault()
                account.storage.save(<- fusd, to: /storage/fusdVault)
                var cap = account.capabilities.storage.issue<&{FungibleToken.Receiver}>(/storage/fusdVault)
                account.capabilities.publish(cap, at: /public/fusdReceiver)
                let capb = account.capabilities.storage.issue<&{FungibleToken.Vault}>(/storage/fusdVault)
                account.capabilities.publish(capb, at: /public/fusdBalance)
            }


            let fusdWallet=Profile.Wallet(
                name:"FUSD", 
                receiver:account.capabilities.get<&{FungibleToken.Receiver}>(/public/fusdReceiver)!,
                balance:account.capabilities.get<&{FungibleToken.Vault}>(/public/fusdBalance)!,
                accept: Type<@FUSD.Vault>(),
                tags: ["fusd", "stablecoin"]
            )

            profile.addWallet(fusdWallet)

            let flowWallet=Profile.Wallet(
                name:"Flow", 
                receiver:account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!,
                balance:account.capabilities.get<&{FungibleToken.Vault}>(/public/flowTokenBalance)!,
                accept: Type<@FlowToken.Vault>(),
                tags: ["flow"]
            )
            profile.addWallet(flowWallet)
            account.storage.save(<-profile, to: Profile.storagePath)

            let cap = account.capabilities.storage.issue<&Profile.User>(Profile.storagePath)
            account.capabilities.publish(cap, at: Profile.publicPath)
            account.capabilities.publish(cap, at: Profile.publicReceiverPath)
        }

        self.userPacks=account.capabilities.get<&FindPack.Collection>(FindPack.CollectionPublicPath)!
        self.packs=FindPack.getPacksCollection(packTypeName: packTypeName, packTypeId:packTypeId)

        self.salePrice= FindPack.getCurrentPrice(packTypeName: packTypeName, packTypeId:packTypeId, user:account.address) ?? panic ("Cannot buy the pack now") 
        self.packsLeft= UInt64(self.packs.getPacksLeft())


        self.userFlowTokenVault = account.storage.borrow<auth(FungibleToken.Withdrawable) &FlowToken.Vault>(from: /storage/flowTokenVault) ?? panic("Cannot borrow FlowToken vault from account storage")
        self.balanceBeforeTransfer = self.userFlowTokenVault.balance

        if self.balanceBeforeTransfer < totalAmount {
            panic("Your account does not have enough funds has ".concat(self.balanceBeforeTransfer.toString()).concat(" needs ").concat(totalAmount.toString()))
        }
        self.paymentVault <- self.userFlowTokenVault.withdraw(amount: totalAmount)
    }

    pre {
        self.salePrice * UFix64(numberOfPacks) == totalAmount: "unexpected sending amount"
        self.packsLeft >= numberOfPacks : "Rats! there are no packs left"
        self.userPacks.check() : "User need a receiver to put the pack in"
    }

    execute {
        var counter = numberOfPacks
        while counter > 0 {
            let purchasingVault <- self.paymentVault.withdraw(amount: self.salePrice)
            self.packs.buy(packTypeName: packTypeName, typeId:packTypeId, vault: <- purchasingVault, collectionCapability: self.userPacks)
            counter = counter - 1
        }
        if self.paymentVault.getBalance() != 0.0 {
            panic("paymentVault balance is non-zero after paying")
        }
        destroy self.paymentVault
    }

}

