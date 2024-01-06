import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FindPack from "../contracts/FindPack.cdc"
import FindVerifier from "../contracts/FindVerifier.cdc"
import FindForge from "../contracts/FindForge.cdc"
import Admin from "../contracts/Admin.cdc"
import Debug from "../contracts/Debug.cdc"
import ViewResolver from "../contracts/standard/ViewResolver.cdc"

// this is a simple tx to update the metadata of a given type of NeoVoucher

transaction(info: FindPack.PackRegisterInfo) {

    let admin: auth(Admin.Owner) &Admin.AdminProxy
    let wallet: Capability<&{FungibleToken.Receiver}>
    let providerCaps : {Type : Capability<auth (NonFungibleToken.Withdrawable) &{NonFungibleToken.Collection}>}
    let types : [Type]

    prepare(account: auth(BorrowValue, IssueStorageCapabilityController, NonFungibleToken.Withdrawable) &Account) {
        self.admin =account.storage.borrow<auth(Admin.Owner) &Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Could not borrow admin")
        self.wallet = getAccount(info.paymentAddress).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!

        //for each tier you need a providerAddress and path
        self.providerCaps = {}
        self.types = []
        for typeName in info.nftTypes {
            let collection = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: typeName)
            if collection == nil || collection!.length == 0 {
                panic("Type : ".concat(typeName).concat(" is not supported in NFTCatalog at the moment"))
            }
            let collectionInfo = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collection!.keys[0])!.collectionData

            let providerCap = account.capabilities.storage.issue<auth(NonFungibleToken.Withdrawable) &{NonFungibleToken.Collection}>(collectionInfo.storagePath)
            if !providerCap.check() {
                panic("provider cap for user ".concat(account.address.toString()).concat(" and path ").concat(collectionInfo.storagePath.toString()).concat(" is not setup correctly"))
            }
            let type = CompositeType(typeName)!
            self.types.append(type)
            self.providerCaps[type] = providerCap
        }
    }

    execute {

        let forgeType = Type<@FindPack.Forge>()

        let minterPlatform = FindForge.getMinterPlatform(name: info.forge, forgeType: forgeType)
        if minterPlatform == nil {
            panic("Please set up minter platform for name : ".concat(info.forge).concat( " with this forge type : ").concat(forgeType.identifier))
        }

        let socialMap : {String : MetadataViews.ExternalURL} = {}
        for key in info.socials.keys {
            socialMap[key] = MetadataViews.ExternalURL(info.socials[key]!)
        }

        let collectionDisplay = MetadataViews.NFTCollectionDisplay(
            name: info.name,
            description: info.description,
            externalURL: MetadataViews.ExternalURL(info.externalURL),
            squareImage: MetadataViews.Media(file: MetadataViews.IPFSFile(cid: info.squareImageHash, path:nil), mediaType: "image"),
            bannerImage: MetadataViews.Media(file: MetadataViews.IPFSFile(cid: info.bannerHash, path:nil), mediaType: "image"),
            socials: socialMap
        )

        var saleInfo : [FindPack.SaleInfo] = []
        for key in info.saleInfo {
            saleInfo.append(key.generateSaleInfo())
        }

        let royaltyItems : [MetadataViews.Royalty] = []
        for i, r in info.primaryRoyalty {
            let wallet = getAccount(r.recipient).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!
            royaltyItems.append(MetadataViews.Royalty(receiver: wallet, cut: r.cut, description: r.description))
        }

        let primaryRoyalties = MetadataViews.Royalties(royaltyItems)

        let secondaryRoyaltyItems : [MetadataViews.Royalty] = []
        for i, r in info.secondaryRoyalty {
            let wallet = getAccount(r.recipient).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!
            secondaryRoyaltyItems.append(MetadataViews.Royalty(receiver: wallet, cut: r.cut, description: r.description))
        }

        let secondaryRoyalty = MetadataViews.Royalties(secondaryRoyaltyItems)

        let metadata = FindPack.Metadata(
            name: info.name,
            description: info.description,
            thumbnailUrl: nil,
            thumbnailHash: info.squareImageHash,
            wallet: self.wallet,
            openTime: info.openTime,
            walletType: CompositeType(info.paymentType)!,
            itemTypes: self.types,
            providerCaps: self.providerCaps,
            requiresReservation: info.requiresReservation,
            storageRequirement: info.storageRequirement,
            saleInfos: saleInfo,
            primarySaleRoyalties: primaryRoyalties,
            royalties: secondaryRoyalty,
            collectionDisplay: collectionDisplay,
            packFields: info.packFields,
            extraData: {}
        )

        let input : {UInt64 : FindPack.Metadata} = {info.typeId : metadata}

        self.admin.addForgeContractData(lease: info.forge, forgeType: Type<@FindPack.Forge>() , data: input)
    }
}
