import "FIND"
import "NonFungibleToken"
import "FungibleToken"
import "Dandy"
import "Profile"
import "ViewResolver"
import "MetadataViews"
import "FindViews"
import "FindForge"

transaction(name: String, maxEdition:UInt64, artist:String, nftName:String, nftDescription:String, nftUrl:String, rarity: String, rarityNum:UFix64, to: Address) {
    prepare(account: auth(BorrowValue) &Account) {

        let dancyReceiver =getAccount(to)
        let collection= dancyReceiver.capabilities.borrow<&{NonFungibleToken.Collection}>(Dandy.CollectionPublicPath)
        if collection==nil  {
            panic("need dandy receicer")
        }
        let finLeases= account.storage.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!
        let forgeType = Dandy.getForgeType()

        let creativeWork=
        FindViews.CreativeWork(artist: artist, name: nftName, description: nftDescription, type:"image")

        let httpFile=MetadataViews.HTTPFile(url:nftUrl)
        let media=MetadataViews.Media(file: httpFile, mediaType: "image/png")

        let rarity = MetadataViews.Rarity(score:rarityNum, max: 100.0, description:rarity)

        let receiver=account.capabilities.get<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)!
        let nftReceiver=getAccount(to).capabilities.borrow<&{NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(Dandy.CollectionPublicPath)?? panic("Cannot borrow reference to Dandy collection.")

        let traits = MetadataViews.Traits([])
        traits.addTrait(MetadataViews.Trait(name: "Color", value: "Pearl", displayType:"String", rarity:nil))
        traits.addTrait(MetadataViews.Trait(name: "Speed", value: 200.0, displayType:"Numeric", rarity:nil))

        var i:UInt64=1

        var minterName="neomotorcycle"
        var lease=finLeases.borrow(minterName)
        if !FindForge.checkMinterPlatform(name: lease.getName(), forgeType: forgeType ) {
            /* set up minterPlatform */
            FindForge.setMinterPlatform(lease: lease, 
            forgeType: forgeType, 
            minterCut: 0.05, 
            description: "Neo Collectibles FIND", 
            externalURL: "https://neomotorcycles.co.uk/index.html", 
            squareImage: "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp", 
            bannerImage: "https://neomotorcycles.co.uk/assets/img/neo-logo-web-dark.png?h=5a4d226197291f5f6370e79a1ee656a1",
            socials: {
                "Twitter" : "https://twitter.com/MotorcyclesNeo" ,
                "Discord" : "https://discord.com/invite/XwSdNydezR"
            })
        }

        while i <= maxEdition {

            let editioned= MetadataViews.Edition(name: "nft", number:i, max:maxEdition)
            let description=creativeWork.description.concat( " edition ").concat(i.toString()).concat( " of ").concat(maxEdition.toString())
            let schemas: [AnyStruct] = [ MetadataViews.Editions([editioned]), creativeWork, rarity, traits, MetadataViews.Medias([media])]

            let mintData = Dandy.DandyInfo(name: "Neo Motorcycle ".concat(i.toString()).concat(" of ").concat(maxEdition.toString()), 
            description: creativeWork.description, 
            thumbnail: media, 
            schemas: schemas, 
            externalUrlPrefix:"https://find.xyz/collection/".concat(name).concat("/dandy"))

            FindForge.mint(lease: lease, forgeType: forgeType, data: mintData, receiver: nftReceiver)

            i=i+1
        }
        i = 1

        minterName="xtingles"
        lease=finLeases.borrow(minterName)
        if !FindForge.checkMinterPlatform(name: lease.getName(), forgeType: forgeType ) {
            /* set up minterPlatform */
            FindForge.setMinterPlatform(lease: lease, 
            forgeType: forgeType, 
            minterCut: 0.05, 
            description: "xtingle FIND", 
            externalURL: "https://xtingles.com/", 
            squareImage: "https://xtingles-strapi-prod.s3.us-east-2.amazonaws.com/copy_of_upcoming_drops_db41fbf287.png",
            bannerImage: "https://xtingles.com/images/main-metaverse.png",
            socials: {
                "Discord" : "https://discord.com/invite/XZDYE6jEuq"
            })
        }

        while i <= maxEdition {
            let editioned= MetadataViews.Edition(name: "nft", number:i, max:maxEdition)
            let artCreativeWork=FindViews.CreativeWork(artist: artist, name: "xtingle ", description: "xtingle_NFT", type:"video")
            let description=artCreativeWork.description.concat( " edition ").concat(i.toString()).concat( " of ").concat(maxEdition.toString())
            let artHttpFile=MetadataViews.HTTPFile(url:"https://nft.blocto.app/xtingles/xBloctopus.mp4")
            let thumbnailFile=MetadataViews.HTTPFile(url:"https://nft.blocto.app/xtingles/preview-xBloctopus.png")
            let artMedia=MetadataViews.Media(file: artHttpFile, mediaType: "video/mp4")
            let thumbnailMedia=MetadataViews.Media(file: thumbnailFile, mediaType: "image/png;display=thumbnail")


            let traits = MetadataViews.Traits([])
            traits.addTrait(MetadataViews.Trait(name: "Author", value: "Xtingels", displayType:"String", rarity:nil))
            traits.addTrait(MetadataViews.Trait(name: "video_length", value: 27.0, displayType:"Numeric", rarity:nil))


            let schemas: [AnyStruct] = [ MetadataViews.Editions([editioned]), artCreativeWork, artMedia, rarity, traits, MetadataViews.Medias([artMedia, thumbnailMedia])]

            let mintData = Dandy.DandyInfo(name: "xtingle ".concat(i.toString()).concat(" of ").concat(maxEdition.toString()), 
            description: artCreativeWork.description,
            thumbnail: thumbnailMedia,
            schemas: schemas, 
            externalUrlPrefix:"https://nft.blocto.app/xtingles/")

            FindForge.mint(lease: lease, forgeType: forgeType, data: mintData, receiver: nftReceiver)
            i=i+1
        }
        i = 1

        minterName="ufcstrike"
        lease=finLeases.borrow(minterName)
        if !FindForge.checkMinterPlatform(name: lease.getName(), forgeType: forgeType ) {
            /* set up minterPlatform */
            FindForge.setMinterPlatform(lease: lease, 
            forgeType: forgeType, 
            minterCut: 0.05, 
            description: "ufc strike FIND", 
            externalURL:  "https://ufcstrike.com/", 
            squareImage: "https://assets.website-files.com/62605ca984796169418ca5dc/628e9bba372af61fcf967e03_round-one-standard-p-1080.png",
            bannerImage: "https://s3.us-east-2.amazonaws.com/giglabs.assets.ufc/4f166ac23e10bb510319e82fe9ed2c7d",
            socials: {
                "Discord" : "https://discord.gg/UFCStrike" , 
                "Twitter" : "https://twitter.com/UFCStrikeNFT"
            })
        }

        while i <= maxEdition {
            let editioned= MetadataViews.Edition(name: "nft", number:i, max:maxEdition)
            let artCreativeWork=FindViews.CreativeWork(artist: artist, name: "ufcstrike ", description: "ufcstrike_NFT", type:"video")
            let description=artCreativeWork.description.concat( " edition ").concat(i.toString()).concat( " of ").concat(maxEdition.toString())
            let artHttpFile=MetadataViews.IPFSFile(cid:"QmdDJUobzSaFfg8PwZZcCB3cPwbZ8pthRf1x6XiR9xwS3U", path:nil)
            let thumbnailHttpFile=MetadataViews.IPFSFile(cid:"QmeDLGnYNyunkTjd23yx36sHviWyR9L2shHshjwe1qBCqR", path:nil)
            let artMedia=MetadataViews.Media(file: artHttpFile, mediaType: "video/mp4")
            let thumbnailMedia=MetadataViews.Media(file: thumbnailHttpFile, mediaType: "image;display=thumbnail")

            let traits = MetadataViews.Traits([])
            traits.addTrait(MetadataViews.Trait(name: "Signature_move", value: "Rare naked choke", displayType:"String", rarity:nil))
            traits.addTrait(MetadataViews.Trait(name: "Reach", value: 120.0, displayType:"Numeric", rarity:nil))


            let schemas: [AnyStruct] = [ MetadataViews.Editions([editioned]), artCreativeWork, artMedia, rarity, traits, MetadataViews.Medias([artMedia, thumbnailMedia])]

            let mintData = Dandy.DandyInfo(name:  "ufcstrike ".concat(i.toString()).concat(" of ").concat(maxEdition.toString()), 
            description: artCreativeWork.description,
            thumbnail: thumbnailMedia,
            schemas: schemas, 
            externalUrlPrefix:"https://www.ufcstrike.com")

            FindForge.mint(lease: lease, forgeType: forgeType, data: mintData, receiver: nftReceiver)
            i=i+1
        }
        i = 1

        minterName="jambb"
        lease=finLeases.borrow(minterName)
        if !FindForge.checkMinterPlatform(name: lease.getName(), forgeType: forgeType ) {
            /* set up minterPlatform */
            FindForge.setMinterPlatform(lease: lease, 
            forgeType: forgeType, 
            minterCut: 0.05, 
            description: "jambb FIND", 
            externalURL:  "https://www.jambb.com/", 
            squareImage: "https://prod-jambb-issuance-static-public.s3.amazonaws.com/issuance-ui/logos/jambb-full-color-wordmark-inverted.svg",
            bannerImage: "https://s3.amazonaws.com/jambb-prod-issuance-ui-static-assets/avatars/b76cdd34-e728-4e71-a0ed-c277a628654a/jambb-logo-3d-hp-hero-07.png",
            socials: {
                "Discord" : "https://discord.gg/VWWfaEP8CA" , 
                "Twitter" : "https://twitter.com/JambbApp"
            })
        }

        while i <= maxEdition {
            let editioned= MetadataViews.Edition(name: "nft", number:i, max:maxEdition)
            let artCreativeWork=FindViews.CreativeWork(artist: artist, name: "jambb ", description: "jambb_NFT", type:"video")
            let description=artCreativeWork.description.concat( " edition ").concat(i.toString()).concat( " of ").concat(maxEdition.toString())
            let artHttpFile=MetadataViews.IPFSFile(cid:"QmVoKN72cEyQ87FkphUxuc2jMnsNUSB5zoSxEitGLBypPr", path:nil)
            let thumbnailHttpFile=MetadataViews.HTTPFile(url:"https://content-images.jambb.com/card-front/29849042-6fc8-4f13-8fa8-6a09501c6ea8.jpg")
            let artMedia=MetadataViews.Media(file: artHttpFile, mediaType: "video/mp4")
            let thumbnailMedia=MetadataViews.Media(file: thumbnailHttpFile, mediaType: "image/jpg;display=thumbnail")


            let traits = MetadataViews.Traits([])
            traits.addTrait(MetadataViews.Trait(name: "Author", value: "Jack Black", displayType:"String", rarity:nil))
            traits.addTrait(MetadataViews.Trait(name: "video_length", value: 45.0, displayType:"Numeric", rarity:nil))


            let schemas: [AnyStruct] = [ MetadataViews.Editions([editioned]), artCreativeWork, artMedia, rarity, traits, MetadataViews.Medias([artMedia, thumbnailMedia])]

            let mintData = Dandy.DandyInfo(name:"jambb ".concat(i.toString()).concat(" of ").concat(maxEdition.toString()), 
            description: artCreativeWork.description,
            thumbnail: thumbnailMedia,
            schemas: schemas, 
            externalUrlPrefix:"https://www.jambb.com")

            FindForge.mint(lease: lease, forgeType: forgeType, data: mintData, receiver: nftReceiver)
            i=i+1
        }
        i = 1

        minterName="goatedgoats"
        lease=finLeases.borrow(minterName)
        if !FindForge.checkMinterPlatform(name: lease.getName(), forgeType: forgeType ) {
            /* set up minterPlatform */
            FindForge.setMinterPlatform(lease: lease, 
            forgeType: forgeType, 
            minterCut: 0.05, 
            description: "goatedgoats FIND",
            externalURL: "https://goatedgoats.com/", 
            squareImage: "https://goatedgoats.com/_next/image?url=%2FLogo.png&w=64&q=75", 
            bannerImage: "",
            socials: {
                "Discord" : "https://discord.com/invite/goatedgoats"
            })
        }

        while i <= maxEdition {
            let editioned= MetadataViews.Edition(name: "nft", number:i, max:maxEdition)
            let artCreativeWork=FindViews.CreativeWork(artist: artist, name: "goatedgoats ", description: "goatedgoats_NFT", type:"image")
            let description=artCreativeWork.description.concat( " edition ").concat(i.toString()).concat( " of ").concat(maxEdition.toString())
            let artHttpFile=MetadataViews.IPFSFile(cid:"QmSj3vVwPPzq4UxUnrR7HvUCCFDJGvwBV2ShP7ycTtD73a", path:nil)
            let artMedia=MetadataViews.Media(file: artHttpFile, mediaType: "image")

            let traits = MetadataViews.Traits([])
            traits.addTrait(MetadataViews.Trait(name: "Color", value: "Black", displayType:"String", rarity:nil))
            traits.addTrait(MetadataViews.Trait(name: "trait-slots", value: 5.0, displayType:"Numeric", rarity:nil))


            let schemas: [AnyStruct] = [ MetadataViews.Editions([editioned]), artCreativeWork, artMedia, rarity, traits, MetadataViews.Medias([artMedia])]

            let mintData = Dandy.DandyInfo(name:"goatedgoats ".concat(i.toString()).concat(" of ").concat(maxEdition.toString()), 
            description: artCreativeWork.description,
            thumbnail: artMedia,
            schemas: schemas, 
            externalUrlPrefix:"https://goatedgoats.com/")

            FindForge.mint(lease: lease, forgeType: forgeType, data: mintData, receiver: nftReceiver)
            i=i+1
        }	
        i = 1

        minterName="klktn"
        lease=finLeases.borrow(minterName)
        if !FindForge.checkMinterPlatform(name: lease.getName(), forgeType: forgeType ) {
            /* set up minterPlatform */
            FindForge.setMinterPlatform(lease: lease, 
            forgeType: forgeType, 
            minterCut: 0.05, 
            description: "klktn FIND",
            externalURL: "https://klktn.com/", 
            squareImage: "", 
            bannerImage: "",
            socials: {
                "Twitter" : "https://twitter.com/KlktNofficial" ,
                "Twitter" : "https://discord.gg/wDc8yEcbeD"
            })
        }

        while i <= maxEdition {
            let editioned= MetadataViews.Edition(name: "nft", number:i, max:maxEdition)
            let artCreativeWork=FindViews.CreativeWork(artist: artist, name: "klktn ", description: "klktn_NFT", type:"video")
            let description=artCreativeWork.description.concat( " edition ").concat(i.toString()).concat( " of ").concat(maxEdition.toString())
            let artHttpFile=MetadataViews.HTTPFile(url:"https://ipfs.io/ipfs/bafybeif3banecjnrz7afp54tb332f3zzigzbdcgmjk3k3dwp4iqlrwsbju/73ceab33cf76c2cf48a9a587119c87d21d4ec92b5748e743113c4ce8a1568b53.mp4")
            let artMedia=MetadataViews.Media(file: artHttpFile, mediaType: "video/mp4")
            let thumbnailMedia=MetadataViews.Media(file: MetadataViews.HTTPFile(url:"https://helloeddi.files.wordpress.com/2020/11/kevin1.jpg?w=982&h=1360?w=650"), mediaType: "image/jpeg")


            let traits = MetadataViews.Traits([])
            traits.addTrait(MetadataViews.Trait(name: "Author", value: "Kevin Woo", displayType:"String", rarity:nil))
            traits.addTrait(MetadataViews.Trait(name: "id", value: 0.0, displayType:"Numeric", rarity:nil))


            let schemas: [AnyStruct] = [ MetadataViews.Editions([editioned]), artCreativeWork, artMedia, rarity, traits, MetadataViews.Medias([artMedia])]

            let mintData = Dandy.DandyInfo(name:"klktn ".concat(i.toString()).concat(" of ").concat(maxEdition.toString()), 
            description: artCreativeWork.description,
            thumbnail: thumbnailMedia,
            schemas: schemas, 
            externalUrlPrefix:"https://klktn.com/")

            FindForge.mint(lease: lease, forgeType: forgeType, data: mintData, receiver: nftReceiver)
            i=i+1
        }	
        i = 1

    }
}
