import NonFungibleToken from 0x1d7e57aa55817448
import FungibleToken from 0xf233dcee88fe0abe
import FlowStorageFees from 0xe467b9dd11fa00df
import FlowToken from 0x1654653399040a61
import MetadataViews from 0x1d7e57aa55817448
import NFTCatalog from 0x49a7cda3a1eecc29
import FINDNFTCatalog from 0x097bafa4e0b48eef
import FindViews from 0x097bafa4e0b48eef
import FIND from 0x097bafa4e0b48eef
import FindAirdropper from 0x097bafa4e0b48eef
import FTRegistry from 0x097bafa4e0b48eef
import Profile from 0x097bafa4e0b48eef
import Sender from 0x097bafa4e0b48eef

transaction(nftIdentifiers: [String], allReceivers: [String] , ids:[UInt64], memos: [String], donationTypes: [String?], donationAmounts: [UFix64?], findDonationType: String?, findDonationAmount: UFix64?) {

    let authPointers : [FindViews.AuthNFTPointer]
    let paths : [PublicPath]
    let flowVault : &FungibleToken.Vault
    let flowTokenRepayment : Capability<&FlowToken.Vault{FungibleToken.Receiver}>
    let defaultTokenAvailableBalance : UFix64

    let royalties: [MetadataViews.Royalties?]
    let totalRoyalties: [UFix64]
    let vaultRefs: {String : &FungibleToken.Vault}
    var token : &Sender.Token

    prepare(account : auth(BorrowValue) &Account) {

        self.authPointers = []
        self.paths = []
        self.royalties = []
        self.totalRoyalties = []
        self.vaultRefs = {}


        let contractData : {Type : NFTCatalog.NFTCatalogMetadata} = {}


        for i , typeIdentifier in nftIdentifiers {
            let type = CompositeType(typeIdentifier) ?? panic("Cannot refer to type with identifier : ".concat(typeIdentifier))

            var data : NFTCatalog.NFTCatalogMetadata? = contractData[type]
            if data == nil {
                data = FINDNFTCatalog.getMetadataFromType(type) ?? panic("NFT Type is not supported by NFT Catalog. Type : ".concat(type.identifier))
                contractData[type] = data
            }

            let path = data!.collectionData

            var providerCap=account.getCapability<&{NonFungibleToken.Provider, ViewResolver.ResolverCollection, NonFungibleToken.Collection}>(path.privatePath)
            if !providerCap.check() {
                let newCap = account.link<&{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
                    path.privatePath,
                    target: path.storagePath
                )
                if newCap == nil {
                    // If linking is not successful, we link it using finds custom link
                    let pathIdentifier = path.privatePath.toString()
                    let findPath = PrivatePath(identifier: pathIdentifier.slice(from: "/private/".length , upTo: pathIdentifier.length).concat("_FIND"))!
                    account.link<&{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
                        findPath,
                        target: path.storagePath
                    )
                    providerCap = account.getCapability<&{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(findPath)
                }
            }
            let pointer = FindViews.AuthNFTPointer(cap: providerCap, id: ids[i])

            if let dt = donationTypes[i] {
                self.royalties.append(pointer.getRoyalty())
                self.totalRoyalties.append(pointer.getTotalRoyaltiesCut())

                // get the vault for donation
                if self.vaultRefs[dt] == nil {
                    let info = FTRegistry.getFTInfo(dt) ?? panic("This token type is not supported at the moment : ".concat(dt))
                    let ftPath = info.vaultPath
                    let ref = account.borrow<&FungibleToken.Vault>(from: ftPath) ?? panic("Cannot borrow vault reference for type : ".concat(dt))
                    self.vaultRefs[dt] = ref
                }

            } else {
                self.royalties.append(nil)
                self.totalRoyalties.append(0.0)
            }

            self.authPointers.append(pointer)
            self.paths.append(path.publicPath)
        }

        self.flowVault = account.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault) ?? panic("Cannot borrow reference to sender's flow vault")
        self.flowTokenRepayment = account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)
        self.defaultTokenAvailableBalance = FlowStorageFees.defaultTokenAvailableBalance(account.address)

        // get the vault for find donation
        if let dt = findDonationType {
            if self.vaultRefs[dt] == nil {
                let info = FTRegistry.getFTInfo(dt) ?? panic("This token type is not supported at the moment : ".concat(dt))
                let ftPath = info.vaultPath
                let ref = account.borrow<&FungibleToken.Vault>(from: ftPath) ?? panic("Cannot borrow vault reference for type : ".concat(dt))
                self.vaultRefs[dt] = ref
            }
        }

        if account.borrow<&Sender.Token>(from: Sender.storagePath) == nil {
            account.save(<- Sender.create(), to: Sender.storagePath)
        }

        self.token =account.borrow<&Sender.Token>(from: Sender.storagePath)!

    }

    execute {
        let addresses : {String : Address} = {}
        let estimatedStorageFee = 0.0002 * UFix64(self.authPointers.length)
        // we pass in the least amount as possible for storage fee here
        let tempVault <- self.flowVault.withdraw(amount: 0.0)
        var vaultRef = &tempVault as &FungibleToken.Vault
        if self.defaultTokenAvailableBalance <= estimatedStorageFee {
            vaultRef = self.flowVault as &FungibleToken.Vault
        } else {
            tempVault.deposit(from: <- self.flowVault.withdraw(amount: estimatedStorageFee))
        }

        let ctx : {String : String} = {
            "tenant" : "find"
        }

        for i,  pointer in self.authPointers {
            let receiver = allReceivers[i]
            let id = ids[i]
            ctx["message"] = memos[i]
            let path = self.paths[i]

            var user = addresses[receiver]
            if user == nil {
                user = FIND.resolve(receiver) ?? panic("Cannot resolve user with name / address : ".concat(receiver))
                addresses[receiver] = user
            }

            // airdrop thru airdropper
            FindAirdropper.forcedAirdrop(pointer: pointer, receiver: user!, path: path, context: ctx, storagePayment: vaultRef, flowTokenRepayment: self.flowTokenRepayment, deepValidation: true)
        }
        self.flowVault.deposit(from: <- tempVault)

        // This is hard coded for spliting at the front end for now. So if there are no royalties, all goes to find
        // AND This does not support different ft types for now.
        var goesToFindFund = 0.0
        for i , type in donationTypes {
            if type == nil {
                continue
            }
            let amount = donationAmounts[i]!
            let royalties = self.royalties[i]!
            let totalRoyalties = self.totalRoyalties[i]
            let vaultRef = self.vaultRefs[type!]!
            var noRoyalty = false
            if totalRoyalties == 0.0 {
                goesToFindFund = goesToFindFund + amount
                continue
            }

            let balance = vaultRef.balance
            var totalPaid = 0.0

            for j, r in royalties.getRoyalties() {
                var cap : Capability<&{FungibleToken.Receiver}> = r.receiver
                if !r.receiver.check(){
                    // try to grab from profile
                    if let ref = getAccount(r.receiver.address).getCapability<&{Profile.Public}>(Profile.publicPath).borrow() {
                        if ref.hasWallet(vaultRef.getType().identifier) {
                            cap = getAccount(r.receiver.address).getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
                        } else if let ftInfo = FTRegistry.getFTInfo(vaultRef.getType().identifier) {
                            cap = getAccount(r.receiver.address).getCapability<&{FungibleToken.Receiver}>(ftInfo.receiverPath)
                        }
                    }

                }

                if cap.check() {
                    let individualAmount = r.cut / totalRoyalties * amount
                    let vault <- vaultRef.withdraw(amount: individualAmount)
                    cap.borrow()!.deposit(from: <- vault)

                    totalPaid = totalPaid + individualAmount
                }
            }

            assert(totalPaid <= amount, message: "Amount paid is greater than expected" )

        }

        // for donating to find
        if findDonationType != nil {
            vaultRef = self.vaultRefs[findDonationType!]!
            let vault <- vaultRef.withdraw(amount: findDonationAmount! + goesToFindFund)
            FIND.depositWithTagAndMessage(to: "find", message: "donation to .find", tag: "donation", vault: <- vault, from: self.token)
        }
    }
}
