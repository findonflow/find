
import FIND from "../contracts/FIND.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import Dandy from "../contracts/Dandy.cdc"
import Profile from "../contracts/Profile.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import FindForge from "../contracts/FindForge.cdc"

transaction(name: String, maxEdition:UInt64, artist:String, nftName:String, nftDescription:String, nftUrl:String, rarity: String, rarityNum:UFix64, to: Address) {
	prepare(account: AuthAccount) {

		let dancyReceiver =getAccount(to)
		let dandyCap= dancyReceiver.getCapability<&{NonFungibleToken.CollectionPublic}>(Dandy.CollectionPublicPath)
		if !dandyCap.check() {
			panic("need dandy receicer")
		}
		let finLeases= account.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!
		let mintFN = Dandy.mintFN()
		let nftType = Type<@Dandy.NFT>()

		let creativeWork=
		FindViews.CreativeWork(artist: artist, name: nftName, description: nftDescription, type:"image")

		let httpFile=MetadataViews.HTTPFile(url:nftUrl)
		let media=MetadataViews.Media(file: httpFile, mediaType: "image/png")

		let rarity = FindViews.Rarity(rarity: rarityNum, rarityName:rarity, parts: {})

		let receiver=account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
		let minterRoyalty=MetadataViews.Royalties(cutInfos:[MetadataViews.Royalty(receiver: receiver, cut: 0.05, description: "artist")])

		let tag=FindViews.Tag({"NeoMotorCycleTag":"Tag1"})
		let scalar=FindViews.Scalar({"Speed" : 100.0})

		let collection=dandyCap.borrow()!
		var i:UInt64=1

		var minterName="neomotorcycle"
		var lease=finLeases.borrow(minterName)
		if !FindForge.checkMinterPlatform(name: lease.getName(), nftType: nftType ) {
			/* set up minterPlatform */
			FindForge.setMinterPlatform(lease: lease, 
										nftType: Type<@Dandy.NFT>(), 
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
			let schemas: [AnyStruct] = [ MetadataViews.Editions([editioned]), creativeWork, minterRoyalty, rarity, tag, scalar, FindViews.Medias([media])]
			
			let mintData = Dandy.DandyInfo(name: "Neo Motorcycle ".concat(i.toString()).concat(" of ").concat(maxEdition.toString()), 
								description: creativeWork.description, 
								thumbnail: media, 
								schemas: schemas, 
								externalUrlPrefix:"https://find.xyz/collection/".concat(name).concat("/dandy"))
			
			let token <- FindForge.mint(lease: lease, nftType: nftType, data: mintData, mintFN: mintFN)
			
			collection.deposit(token: <- token)
			i=i+1
		}
		i = 1

		minterName="xtingles"
		lease=finLeases.borrow(minterName)
		if !FindForge.checkMinterPlatform(name: lease.getName(), nftType: nftType ) {
			/* set up minterPlatform */
			FindForge.setMinterPlatform(lease: lease, 
										nftType: Type<@Dandy.NFT>(), 
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
			let artTag=FindViews.Tag({"xtingle Tag":"Tag1"})
			let artScalar=FindViews.Scalar({"video length" : 27.0})
			let schemas: [AnyStruct] = [ MetadataViews.Editions([editioned]), artCreativeWork, artMedia, minterRoyalty, rarity, artTag, artScalar, FindViews.Medias([artMedia, thumbnailMedia])]
			
			let mintData = Dandy.DandyInfo(name: "xtingle ".concat(i.toString()).concat(" of ").concat(maxEdition.toString()), 
								description: artCreativeWork.description,
								thumbnail: thumbnailMedia,
								schemas: schemas, 
								externalUrlPrefix:"https://nft.blocto.app/xtingles/")
			
			let token <- FindForge.mint(lease: lease, nftType: nftType, data: mintData, mintFN: mintFN)
			collection.deposit(token: <- token)
			i=i+1
		}
		i = 1

		minterName="flovatar"
		lease=finLeases.borrow(minterName)
		if !FindForge.checkMinterPlatform(name: lease.getName(), nftType: nftType ) {
			/* set up minterPlatform */
			FindForge.setMinterPlatform(lease: lease, 
										nftType: Type<@Dandy.NFT>(), 
										minterCut: 0.05, 
										description: "flovatar FIND", 
										externalURL: "https://flovatar.com/", 
										squareImage: "https://miro.medium.com/max/1080/1*nD3N5BvxvH-wgLW1KPizoA.png",
										bannerImage: "https://miro.medium.com/max/1400/1*WjFBUweGaThcTR-UOZ6TnA.gif",
										socials: {
											"Discord" : "https://discord.gg/flovatar" , 
											"Twitter" : "https://twitter.com/flovatar"
										})

		while i <= maxEdition {
			let editioned= MetadataViews.Edition(name: "nft", number:i, max:maxEdition)
			let artCreativeWork=FindViews.CreativeWork(artist: artist, name: "flovatar ", description: "flovatar_NFT", type:"image")
			let description=artCreativeWork.description.concat( " edition ").concat(i.toString()).concat( " of ").concat(maxEdition.toString())
			let artHttpFile=MetadataViews.HTTPFile(url:"https://flovatar.com/api/image/166")
			let artMedia=MetadataViews.Media(file: artHttpFile, mediaType: "image/svg")
			let artTag=FindViews.Tag({"flovatar Tag":"Tag1"})
			let artScalar=FindViews.Scalar({"rarity score" : 2.2, "id" : 166.0})
			let schemas: [AnyStruct] = [ MetadataViews.Editions([editioned]), artCreativeWork, artMedia, minterRoyalty, rarity, artTag, artScalar, FindViews.Medias([artMedia])]
			
			let mintData = Dandy.DandyInfo(name: "flovatar ".concat(i.toString()).concat(" of ").concat(maxEdition.toString()), 
								description: artCreativeWork.description,
								thumbnail: artMedia,
								schemas: schemas, 
								externalUrlPrefix:"https://flovatar.com/flovatars/166/0x886f3aeaf848c535")
			
			let token <- FindForge.mint(lease: lease, nftType: nftType, data: mintData, mintFN: mintFN)
			
			collection.deposit(token: <- token)
			i=i+1
		}
		i = 1

		minterName="ufcstrike"
		lease=finLeases.borrow(minterName)
		if !FindForge.checkMinterPlatform(name: lease.getName(), nftType: nftType ) {
			/* set up minterPlatform */
			FindForge.setMinterPlatform(lease: lease, 
										nftType: Type<@Dandy.NFT>(), 
										minterCut: 0.05, 
										description: "ufc strike FIND", 
										externalURL:  "https://ufcstrike.com/", 
										squareImage: "https://assets.website-files.com/62605ca984796169418ca5dc/628e9bba372af61fcf967e03_round-one-standard-p-1080.png",
										bannerImage: "https://s3.us-east-2.amazonaws.com/giglabs.assets.ufc/4f166ac23e10bb510319e82fe9ed2c7d",
										socials: {
											"Discord" : "https://discord.gg/UFCStrike" , 
											"Twitter" : "https://twitter.com/UFCStrikeNFT"
										})

		while i <= maxEdition {
			let editioned= MetadataViews.Edition(name: "nft", number:i, max:maxEdition)
			let artCreativeWork=FindViews.CreativeWork(artist: artist, name: "ufcstrike ", description: "ufcstrike_NFT", type:"video")
			let description=artCreativeWork.description.concat( " edition ").concat(i.toString()).concat( " of ").concat(maxEdition.toString())
			let artHttpFile=MetadataViews.IPFSFile(cid:"QmdDJUobzSaFfg8PwZZcCB3cPwbZ8pthRf1x6XiR9xwS3U", path:nil)
			let thumbnailHttpFile=MetadataViews.IPFSFile(cid:"QmeDLGnYNyunkTjd23yx36sHviWyR9L2shHshjwe1qBCqR", path:nil)
			let artMedia=MetadataViews.Media(file: artHttpFile, mediaType: "video/mp4")
			let thumbnailMedia=MetadataViews.Media(file: thumbnailHttpFile, mediaType: "image;display=thumbnail")
			let artTag=FindViews.Tag({"ufcstrike Tag":"Tag1"})
			let artScalar=FindViews.Scalar({"rank" : 295.0})
			let schemas: [AnyStruct] = [ MetadataViews.Editions([editioned]), artCreativeWork, artMedia, minterRoyalty, rarity, artTag, artScalar, FindViews.Medias([artMedia, thumbnailMedia])]
			
			let mintData = Dandy.DandyInfo(name:  "ufcstrike ".concat(i.toString()).concat(" of ").concat(maxEdition.toString()), 
								description: artCreativeWork.description,
								thumbnail: thumbnailMedia,
								schemas: schemas, 
								externalUrlPrefix:"https://www.ufcstrike.com")
			
			let token <- FindForge.mint(lease: lease, nftType: nftType, data: mintData, mintFN: mintFN)
			
			collection.deposit(token: <- token)
			i=i+1
		}
		i = 1

		finLeases.addForgeMinter(name:"jambb", forgeMinterType: forgeType, description: "jambb FIND", externalURL: "https://www.jambb.com/", squareImage: "https://prod-jambb-issuance-static-public.s3.amazonaws.com/issuance-ui/logos/jambb-full-color-wordmark-inverted.svg", bannerImage: "https://s3.amazonaws.com/jambb-prod-issuance-ui-static-assets/avatars/b76cdd34-e728-4e71-a0ed-c277a628654a/jambb-logo-3d-hp-hero-07.png")

		minterName="jambb"
		lease=finLeases.borrow(minterName)
		if !FindForge.checkMinterPlatform(name: lease.getName(), nftType: nftType ) {
			/* set up minterPlatform */
			FindForge.setMinterPlatform(lease: lease, 
										nftType: Type<@Dandy.NFT>(), 
										minterCut: 0.05, 
										description: "jambb FIND", 
										externalURL:  "https://www.jambb.com/", 
										squareImage: "https://prod-jambb-issuance-static-public.s3.amazonaws.com/issuance-ui/logos/jambb-full-color-wordmark-inverted.svg",
										bannerImage: "https://s3.amazonaws.com/jambb-prod-issuance-ui-static-assets/avatars/b76cdd34-e728-4e71-a0ed-c277a628654a/jambb-logo-3d-hp-hero-07.png",
										socials: {
											"Discord" : "https://discord.gg/VWWfaEP8CA" , 
											"Twitter" : "https://twitter.com/JambbApp"
										})

		while i <= maxEdition {
			let editioned= MetadataViews.Edition(name: "nft", number:i, max:maxEdition)
			let artCreativeWork=FindViews.CreativeWork(artist: artist, name: "jambb ", description: "jambb_NFT", type:"video")
			let description=artCreativeWork.description.concat( " edition ").concat(i.toString()).concat( " of ").concat(maxEdition.toString())
			let artHttpFile=MetadataViews.IPFSFile(cid:"QmVoKN72cEyQ87FkphUxuc2jMnsNUSB5zoSxEitGLBypPr", path:nil)
			let thumbnailHttpFile=MetadataViews.HTTPFile(url:"https://content-images.jambb.com/card-front/29849042-6fc8-4f13-8fa8-6a09501c6ea8.jpg")
			let artMedia=MetadataViews.Media(file: artHttpFile, mediaType: "video/mp4")
			let thumbnailMedia=MetadataViews.Media(file: thumbnailHttpFile, mediaType: "image/jpg;display=thumbnail")
			let artTag=FindViews.Tag({"jambb Tag":"Tag1"})
			let artScalar=FindViews.Scalar({"video length" : 45.0})
			let schemas: [AnyStruct] = [ MetadataViews.Editions([editioned]), artCreativeWork, artMedia, minterRoyalty, rarity, artTag, artScalar, FindViews.Medias([artMedia, thumbnailMedia])]
			
			let mintData = Dandy.DandyInfo(name:"jambb ".concat(i.toString()).concat(" of ").concat(maxEdition.toString()), 
								description: artCreativeWork.description,
								thumbnail: thumbnailMedia,
								schemas: schemas, 
								externalUrlPrefix:"https://www.ufcstrike.com")
			
			let token <- FindForge.mint(lease: lease, nftType: nftType, data: mintData, mintFN: mintFN)
			
			collection.deposit(token: <- token)
			i=i+1
		}
		i = 1
	
		finLeases.addForgeMinter(name:"bitku", forgeMinterType: forgeType, description: "bitku FIND", externalURL: "https://bitku.art/", squareImage: "", bannerImage: "")

		minterName="bitku"
		lease=finLeases.borrow(minterName)
		if !FindForge.checkMinterPlatform(name: lease.getName(), nftType: nftType ) {
			/* set up minterPlatform */
			FindForge.setMinterPlatform(lease: lease, 
										nftType: Type<@Dandy.NFT>(), 
										minterCut: 0.05, 
										description: "bitku FIND",
										externalURL: "https://bitku.art/",
										squareImage: "",
										bannerImage: "",
										socials: {
											"Github" : "https://github.com/docmarionum1/bitku#readme"
										})

		while i <= maxEdition {
			let editioned= MetadataViews.Edition(name: "nft", number:i, max:maxEdition)
			let artCreativeWork=FindViews.CreativeWork(artist: artist, name: "bitku ", description: "bitku_NFT", type:"text")
			let description=artCreativeWork.description.concat( " edition ").concat(i.toString()).concat( " of ").concat(maxEdition.toString())
			let artHttpFile=FindViews.OnChainFile(content:"No one\nOf the year I hope it's on\nFor work", mediaType: "text/plain")
			let artMedia=MetadataViews.Media(file: artHttpFile, mediaType: "text/plain")
			let artTag=FindViews.Tag({"bitku Tag":"Tag1"})
			let artScalar=FindViews.Scalar({"rank" : 0.0})
			let schemas: [AnyStruct] = [ MetadataViews.Editions([editioned]), artCreativeWork, artMedia, minterRoyalty, rarity, artTag, artScalar, FindViews.Medias([artMedia])]
			
			let mintData = Dandy.DandyInfo(name:"bitku ".concat(i.toString()).concat(" of ").concat(maxEdition.toString()), 
								description: artCreativeWork.description,
								thumbnail: artMedia,
								schemas: schemas, 
								externalUrlPrefix:"https://bitku.art/#0x886f3aeaf848c535/188")
			
			let token <- FindForge.mint(lease: lease, nftType: nftType, data: mintData, mintFN: mintFN)
			
			collection.deposit(token: <- token)
			i=i+1
		}
		i = 1

		minterName="goatedgoats"
		lease=finLeases.borrow(minterName)
		if !FindForge.checkMinterPlatform(name: lease.getName(), nftType: nftType ) {
			/* set up minterPlatform */
			FindForge.setMinterPlatform(lease: lease, 
										nftType: Type<@Dandy.NFT>(), 
										minterCut: 0.05, 
										description: "goatedgoats FIND",
										externalURL: "https://goatedgoats.com/", 
										squareImage: "https://goatedgoats.com/_next/image?url=%2FLogo.png&w=64&q=75", 
										bannerImage: "",
										socials: {
											"Discord" : "https://discord.com/invite/goatedgoats"
										})

		while i <= maxEdition {
			let editioned= MetadataViews.Edition(name: "nft", number:i, max:maxEdition)
			let artCreativeWork=FindViews.CreativeWork(artist: artist, name: "goatedgoats ", description: "goatedgoats_NFT", type:"image")
			let description=artCreativeWork.description.concat( " edition ").concat(i.toString()).concat( " of ").concat(maxEdition.toString())
			let artHttpFile=MetadataViews.IPFSFile(cid:"QmSj3vVwPPzq4UxUnrR7HvUCCFDJGvwBV2ShP7ycTtD73a", path:nil)
			let artMedia=MetadataViews.Media(file: artHttpFile, mediaType: "image")
			let artTag=FindViews.Tag({"goatedgoats Tag":"Tag1"})
			let artScalar=FindViews.Scalar({"id" : 2389.0})
			let schemas: [AnyStruct] = [ MetadataViews.Editions([editioned]), artCreativeWork, artMedia, minterRoyalty, rarity, artTag, artScalar, FindViews.Medias([artMedia])]
			
			let mintData = Dandy.DandyInfo(name:"goatedgoats ".concat(i.toString()).concat(" of ").concat(maxEdition.toString()), 
								description: artCreativeWork.description,
								thumbnail: artMedia,
								schemas: schemas, 
								externalUrlPrefix:"https://goatedgoats.com/")
			
			let token <- FindForge.mint(lease: lease, nftType: nftType, data: mintData, mintFN: mintFN)

			collection.deposit(token: <- token)
			i=i+1
		}	
		i = 1
		
		finLeases.addForgeMinter(name:"klktn", 
								 forgeMinterType: forgeType, 
								 description: "klktn FIND",
								 externalURL: "https://klktn.com/", 
								 squareImage: "", 
								 bannerImage: ""
								 )

		minterName="klktn"
		lease=finLeases.borrow(minterName)
		if !FindForge.checkMinterPlatform(name: lease.getName(), nftType: nftType ) {
			/* set up minterPlatform */
			FindForge.setMinterPlatform(lease: lease, 
										nftType: Type<@Dandy.NFT>(), 
										minterCut: 0.05, 
										description: "klktn FIND",
										externalURL: "https://klktn.com/", 
										squareImage: "", 
										bannerImage: "",
										socials: {
											"Twitter" : "https://twitter.com/KlktNofficial" ,
											"Twitter" : "https://discord.gg/wDc8yEcbeD"
										})

		while i <= maxEdition {
			let editioned= MetadataViews.Edition(name: "nft", number:i, max:maxEdition)
			let artCreativeWork=FindViews.CreativeWork(artist: artist, name: "klktn ", description: "klktn_NFT", type:"video")
			let description=artCreativeWork.description.concat( " edition ").concat(i.toString()).concat( " of ").concat(maxEdition.toString())
			let artHttpFile=MetadataViews.HTTPFile(url:"https://ipfs.io/ipfs/bafybeif3banecjnrz7afp54tb332f3zzigzbdcgmjk3k3dwp4iqlrwsbju/73ceab33cf76c2cf48a9a587119c87d21d4ec92b5748e743113c4ce8a1568b53.mp4")
			let artMedia=MetadataViews.Media(file: artHttpFile, mediaType: "video/mp4")
			let artTag=FindViews.Tag({"klktn Tag":"Tag1"})
			let artScalar=FindViews.Scalar({"id" : 0.0})
			let schemas: [AnyStruct] = [ MetadataViews.Editions([editioned]), artCreativeWork, artMedia, minterRoyalty, rarity, artTag, artScalar, FindViews.Medias([artMedia])]
			
			let mintData = Dandy.DandyInfo(name:"klktn ".concat(i.toString()).concat(" of ").concat(maxEdition.toString()), 
								description: artCreativeWork.description,
								thumbnail: artMedia,
								schemas: schemas, 
								externalUrlPrefix:"https://klktn.com/")
			
			let token <- FindForge.mint(lease: lease, nftType: nftType, data: mintData, mintFN: mintFN)
			
			collection.deposit(token: <- token)
			i=i+1
		}	
		i = 1

	}
}
