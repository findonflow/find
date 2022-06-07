
import FIND from "../contracts/FIND.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import Dandy from "../contracts/Dandy.cdc"
import Profile from "../contracts/Profile.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"

transaction(name: String, maxEdition:UInt64, artist:String, nftName:String, nftDescription:String, nftUrl:String, rarity: String, rarityNum:UFix64, to: Address) {
	prepare(account: AuthAccount) {

		let dancyReceiver =getAccount(to)
		let dandyCap= dancyReceiver.getCapability<&{NonFungibleToken.CollectionPublic}>(Dandy.CollectionPublicPath)
		if !dandyCap.check() {
			panic("need dandy receicer")
		}

		let finLeases= account.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!

		let creativeWork=
		FindViews.CreativeWork(artist: artist, name: nftName, description: nftDescription, type:"image")

		let httpFile=MetadataViews.HTTPFile(url:nftUrl)
		let media=MetadataViews.Media(file: httpFile, mediaType: "thumbnail")

		let rarity = FindViews.Rarity(rarity: rarityNum, rarityName:rarity, parts: {})

		let receiver=account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
		let minterRoyalty=MetadataViews.Royalties(cutInfos:[MetadataViews.Royalty(receiver: receiver, cut: 0.05, description: "artist")])

		let tag=FindViews.Tag({"NeoMotorCycleTag":"Tag1"})
		let scalar=FindViews.Scalar({"Speed" : 100.0})

		let collection=dandyCap.borrow()!
		var i:UInt64=1

		while i <= maxEdition {
			let editioned= MetadataViews.Edition(name: "nft", number:i, max:maxEdition)
			let description=creativeWork.description.concat( " edition ").concat(i.toString()).concat( " of ").concat(maxEdition.toString())
			let schemas: [AnyStruct] = [ MetadataViews.Editions([editioned]), creativeWork, minterRoyalty, rarity, tag, scalar, FindViews.Medias([media])]
			let token <- finLeases.mintDandy(minter: name, 
			  nftName: "Neo Motorcycle ".concat(i.toString()).concat(" of ").concat(maxEdition.toString()), 
				description: creativeWork.description,
				thumbnail: media,
				schemas: schemas, 
				externalUrlPrefix: "https://find.xyz/collection/".concat(name).concat("/dandy"),
				collectionDescription: "Neo Collectibles FIND",
				collectionExternalURL: "https://neomotorcycles.co.uk/index.html",
				collectionSquareImage: "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
				collectionBannerImage: "https://neomotorcycles.co.uk/assets/img/neo-logo-web-dark.png?h=5a4d226197291f5f6370e79a1ee656a1",
			)

			collection.deposit(token: <- token)
			i=i+1
		}
		i = 1

		while i <= maxEdition {
			let editioned= MetadataViews.Edition(name: "nft", number:i, max:maxEdition)
			let artCreativeWork=FindViews.CreativeWork(artist: artist, name: "xtingle ", description: "xtingle_NFT", type:"video")
			let description=artCreativeWork.description.concat( " edition ").concat(i.toString()).concat( " of ").concat(maxEdition.toString())
			let artHttpFile=MetadataViews.HTTPFile(url:"https://nft.blocto.app/xtingles/xBloctopus.mp4")
			let thumbnailFile=MetadataViews.HTTPFile(url:"https://nft.blocto.app/xtingles/preview-xBloctopus.png")
			let artMedia=MetadataViews.Media(file: artHttpFile, mediaType: "video")
			let thumbnailMedia=MetadataViews.Media(file: thumbnailFile, mediaType: "thumbnail")
			let artTag=FindViews.Tag({"xtingle Tag":"Tag1"})
			let artScalar=FindViews.Scalar({"video length" : 27.0})

			let schemas: [AnyStruct] = [ MetadataViews.Editions([editioned]), artCreativeWork, artMedia, minterRoyalty, rarity, artTag, artScalar, FindViews.Medias([artMedia, thumbnailMedia])]
			let token <- finLeases.mintDandy(minter: name, 
			  nftName: "xtingle ".concat(i.toString()).concat(" of ").concat(maxEdition.toString()), 
				description: artCreativeWork.description,
				thumbnail: thumbnailMedia,
				schemas: schemas, 
				externalUrlPrefix: "https://nft.blocto.app/xtingles/",
				collectionDescription: "xtingle FIND",
				collectionExternalURL: "https://xtingles.com/",
				collectionSquareImage: "https://xtingles-strapi-prod.s3.us-east-2.amazonaws.com/copy_of_upcoming_drops_db41fbf287.png",
				collectionBannerImage: "https://xtingles.com/images/main-metaverse.png",
			)

			collection.deposit(token: <- token)
			i=i+1
		}
		i = 1

		while i <= maxEdition {
			let editioned= MetadataViews.Edition(name: "nft", number:i, max:maxEdition)
			let artCreativeWork=FindViews.CreativeWork(artist: artist, name: "flovatar ", description: "flovatar_NFT", type:"image")
			let description=artCreativeWork.description.concat( " edition ").concat(i.toString()).concat( " of ").concat(maxEdition.toString())
			let artHttpFile=MetadataViews.HTTPFile(url:"https://flovatar.com/api/image/166")
			let artMedia=MetadataViews.Media(file: artHttpFile, mediaType: "image")
			let artTag=FindViews.Tag({"flovatar Tag":"Tag1"})
			let artScalar=FindViews.Scalar({"rarity score" : 2.2, "id" : 166.0})

			let schemas: [AnyStruct] = [ MetadataViews.Editions([editioned]), artCreativeWork, artMedia, minterRoyalty, rarity, artTag, artScalar, FindViews.Medias([artMedia])]
			let token <- finLeases.mintDandy(minter: name, 
			  nftName: "flovatar ".concat(i.toString()).concat(" of ").concat(maxEdition.toString()), 
				description: artCreativeWork.description,
				thumbnail: artMedia,
				schemas: schemas, 
				externalUrlPrefix: "https://flovatar.com/api/image/",
				collectionDescription: "flovatar FIND",
				collectionExternalURL: "https://flovatar.com/",
				collectionSquareImage: "https://miro.medium.com/max/1080/1*nD3N5BvxvH-wgLW1KPizoA.png",
				collectionBannerImage: "https://miro.medium.com/max/1400/1*WjFBUweGaThcTR-UOZ6TnA.gif",
			)

			collection.deposit(token: <- token)
			i=i+1
		}
		i = 1

		while i <= maxEdition {
			let editioned= MetadataViews.Edition(name: "nft", number:i, max:maxEdition)
			let artCreativeWork=FindViews.CreativeWork(artist: artist, name: "ufcstrike ", description: "ufcstrike_NFT", type:"video")
			let description=artCreativeWork.description.concat( " edition ").concat(i.toString()).concat( " of ").concat(maxEdition.toString())
			let artHttpFile=MetadataViews.IPFSFile(cid:"QmdDJUobzSaFfg8PwZZcCB3cPwbZ8pthRf1x6XiR9xwS3U", path:nil)
			let thumbnailHttpFile=MetadataViews.IPFSFile(cid:"QmeDLGnYNyunkTjd23yx36sHviWyR9L2shHshjwe1qBCqR", path:nil)
			let artMedia=MetadataViews.Media(file: artHttpFile, mediaType: "video")
			let thumbnailMedia=MetadataViews.Media(file: thumbnailHttpFile, mediaType: "thumbnail")

			let artTag=FindViews.Tag({"ufcstrike Tag":"Tag1"})
			let artScalar=FindViews.Scalar({"rank" : 295.0})

			let schemas: [AnyStruct] = [ MetadataViews.Editions([editioned]), artCreativeWork, artMedia, minterRoyalty, rarity, artTag, artScalar, FindViews.Medias([artMedia, thumbnailMedia])]
			let token <- finLeases.mintDandy(minter: name, 
			  nftName: "ufcstrike ".concat(i.toString()).concat(" of ").concat(maxEdition.toString()), 
				description: artCreativeWork.description,
				thumbnail: thumbnailMedia,
				schemas: schemas, 
				externalUrlPrefix: "https://giglabs.mypinata.cloud/ipfs/",
				collectionDescription: "ufc strike FIND",
				collectionExternalURL: "https://ufcstrike.com/",
				collectionSquareImage: "https://assets.website-files.com/62605ca984796169418ca5dc/628e9bba372af61fcf967e03_round-one-standard-p-1080.png",
				collectionBannerImage: "https://s3.us-east-2.amazonaws.com/giglabs.assets.ufc/4f166ac23e10bb510319e82fe9ed2c7d",
			)

			collection.deposit(token: <- token)
			i=i+1
		}

		while i <= maxEdition {
			let editioned= MetadataViews.Edition(name: "nft", number:i, max:maxEdition)
			let artCreativeWork=FindViews.CreativeWork(artist: artist, name: "jambb ", description: "jambb_NFT", type:"video")
			let description=artCreativeWork.description.concat( " edition ").concat(i.toString()).concat( " of ").concat(maxEdition.toString())
			let artHttpFile=MetadataViews.IPFSFile(cid:"QmVoKN72cEyQ87FkphUxuc2jMnsNUSB5zoSxEitGLBypPr", path:nil)
			let thumbnailHttpFile=MetadataViews.HTTPFile(url:"https://content-images.jambb.com/card-front/29849042-6fc8-4f13-8fa8-6a09501c6ea8.jpg")
			let artMedia=MetadataViews.Media(file: artHttpFile, mediaType: "video")
			let thumbnailMedia=MetadataViews.Media(file: thumbnailHttpFile, mediaType: "thumbnail")

			let artTag=FindViews.Tag({"jambb Tag":"Tag1"})
			let artScalar=FindViews.Scalar({"video length" : 45.0})

			let schemas: [AnyStruct] = [ MetadataViews.Editions([editioned]), artCreativeWork, artMedia, minterRoyalty, rarity, artTag, artScalar, FindViews.Medias([artMedia, thumbnailMedia])]
			let token <- finLeases.mintDandy(minter: name, 
			  nftName: "jambb ".concat(i.toString()).concat(" of ").concat(maxEdition.toString()), 
				description: artCreativeWork.description,
				thumbnail: thumbnailMedia,
				schemas: schemas, 
				externalUrlPrefix: "https://www.jambb.com/c/moment/",
				collectionDescription: "jambb FIND",
				collectionExternalURL: "https://www.jambb.com/",
				collectionSquareImage: "https://prod-jambb-issuance-static-public.s3.amazonaws.com/issuance-ui/logos/jambb-full-color-wordmark-inverted.svg",
				collectionBannerImage: "https://s3.amazonaws.com/jambb-prod-issuance-ui-static-assets/avatars/b76cdd34-e728-4e71-a0ed-c277a628654a/jambb-logo-3d-hp-hero-07.png",
			)

			collection.deposit(token: <- token)
			i=i+1
		}
	
		while i <= maxEdition {
			let editioned= MetadataViews.Edition(name: "nft", number:i, max:maxEdition)
			let artCreativeWork=FindViews.CreativeWork(artist: artist, name: "bitku ", description: "bitku_NFT", type:"text")
			let description=artCreativeWork.description.concat( " edition ").concat(i.toString()).concat( " of ").concat(maxEdition.toString())
			let artHttpFile=FindViews.OnChainFile(content:"No one\nOf the year I hope it's on\nFor work", mediaType: "text")
			let artMedia=MetadataViews.Media(file: artHttpFile, mediaType: "text")

			let artTag=FindViews.Tag({"bitku Tag":"Tag1"})
			let artScalar=FindViews.Scalar({"rank" : 0.0})

			let schemas: [AnyStruct] = [ MetadataViews.Editions([editioned]), artCreativeWork, artMedia, minterRoyalty, rarity, artTag, artScalar, FindViews.Medias([artMedia])]
			let token <- finLeases.mintDandy(minter: name, 
			  nftName: "jambb ".concat(i.toString()).concat(" of ").concat(maxEdition.toString()), 
				description: artCreativeWork.description,
				thumbnail: artMedia,
				schemas: schemas, 
				externalUrlPrefix: "https://bitku.art/",
				collectionDescription: "jambb FIND",
				collectionExternalURL: "https://bitku.art/",
				collectionSquareImage: "",
				collectionBannerImage: "",
			)

			collection.deposit(token: <- token)
			i=i+1
		}

		while i <= maxEdition {
			let editioned= MetadataViews.Edition(name: "nft", number:i, max:maxEdition)
			let artCreativeWork=FindViews.CreativeWork(artist: artist, name: "goatedgoats ", description: "goatedgoats_NFT", type:"image")
			let description=artCreativeWork.description.concat( " edition ").concat(i.toString()).concat( " of ").concat(maxEdition.toString())
			let artHttpFile=MetadataViews.IPFSFile(cid:"QmSj3vVwPPzq4UxUnrR7HvUCCFDJGvwBV2ShP7ycTtD73a", path:nil)
			let artMedia=MetadataViews.Media(file: artHttpFile, mediaType: "image")

			let artTag=FindViews.Tag({"goatedgoats Tag":"Tag1"})
			let artScalar=FindViews.Scalar({"id" : 2389.0})

			let schemas: [AnyStruct] = [ MetadataViews.Editions([editioned]), artCreativeWork, artMedia, minterRoyalty, rarity, artTag, artScalar, FindViews.Medias([artMedia])]
			let token <- finLeases.mintDandy(minter: name, 
			  nftName: "jambb ".concat(i.toString()).concat(" of ").concat(maxEdition.toString()), 
				description: artCreativeWork.description,
				thumbnail: artMedia,
				schemas: schemas, 
				externalUrlPrefix: "https://goatedgoats.com/",
				collectionDescription: "goatedgoats FIND",
				collectionExternalURL: "https://goatedgoats.com/",
				collectionSquareImage: "https://goatedgoats.com/_next/image?url=%2FLogo.png&w=64&q=75",
				collectionBannerImage: "",
			)

			collection.deposit(token: <- token)
			i=i+1
		}	
		
		while i <= maxEdition {
			let editioned= MetadataViews.Edition(name: "nft", number:i, max:maxEdition)
			let artCreativeWork=FindViews.CreativeWork(artist: artist, name: "klktn ", description: "klktn_NFT", type:"video")
			let description=artCreativeWork.description.concat( " edition ").concat(i.toString()).concat( " of ").concat(maxEdition.toString())
			let artHttpFile=MetadataViews.HTTPFile(url:"https://ipfs.io/ipfs/bafybeif3banecjnrz7afp54tb332f3zzigzbdcgmjk3k3dwp4iqlrwsbju/73ceab33cf76c2cf48a9a587119c87d21d4ec92b5748e743113c4ce8a1568b53.mp4")
			let artMedia=MetadataViews.Media(file: artHttpFile, mediaType: "video")

			let artTag=FindViews.Tag({"klktn Tag":"Tag1"})
			let artScalar=FindViews.Scalar({"id" : 0.0})

			let schemas: [AnyStruct] = [ MetadataViews.Editions([editioned]), artCreativeWork, artMedia, minterRoyalty, rarity, artTag, artScalar, FindViews.Medias([artMedia])]
			let token <- finLeases.mintDandy(minter: name, 
			  nftName: "jambb ".concat(i.toString()).concat(" of ").concat(maxEdition.toString()), 
				description: artCreativeWork.description,
				thumbnail: artMedia,
				schemas: schemas, 
				externalUrlPrefix: "https://klktn.com/",
				collectionDescription: "goatedgoatstraits FIND",
				collectionExternalURL: "https://klktn.com/",
				collectionSquareImage: "",
				collectionBannerImage: "",
			)

			collection.deposit(token: <- token)
			i=i+1
		}	

	}
}
