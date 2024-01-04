import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FindViews from "../contracts/FindViews.cdc"
import FIND from "../contracts/FIND.cdc"
import FindAirdropper from "../contracts/FindAirdropper.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import Profile from "../contracts/Profile.cdc"
import Sender from "../contracts/Sender.cdc"

transaction(nftIdentifiers: [String], allReceivers: [String] , ids:[UInt64], memos: [String], donationTypes: [String?], donationAmounts: [UFix64?], findDonationType: String?, findDonationAmount: UFix64?) {

    let authPointers : [FindViews.AuthNFTPointer]
    let paths : [PublicPath]
    let royalties: [MetadataViews.Royalties?]
    let totalRoyalties: [UFix64]
    let vaultRefs: {String : auth(FungibleToken.Withdrawable) &{FungibleToken.Vault}}
    var token : &Sender.Token


    prepare(account: auth (BorrowValue, SaveValue, StorageCapabilities, NonFungibleToken.Withdrawable, IssueStorageCapabilityController, FungibleToken.Withdrawable) &Account) {

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

            let storage = account.capabilities.storage
            //TODO: should we issue a new cap here everytime?

            /*
            var providerCap : Capability<auth(NonFungibleToken.Withdrawable) &{NonFungibleToken.Collection}>? = nil
            for p in storage.getControllers(forPath: path.storagePath) {
                let ref = p.capability.borrow<auth(NonFungibleToken.Withdrawable) &{NonFungibleToken.Collection}>() 
                if ref != nil{
                    providerCap=p.capability as! auth(NonFungibleToken.Withdrawable) &{NonFungibleToken.Collection}
                    break
                }

            }
            if providerCap == nil{

                */
                var providerCap=storage.issue<auth(NonFungibleToken.Withdrawable) &{NonFungibleToken.Collection}>(path.storagePath)

                let capcon = storage.getController(byCapabilityID:providerCap.id)!
                capcon.setTag("sendNFT".concat(path.storagePath.toString()))

                let pointer = FindViews.AuthNFTPointer(cap: providerCap, id: ids[i])

                if let dt = donationTypes[i] {
                    self.royalties.append(pointer.getRoyalty())
                    self.totalRoyalties.append(pointer.getTotalRoyaltiesCut())

                    // get the vault for donation
                    if self.vaultRefs[dt] == nil {
                        let info = FTRegistry.getFTInfo(dt) ?? panic("This token type is not supported at the moment : ".concat(dt))
                        let ftPath = info.vaultPath
                        let ref = account.storage.borrow<auth(FungibleToken.Withdrawable) &{FungibleToken.Vault}>(from: ftPath) ?? panic("Cannot borrow vault reference for type : ".concat(dt))
                        self.vaultRefs[dt] = ref
                    }

                } else {
                    self.royalties.append(nil)
                    self.totalRoyalties.append(0.0)
                }


                self.authPointers.append(pointer)
                self.paths.append(path.publicPath)
            }

            // get the vault for find donation
            if let dt = findDonationType {
                if self.vaultRefs[dt] == nil {
                    let info = FTRegistry.getFTInfo(dt) ?? panic("This token type is not supported at the moment : ".concat(dt))
                    let ftPath = info.vaultPath
                    let ref = account.storage.borrow<auth(FungibleToken.Withdrawable) &{FungibleToken.Vault}>(from: ftPath) ?? panic("Cannot borrow vault reference for type : ".concat(dt))
                    self.vaultRefs[dt] = ref
                }
            }

            if account.storage.borrow<&Sender.Token>(from: Sender.storagePath) == nil {
                account.storage.save(<- Sender.createToken(), to: Sender.storagePath)
            }

            self.token =account.storage.borrow<&Sender.Token>(from: Sender.storagePath)!

        }

        execute {
            let addresses : {String : Address} = {}

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
                FindAirdropper.safeAirdrop(pointer: pointer, receiver: user!, path: path, context: ctx, deepValidation: true)
            }


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
                if totalRoyalties == 0.0 {
                    goesToFindFund = goesToFindFund + amount
                    continue
                }

                let balance = vaultRef.getBalance()
                var totalPaid = 0.0

                for j, r in royalties.getRoyalties() {
                    var cap : Capability<&{FungibleToken.Receiver}>? = r.receiver
                    if r.receiver.check() {
                        let individualAmount = r.cut / totalRoyalties * amount
                        let vault <- vaultRef.withdraw(amount: individualAmount)
                        r.receiver.borrow()!.deposit(from: <- vault)
                        totalPaid = totalPaid + individualAmount
                    }
                    //there is no way to send over funds if this does not happen anmore
                }

                assert(totalPaid <= amount, message: "Amount paid is greater than expected" )

            }


            // for donating to find
            if findDonationType != nil {
                let vaultRef = self.vaultRefs[findDonationType!]!
                let vault <- vaultRef.withdraw(amount: findDonationAmount! + goesToFindFund)
                FIND.depositWithTagAndMessage(to: "find", message: "donation to .find", tag: "donation", vault: <- vault, from: self.token)
            }
        }
    }
