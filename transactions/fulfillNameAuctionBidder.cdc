import "FIND"
import "FungibleToken"
import "FUSD"
import "Profile"

transaction(owner: Address, name: String) {

    let leaseCollectionOwner : &FIND.LeaseCollection{FIND.LeaseCollectionPublic}?

    prepare(account: auth(BorrowValue) &Account) {


        //Add exising FUSD or create a new one and add it
        let fusdReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
        if !fusdReceiver.check() {
            let fusd <- FUSD.createEmptyVault(vaultType: Type<@FUSD.Vault>())
            account.storage.save(<- fusd, to: /storage/fusdVault)
            account.link<&FUSD.Vault{FungibleToken.Receiver}>( /public/fusdReceiver, target: /storage/fusdVault)
            account.link<&FUSD.Vault{FungibleToken.Balance}>( /public/fusdBalance, target: /storage/fusdVault)
        }

        let leaseCollection = account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
        if !leaseCollection!.check() {
            account.storage.save(<- FIND.createEmptyLeaseCollection(), to: FIND.LeaseStoragePath)
            account.link<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>( FIND.LeasePublicPath, target: FIND.LeaseStoragePath)
        }

        let profileCap = account.getCapability<&{Profile.Public}>(Profile.publicPath)
        if !profileCap.check() {
            let profile <-Profile.createUser(name:name, createdAt: "find")

            let fusdWallet=Profile.Wallet( name:"FUSD", receiver:fusdReceiver, balance:account.getCapability<&{FungibleToken.Balance}>(/public/fusdBalance), accept: Type<@FUSD.Vault>(), tags: ["fusd", "stablecoin"])

            profile.addWallet(fusdWallet)

            account.storage.save(<-profile, to: Profile.storagePath)
            account.link<&Profile.User{Profile.Public}>(Profile.publicPath, target: Profile.storagePath)
            account.link<&{FungibleToken.Receiver}>(Profile.publicReceiverPath, target: Profile.storagePath)
        }

        self.leaseCollectionOwner = getAccount(owner).getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath).borrow()

    }

    pre{
        self.leaseCollectionOwner != nil : "Cannot borrow reference to find lease collection. Account address: ".concat(owner.toString())
    }

    execute {
        self.leaseCollectionOwner!.fulfillAuction(name)
    }
}
