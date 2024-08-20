import "NonFungibleToken"
import "FungibleToken"
import "TokenForwarding"
import "FlowToken"
import "MetadataViews"
import "ViewResolver"
import "NFTCatalog"
import "FINDNFTCatalog"
import "Profile"
import "FindViews"
import "FIND"
import "FindAirdropper"
import "FindUtils"

access(all) fun main(sender: Address, nftIdentifiers: [String],  allReceivers:[String] , ids: [UInt64], memos: [String]) : [Report] {

    fun logErr(_ i: Int , err: String) : Report {
        return Report(receiver: allReceivers[i] , address: nil, inputName: nil, findName: nil, avatar: nil, isDapper: nil, type: nftIdentifiers[i], id: ids[i] , message: memos[i] ,receiverLinked: nil , collectionPublicLinked: nil , accountInitialized: nil , nftInPlace: nil, royalties: nil, err: err)
    }

    let paths : [PublicPath] = []
    let contractData : {Type : NFTCatalog.NFTCatalogMetadata} = {}
    let addresses : {String : Address} = {}

    let account = getAuthAccount<auth(BorrowValue) &Account>(sender)
    let report : [Report] = []
    for i , typeIdentifier in nftIdentifiers {
        let checkType = CompositeType(typeIdentifier)
        if checkType == nil {
            report.append(logErr(i, err: "Cannot refer to type with identifier : ".concat(typeIdentifier)))
            continue
        }
        let type = checkType!

        var data : NFTCatalog.NFTCatalogMetadata? = contractData[type]
        if data == nil {
            let checkData = FINDNFTCatalog.getMetadataFromType(type)
            if checkData == nil {
                report.append(logErr(i, err: "NFT Type is not supported by NFT Catalog. Type : ".concat(type.identifier)))
                continue
            }
            contractData[type] = checkData!
            data = checkData!
        }

        let path = data!.collectionData

        let checkCol = account.storage.borrow<&{NonFungibleToken.Collection}>(from: path.storagePath)
        if checkCol == nil {
            report.append(logErr(i, err: "Cannot borrow collection from sender. Type : ".concat(type.identifier)))
            continue
        }
        let owned = checkCol!.getIDs().contains(ids[i])

        let receiver = allReceivers[i]
        let id = ids[i]
        let message = memos[i]

        var user = addresses[receiver]
        if user == nil {
            let checkUser = FIND.resolve(receiver)
            if checkUser == nil {
                report.append(logErr(i, err: "Cannot resolve user with name / address : ".concat(receiver)))
                continue
            }
            addresses[receiver] = checkUser!
            user = checkUser!
        }
        let checkAcct = getAccount(user!)
        if checkAcct.balance == 0.0 {
            report.append(logErr(i, err: "Account is not an activated account"))
            continue
        }


        var isDapper=false
        if let receiver =getAccount(user!).capabilities.borrow<&{FungibleToken.Receiver}>(/public/flowTokenReceiver) {
            isDapper=receiver.isInstance(Type<@TokenForwarding.Forwarder>())
        } else {
            if let duc = getAccount(user!).capabilities.borrow<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver) {
                isDapper = duc.isInstance(Type<@TokenForwarding.Forwarder>())
            }
        }

        // check receiver account storage
        let receiverCap = getAccount(user!).capabilities.get<&{NonFungibleToken.Receiver}>(path.publicPath)
        let collectionPublicCap = getAccount(user!).capabilities.get<&{NonFungibleToken.Collection}>(path.publicPath)
        let storage = getAuthAccount<auth(BorrowValue) &Account>(user!).storage.type(at: path.storagePath)

        var storageInited = false
        if storage != nil && checkSameContract(collection: storage!, nft: type){
            storageInited = true
        }

        var royalties : Royalties? = nil
        let mv = account.storage.borrow<&{ViewResolver.ResolverCollection}>(from: path.storagePath)
        if mv != nil {
            let rv = mv!.borrowViewResolver(id: id)!
            if let r = MetadataViews.getRoyalties(rv) {
                royalties = Royalties(r)
            }
        }

        var inputName : String? = receiver
        var findName : String? = FIND.reverseLookup(user!)
        if FindUtils.hasPrefix(receiver, prefix: "0x") {
            inputName = nil
        }

        var avatar : String? = nil
        if let profile = getAccount(user!).capabilities.borrow<&{Profile.Public}>(Profile.publicPath){
            avatar = profile.getAvatar()
        }

        let rLinked = receiverCap !=nil && receiverCap!.check()
        let cpLinked = collectionPublicCap !=nil && collectionPublicCap!.check()
        let r = Report(receiver: allReceivers[i] , address: user, inputName: inputName, findName: findName, avatar: avatar, isDapper: isDapper, type: nftIdentifiers[i], id: ids[i] , message: memos[i] ,receiverLinked: rLinked , collectionPublicLinked: cpLinked , accountInitialized: storageInited , nftInPlace: owned, royalties:royalties, err: nil)
        report.append(r)
    }

    return report
}


