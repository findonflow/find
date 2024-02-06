import "FindMarket"
import "FindViews"
import "FindUtils"
import "FIND"
import "MetadataViews"
import "ViewResolver"
import "NonFungibleToken"
import "FINDNFTCatalog"
import "FTRegistry"

access(all) struct NFTDetailReport {
    access(all) let findMarket: {String : FindMarket.SaleItemInformation}
    access(all) let nftDetail: NFTDetail?
    access(all) let allowedListingActions: {String : ListingTypeReport}
    access(all) let dapperAllowedListingActions: {String : ListingTypeReport}
    access(all) let linkedForMarket : Bool?


    init(findMarket:{String : FindMarket.SaleItemInformation},
    nftDetail: NFTDetail?,
    allowedListingActions: {String : ListingTypeReport},
    dapperAllowedListingActions: {String : ListingTypeReport},
    linkedForMarket : Bool?) {
        self.findMarket=findMarket
        self.nftDetail=nftDetail
        self.allowedListingActions=allowedListingActions
        self.dapperAllowedListingActions=dapperAllowedListingActions
        self.linkedForMarket = linkedForMarket
    }
}

access(all) struct ListingTypeReport {
    access(all) let ftAlias: [String]
    access(all) let ftIdentifiers: [String]
    access(all) let listingType: String
    access(all) let status: String
    access(all) let ListingDetails: [ListingRoyalties]

    init(listingType: String, ftAlias: [String], ftIdentifiers: [String],  status: String , ListingDetails: [ListingRoyalties]) {
        self.listingType=listingType
        self.status=status
        self.ListingDetails=ListingDetails
        self.ftAlias=ftAlias
        self.ftIdentifiers=ftIdentifiers
    }
}

access(all) struct NFTDetail {
    access(all) let id: UInt64
    access(all) let uuid: UInt64
    access(all) let name:String
    access(all) let description:String
    access(all) let thumbnail:String
    access(all) let type: String
    access(all) var externalViewURL: String?
    access(all) var rarity:MetadataViews.Rarity?
    access(all) var editions: [MetadataViews.Edition]
    access(all) var serial: UInt64?
    access(all) var traits: [MetadataViews.Trait]
    access(all) var media : {String: String} //url to mediaType
    access(all) var collection : NFTCollectionDisplay?
    access(all) var license : String?
    access(all) var data: {String : AnyStruct?}
    access(all) var soulBounded: Bool
    access(all) var views :[String]

    init(_ pointer: FindViews.ViewReadPointer, views: {String : AnyStruct}, resolvedViews: [Type]){

        self.type=pointer.itemType.identifier
        self.id=pointer.id
        self.uuid=pointer.getUUID()

        // Display
        let display = views["Display"] ?? panic("Could not find display")
        let d = display as! MetadataViews.Display
        self.name=d.name
        self.description=d.description
        self.thumbnail=d.thumbnail.uri()
        views.remove(key: "Display")

        // External URL
        self.externalViewURL = nil
        if let externalURL = views["ExternalURL"] {
            if let e = externalURL as? MetadataViews.ExternalURL {
                self.externalViewURL = e.url
            }
        }
        views.remove(key: "ExternalURL")

        // Edition
        self.editions=[]
        if let editions = views["Editions"] {
            if let e = editions as? MetadataViews.Editions {
                if e.infoList.length > 0 {
                    self.editions=e.infoList
                }
            }
        }
        views.remove(key: "Editions")

        // Serial
        self.serial=nil
        if let serial = views["Serial"] {
            if let s = serial as? MetadataViews.Serial {
                self.serial=s.number
            }
        }
        views.remove(key: "Serial")

        // subCollection
        self.collection=nil
        if let grouping = views["NFTCollectionDisplay"] {
            if let sc = grouping as? MetadataViews.NFTCollectionDisplay {
                self.collection=NFTCollectionDisplay(sc)
            }
        }
        views.remove(key: "NFTCollectionDisplay")

        // Medias
        self.media={}
        if let medias= views["Medias"] {
            if let ms = medias as? MetadataViews.Medias {
                for m in ms.items {
                    let url = m.file.uri()
                    let type = m.mediaType
                    self.media[url] = type
                }
            }
        }
        views.remove(key: "Medias")

        // Rarity
        self.rarity=nil
        if let rarity= views["Rarity"] {
            if let r = rarity as? MetadataViews.Rarity {
                self.rarity = r
            }
        }
        views.remove(key: "Rarity")

        // Traits
        self.traits=[]
        if let traits = views["Traits"] {
            if let t = traits as? MetadataViews.Traits {
                if t.traits.length > 0 {
                    self.traits=t.traits
                }
            }
        }
        views.remove(key: "Traits")

        // License
        self.license= nil
        if let license= views["License"] {
            if let l = license as? MetadataViews.License {
                self.license = l.spdxIdentifier
            }
        }
        views.remove(key: "License")

        self.soulBounded = false
        if let soulBound= views["SoulBound"] {
            self.soulBounded = true
        }
        views.remove(key: "SoulBound")

        self.views=[]

        for view in pointer.getViews() {
            if defaultViews().contains(view) {
                continue
            }
            if resolvedViews.contains(view) {
                continue
            }
            self.views.append(view.identifier)
        }
        self.data=views

    }
}

