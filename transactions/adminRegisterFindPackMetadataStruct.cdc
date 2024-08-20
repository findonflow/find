import "NonFungibleToken"
import "MetadataViews"
import "FINDNFTCatalog"
import "FungibleToken"
import "FindPack"
import "FindVerifier"
import "FindForge"
import "Admin"
import "Debug"
import "ViewResolver"

// this is a simple tx to update the metadata of a given type of NeoVoucher

transaction(info: FindPack.PackRegisterInfo) {

    let admin: auth(Admin.Owner) &Admin.AdminProxy
    let wallet: Capability<&{FungibleToken.Receiver}>
    let providerCaps : {Type : Capability<auth (NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>}
    let types : [Type]

    prepare(account: auth(Storage, IssueStorageCapabilityController, NonFungibleToken.Withdraw) &Account) {
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

            let storagePathIdentifer = collectionInfo.storagePath.toString().split(separator:"/")[1]
            let providerIdentifier = storagePathIdentifer.concat("Provider")
            let providerStoragePath = StoragePath(identifier: providerIdentifier)!

            //if this stores anything but this it will panic, why does it not return nil?
            var existingProvider= account.storage.copy<Capability<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>>(from: providerStoragePath) 
            if existingProvider==nil {
                existingProvider=account.capabilities.storage.issue<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>(collectionInfo.storagePath)
                //we save it to storage to memoize it
                account.storage.save(existingProvider!, to: providerStoragePath)
                log("create new cap")
            }
            var providerCap = existingProvider!

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