access(all) struct Report {
    access(all) let receiver: String
    access(all) let address: Address?
    access(all) let inputName: String?
    access(all) let findName: String?
    access(all) let avatar: String?
    access(all) let isDapper: Bool?
    access(all) let type: String
    access(all) let id: UInt64
    access(all) let message: String
    access(all) var ok: Bool
    access(all) let receiverLinked: Bool?
    access(all) let collectionPublicLinked: Bool?
    access(all) let accountInitialized: Bool?
    access(all) let nftInPlace: Bool?
    access(all) let royalties: Royalties?
    access(all) let err: String?

    init(receiver: String , address: Address?, inputName: String?, findName: String?, avatar: String?, isDapper: Bool? , type: String, id: UInt64 , message: String ,receiverLinked: Bool? , collectionPublicLinked: Bool? , accountInitialized: Bool? , nftInPlace: Bool?, royalties: Royalties?, err: String?) {
        self.receiver=receiver
        self.address=address
        self.inputName=inputName
        self.findName=findName
        self.avatar=avatar
        self.isDapper=isDapper
        self.type=type
        self.id=id
        self.message=message
        self.receiverLinked=receiverLinked
        self.collectionPublicLinked=collectionPublicLinked
        self.accountInitialized=accountInitialized
        self.nftInPlace=nftInPlace
        self.err=err
        self.royalties=royalties
        self.ok = false
        if accountInitialized == true && nftInPlace == true {
            if receiverLinked == true || collectionPublicLinked == true {
                self.ok = true
            }
        }
    }
}

access(all) struct Royalties {
    access(all) let totalRoyalty: UFix64
    access(all) let royalties: [Royalty]

    init(_ royalties: MetadataViews.Royalties) {
        var totalR = 0.0
        let array : [Royalty] = []
        for r in royalties.getRoyalties() {
            array.append(Royalty(r))
            totalR = totalR + r.cut
        }
        self.totalRoyalty = totalR
        self.royalties = array
    }
}

access(all) struct Royalty {
    access(all) let name: String?
    access(all) let address: Address
    access(all) let cut: UFix64
    access(all) let acceptTypes: [String]
    access(all) let description: String

    init(_ r: MetadataViews.Royalty) {
        self.name = FIND.reverseLookup(r.receiver.address)
        self.address = r.receiver.address
        self.cut = r.cut
        self.description = r.description
        let acceptTypes : [String] = []
        if r.receiver.check() {
            let ref = r.receiver.borrow()!
            let t = ref.getType()
            if t.isInstance(Type<@{FungibleToken.Vault}>()) {
                acceptTypes.append(t.identifier)
            } else if t == Type<@TokenForwarding.Forwarder>() {
                acceptTypes.append(Type<@FlowToken.Vault>().identifier)
            } else if t == Type<@Profile.User>() {
                let ref = getAccount(r.receiver.address).capabilities.borrow<&{Profile.Public}>(Profile.publicPath)!
                let wallets = ref.getWallets()
                for w in wallets {
                    acceptTypes.append(w.accept.identifier)
                }
            }
        }
        self.acceptTypes = acceptTypes
    }
}

access(all) fun checkSameContract(collection: Type, nft: Type) : Bool {
    let colType = collection.identifier
    let croppedCol = colType.slice(from: 0 , upTo : colType.length - "collection".length)
    let nftType = nft.identifier
    let croppedNft = nftType.slice(from: 0 , upTo : nftType.length - "nft".length)
    if croppedCol == croppedNft {
        return true
    }
    return false
}