access(all) struct ListingRoyalties {

    access(all) let ftAlias: String?
    access(all) let ftIdentifier: String
    access(all) let royalties: [Royalties]

    init(ftAlias: String?, ftIdentifier: String, royalties: [Royalties]) {
        self.ftAlias=ftAlias
        self.ftIdentifier=ftIdentifier
        self.royalties=royalties
    }
}

access(all) struct Royalties {

    access(all) let royaltyName: String
    access(all) let address: Address
    access(all) let findName: String?
    access(all) let cut: UFix64

    init(royaltyName: String , address: Address, findName: String?, cut: UFix64) {
        self.royaltyName=royaltyName
        self.address=address
        self.findName=findName
        self.cut=cut
    }
}

access(all) struct NFTCollectionDisplay {
    // Name that should be used when displaying this NFT collection.
    access(all) let name: String

    // Description that should be used to give an overview of this collection.
    access(all) let description: String

    // External link to a URL to view more information about this collection.
    access(all) let externalURL: String

    // Square-sized image to represent this collection.
    access(all) let squareImage: {String : String}

    // Banner-sized image for this collection, recommended to have a size near 1200x630.
    access(all) let bannerImage: {String : String}

    // Social links to reach this collection's social homepages.
    // Possible keys may be "instagram", "twitter", "discord", etc.
    access(all) let socials: {String: String}

    init(
        _ nftCD : MetadataViews.NFTCollectionDisplay
    ) {
        self.name = nftCD.name
        self.description = nftCD.description
        self.externalURL = nftCD.externalURL.url

        let squareImage = {nftCD.squareImage.file.uri() : nftCD.squareImage.mediaType}
        self.squareImage = squareImage

        let bannerImage = {nftCD.bannerImage.file.uri() : nftCD.bannerImage.mediaType}
        self.bannerImage = bannerImage

        let socials : {String : String} = {}
        for key in nftCD.socials.keys{
            socials[key] = nftCD.socials[key]!.url
        }
        self.socials = socials
    }
}

