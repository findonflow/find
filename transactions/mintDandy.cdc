
import "FIND"
import "NonFungibleToken"
import "FungibleToken"
import "Dandy"
import "Profile"
import "MetadataViews"
import "ViewResolver"
import "FindViews"
import "FindForge"

transaction(name: String, maxEdition:UInt64, artist:String, nftName:String, nftDescription:String, nftUrl:String, collectionDescription: String, collectionExternalURL: String, collectionSquareImage: String, collectionBannerImage: String) {
    prepare(account: auth(BorrowValue, SaveValue, PublishCapability, IssueStorageCapabilityController) &Account) {


        let dandyCap= account.capabilities.get<&{NonFungibleToken.Collection}>(Dandy.CollectionPublicPath)
        if !dandyCap.check() {
            account.storage.save(<- Dandy.createEmptyCollection(nftType:Type<@Dandy.NFT>()), to: Dandy.CollectionStoragePath)
            let cap = account.capabilities.storage.issue<&Dandy.Collection>(Dandy.CollectionStoragePath)
            account.capabilities.publish(cap, at: Dandy.CollectionPublicPath)
        }

        let finLeases= account.storage.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!
        let lease=finLeases.borrow(name)
        let forgeType = Dandy.getForgeType()
        if !FindForge.checkMinterPlatform(name: lease.getName(), forgeType: forgeType ) {
            /* set up minterPlatform */
            FindForge.setMinterPlatform(lease: lease, 
            forgeType: forgeType, 
            minterCut: 0.05, 
            description: collectionDescription, 
            externalURL: collectionExternalURL, 
            squareImage: collectionSquareImage, 
            bannerImage: collectionBannerImage, 
            socials: {
                "Twitter" : "https://twitter.com/home" ,
                "Discord" : "discord.gg/"
            })
        }

        let creativeWork=
        FindViews.CreativeWork(artist: artist, name: nftName, description: nftDescription, type:"image")

        let httpFile=MetadataViews.HTTPFile(url:nftUrl)
        let media=MetadataViews.Media(file: httpFile, mediaType: "image/png")

        let receiver=account.capabilities.get<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
        let nftReceiver=account.capabilities.borrow<&{NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(Dandy.CollectionPublicPath) ?? panic("Cannot borrow reference to Dandy collection.")

        let traits = MetadataViews.Traits([])
        traits.addTrait(MetadataViews.Trait(name: "NeoMotorCycleTag", value: "Tag1", displayType:"String", rarity:nil))
        traits.addTrait(MetadataViews.Trait(name: "Speed", value: 100.0, displayType:"Numeric", rarity:nil))
        traits.addTrait(MetadataViews.Trait(name: "Birthday", value: 1660145023.0, displayType:"Date", rarity:nil))

        let collection=dandyCap.borrow()!
        var i:UInt64=1

        while i <= maxEdition {

            let editioned= MetadataViews.Edition(name: nil, number:i, max:maxEdition)
            let set= MetadataViews.Edition(name: "set", number:i, max:maxEdition)
            let editions = MetadataViews.Editions([editioned, set])
            let description=creativeWork.description.concat( " edition ").concat(i.toString()).concat( " of ").concat(maxEdition.toString())
            let schemas: [AnyStruct] = [ editions, creativeWork, MetadataViews.Medias([media]), traits ]

            let mintData = Dandy.DandyInfo(name: "Neo Motorcycle ".concat(i.toString()).concat(" of ").concat(maxEdition.toString()), 
            description: creativeWork.description, 
            thumbnail: media, 
            schemas: schemas, 
            externalUrlPrefix:"https://find.xyz/collection/".concat(name).concat("/dandy"))

            FindForge.mint(lease: lease, forgeType: forgeType, data: mintData, receiver: nftReceiver)

            i=i+1
        }

    }
}