access(all) fun main(user: String, project:String, id: UInt64, views: [String]) : NFTDetailReport?{
    let resolveAddress = FIND.resolve(user)
    if resolveAddress == nil {
        return nil
    }
    let address = resolveAddress!

    let account = getAuthAccount<auth(IssueStorageCapabilityController) &Account>(address)

    if account.balance > 0.0 {
        // check link for market
        let linkedForMarket = account.capabilities.get<&{NonFungibleToken.Collection}>(getPublicPath(project))?.check()

        let storagePath = getStoragePath(project)
        let cap= account.capabilities.storage.issue<&{NonFungibleToken.Collection}>(storagePath)
        let pointer = FindViews.ViewReadPointer(cap: cap, id: id)

        let nftDetail = getNFTDetail(pointer:pointer, views: views)
        if nftDetail == nil {
            return nil
        }

        let findAddress=FindMarket.getFindTenantAddress()
        var findMarket=FindMarket.getNFTListing(tenant:findAddress, address: address, id: nftDetail!.uuid, getNFTInfo:false)

        var report : {String : ListingTypeReport} = {}
        var dapperReport : {String : ListingTypeReport} = {}

        // check if that's soulBound, if yes, the report will be nil
        if !pointer.checkSoulBound() {
            let tenantCap = FindMarket.getTenantCapability(findAddress)!
            let tenantRef = tenantCap.borrow() ?? panic("This tenant is not set up. Tenant : ".concat(tenantCap.address.toString()))

            let marketTypes = FindMarket.getSaleItemTypes()

            for marketType in marketTypes {
                if let allowedListing = tenantRef.getAllowedListings(nftType: pointer.getItemType(), marketType: marketType) {
                    report[FindMarket.getMarketOptionFromType(marketType)] = createListingTypeReport(allowedListing, pointer: pointer, tenantRef: tenantRef, dapper: false)
                    dapperReport[FindMarket.getMarketOptionFromType(marketType)] = createListingTypeReport(allowedListing, pointer: pointer, tenantRef: tenantRef, dapper: true)
                }
            }
        }

        let nftType = pointer.itemType

        return NFTDetailReport(
            findMarket:findMarket,
            nftDetail: nftDetail,
            allowedListingActions: report,
            dapperAllowedListingActions: dapperReport,
            linkedForMarket : linkedForMarket)
        }
        return nil

    }

    access(all) let resolvedAddresses : {Address : String} = {}

    access(all) var nftRoyalties : [Royalties]? = nil

    access(all) fun reverseLookup(_ addr: Address) : String? {

        if let name = resolvedAddresses[addr] {
            if name == "" {
                return nil
            } else {
                return name
            }
        }
        let name = FIND.reverseLookup(addr)
        if name == nil {
            resolvedAddresses[addr] = ""
        } else {
            resolvedAddresses[addr] = name
        }
        return name

    }

    access(all) fun getNFTDetail(pointer: FindViews.ViewReadPointer, views: [String]) : NFTDetail? {

        if !pointer.valid() {
            return nil
        }

        var nftViews: {String : AnyStruct} = {}
        var resolvedViews: [Type] = []
        let viewResolver = pointer.getViewResolver()

        let defaultViews = defaultViews()
        for view in views {
            if let runTimeType = CompositeType(view) {
                if !defaultViews.contains(runTimeType) {
                    defaultViews.append(runTimeType)
                }
            }
        }


        for runTimeType in defaultViews {
            // Resolve arrayed views to ensure we didn't miss any stuff
            if runTimeType == Type<MetadataViews.Editions>() {
                if let editions = MetadataViews.getEditions(viewResolver) {
                    if let edition = getEdition(viewResolver) {
                        var check = false
                        for item in editions.infoList {
                            if item.name == edition.name && item.number == edition.number && item.max == edition.max {
                                check = true
                                break
                            }
                        }
                        // If the edition does not exist in editions, add it in
                        if !check {
                            let array = editions.infoList
                            array.append(edition)
                            nftViews["Editions"] = MetadataViews.Editions(array)
                            resolvedViews.append(runTimeType)
                            continue
                        }
                    }
                    // If edition does not exist OR edition is already in editions , append it to views and continue
                    nftViews["Editions"] = editions
                    resolvedViews.append(runTimeType)
                    continue
                }
            }

            if runTimeType == Type<MetadataViews.Edition>() {
                // If the editions does not exist, check if there is edition, if there is, add it in as editions
                if nftViews["Editions"] == nil {
                    if let edition = getEdition(viewResolver) {
                        nftViews["Editions"] = MetadataViews.Editions([edition])
                        resolvedViews.append(runTimeType)
                    }
                }
                continue
            }

            if runTimeType == Type<MetadataViews.Medias>() {
                if let medias = MetadataViews.getMedias(viewResolver) {
                    if let media = getMedia(viewResolver) {
                        var check = false
                        let uri = media.file.uri()
                        for item in medias.items {
                            if item.file.uri() == uri {
                                check = true
                                break
                            }
                            if !check {
                                let array = medias.items
                                array.append(media)
                                nftViews["Medias"] = MetadataViews.Medias(array)
                                resolvedViews.append(runTimeType)
                                continue
                            }
                        }
                    }
                    nftViews["Medias"] = medias
                    resolvedViews.append(runTimeType)
                    continue
                }
            }

            if runTimeType == Type<MetadataViews.Media>() {
                if nftViews["Medias"] == nil {
                    if let media = getMedia(viewResolver) {
                        nftViews["Medias"] = MetadataViews.Medias([media])
                        resolvedViews.append(runTimeType)
                    }
                }
                continue
            }

            if runTimeType == Type<MetadataViews.Traits>() {
                if let traits = MetadataViews.getTraits(viewResolver) {
                    if let trait = getTrait(viewResolver) {
                        var check = false
                        for item in traits.traits {
                            if item.name == trait.name {
                                check = true
                                break
                            }
                            if !check {
                                let array = traits.traits
                                array.append(trait)

                                nftViews["Traits"] = cleanUpTraits(array)
                                resolvedViews.append(runTimeType)
                                continue
                            }
                        }
                    }
                    nftViews["Traits"] = cleanUpTraits(traits.traits)
                    resolvedViews.append(runTimeType)
                    continue
                }
            }

            if runTimeType == Type<MetadataViews.Trait>() {
                if nftViews["Traits"] == nil {
                    if let trait = getTrait(viewResolver) {
                        nftViews["Traits"] = MetadataViews.Traits([trait])
                        resolvedViews.append(runTimeType)
                    }
                }
                continue
            }

            if let view = pointer.resolveView(runTimeType) {
                let name = FindUtils.splitString(runTimeType.identifier, sep: ".")[3]
                nftViews[name] = view
                resolvedViews.append(runTimeType)
            }
        }

        return NFTDetail(pointer, views: nftViews, resolvedViews: resolvedViews)


    }

    access(all) fun getEdition(_ viewResolver: &{ViewResolver.Resolver}) : MetadataViews.Edition? {
        if let view = viewResolver.resolveView(Type<MetadataViews.Edition>()) {
            if let v = view as? MetadataViews.Edition {
                return v
            }
        }
        return nil
    }

    access(all) fun getMedia(_ viewResolver: &{ViewResolver.Resolver}) : MetadataViews.Media? {
        if let view = viewResolver.resolveView(Type<MetadataViews.Media>()) {
            if let v = view as? MetadataViews.Media {
                return v
            }
        }
        return nil
    }

    access(all) fun getTrait(_ viewResolver: &{ViewResolver.Resolver}) : MetadataViews.Trait? {
        if let view = viewResolver.resolveView(Type<MetadataViews.Trait>()) {
            if let v = view as? MetadataViews.Trait {
                return v
            }
        }
        return nil
    }

    /* Helper Function */
    access(all) fun resolveRoyalties(_ pointer: FindViews.ViewReadPointer) : [Royalties] {
        let array : [Royalties] = []
        for royalty in pointer.getRoyalty().getRoyalties() {
            let address = royalty.receiver.address
            array.append(Royalties(royaltyName: royalty.description, address: address, findName: reverseLookup(address), cut: royalty.cut))
        }

        return array
    }

    access(all) fun resolveMarketplaceRoyalties(tenantRef: &{FindMarket.TenantPublic}, listing: Type, nft: Type, ft: Type) : [Royalties] {

        let cuts = tenantRef.getCuts(name:"", listingType: listing, nftType:nft, ftType:ft)

        let royalties :[Royalties] = []

        for allCuts in cuts.values {
            for cut in allCuts.cuts {
                royalties.append(Royalties(royaltyName: cut.getName(), address: cut.getAddress(), findName: reverseLookup(cut.getAddress()), cut: cut.getCut()))
            }
        }

        return royalties
    }

    access(all) fun createListingTypeReport(_ allowedListing: FindMarket.AllowedListing, pointer: FindViews.ViewReadPointer, tenantRef: &{FindMarket.TenantPublic}, dapper: Bool) : ListingTypeReport? {
        let listingType = allowedListing.listingType.identifier
        var ftAlias : [String] = []
        var ftIdentifier : [String] = []
        var listingDetails : [ListingRoyalties] = []
        for ft in allowedListing.ftTypes {
            var alias : String? = nil
            let ftInfo = FTRegistry.getFTInfo(ft.identifier) ?? panic(ft.identifier.concat(" is not added to FTRegistry yet."))
            switch dapper {
            case true :
                if !ftInfo.tag.contains("dapper") {
                    continue
                }

            case false :
                if ftInfo.tag.contains("dapper") {
                    continue
                }
            }
            alias = ftInfo.alias
            ftAlias.append(ftInfo.alias)
            ftIdentifier.append(ft.identifier)

            // getRoyalties
            var nftR = nftRoyalties
            if nftR == nil {
                nftRoyalties = resolveRoyalties(pointer)
                nftR = nftRoyalties
            }

            let findR = resolveMarketplaceRoyalties(tenantRef: tenantRef, listing: allowedListing.listingType , nft: pointer.getItemType(), ft: ft)
            findR.appendAll(nftR!)

            listingDetails.append(ListingRoyalties(ftAlias: alias, ftIdentifier: ft.identifier, royalties: findR))
        }

        if ftIdentifier.length == 0 {
            return nil
        }

        return ListingTypeReport(listingType: listingType, ftAlias: ftAlias, ftIdentifiers: ftIdentifier,  status: allowedListing.status , ListingDetails: listingDetails)
    }

    access(all) fun defaultViews() : [Type] {
        return [
        Type<MetadataViews.Display>() ,
        Type<MetadataViews.Editions>() ,
        Type<MetadataViews.Edition>() ,
        Type<MetadataViews.Serial>() ,
        Type<MetadataViews.Medias>() ,
        Type<MetadataViews.Media>() ,
        Type<MetadataViews.License>() ,
        Type<MetadataViews.ExternalURL>() ,
        Type<MetadataViews.NFTCollectionDisplay>() ,
        Type<MetadataViews.Traits>() ,
        Type<MetadataViews.Trait>() ,
        Type<MetadataViews.Rarity>(),
        Type<FindViews.SoulBound>()
        ]
    }

    access(all) fun getStoragePath(_ nftIdentifier: String) : StoragePath {
        if let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftIdentifier)?.keys {
            let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])!
            return collection.collectionData.storagePath
        }

        if let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier :nftIdentifier) {
            return collection.collectionData.storagePath
        }
        panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftIdentifier))
    }

    access(all) fun getPublicPath(_ nftIdentifier: String) : PublicPath {
        if let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftIdentifier)?.keys {
            let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])!
            return collection.collectionData.publicPath
        }

        if let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier :nftIdentifier) {
            return collection.collectionData.publicPath
        }
        panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftIdentifier))
    }

    access(all) fun cleanUpTraits(_ traits: [MetadataViews.Trait]) : MetadataViews.Traits {
        let dateValues  = {"Date" : true, "Numeric":false, "Number":false, "date":true, "numeric":false, "number":false}

        let array : [MetadataViews.Trait] = []

        for i , trait in traits {
            let displayType = trait.displayType ?? "string"
            if let isDate = dateValues[displayType] {
                if isDate {
                    array.append(MetadataViews.Trait(name: trait.name, value: trait.value, displayType: "Date", rarity: trait.rarity))
                } else {
                    array.append(MetadataViews.Trait(name: trait.name, value: trait.value, displayType: "Numeric", rarity: trait.rarity))
                }
            } else {
                if let value = trait.value as? Bool {
                    if value {
                        array.append(MetadataViews.Trait(name: trait.name, value: trait.value, displayType: "Bool", rarity: trait.rarity))
                    }else {
                        array.append(MetadataViews.Trait(name: trait.name, value: trait.value, displayType: "Bool", rarity: trait.rarity))
                    }
                } else if let value = trait.value as? String {
                    array.append(MetadataViews.Trait(name: trait.name, value: trait.value, displayType: "String", rarity: trait.rarity))
                } else {
                    array.append(MetadataViews.Trait(name: trait.name, value: trait.value, displayType: "String", rarity: trait.rarity))
                }
            }
        }
        return MetadataViews.Traits(array)
    }
