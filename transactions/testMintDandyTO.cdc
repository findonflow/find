
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
			let schemas: [AnyStruct] = [ editioned, creativeWork, minterRoyalty, rarity, tag, scalar, FindViews.Medias([media])]
			let token <- finLeases.mintDandy(minter: name, 
			  nftName: "Neo Motorcycle ".concat(i.toString()).concat(" of ").concat(maxEdition.toString()), 
				description: creativeWork.description,
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
			let artCreativeWork=FindViews.CreativeWork(artist: artist, name: "xtingle ", description: "xtingle_NFT", type:"video/mp4")
			let description=artCreativeWork.description.concat( " edition ").concat(i.toString()).concat( " of ").concat(maxEdition.toString())
			let artHttpFile=MetadataViews.HTTPFile(url:"https://nft.blocto.app/xtingles/xBloctopus.mp4")
			let thumbnailFile=MetadataViews.HTTPFile(url:"https://nft.blocto.app/xtingles/preview-xBloctopus.png")
			let artMedia=MetadataViews.Media(file: artHttpFile, mediaType: "video")
			let thumbnailMedia=MetadataViews.Media(file: thumbnailFile, mediaType: "thumbnail")
			let artTag=FindViews.Tag({"xtingle Tag":"Tag1"})
			let artScalar=FindViews.Scalar({"video length" : 27.0})

			let schemas: [AnyStruct] = [ editioned, artCreativeWork, artMedia, minterRoyalty, rarity, artTag, artScalar, FindViews.Medias([artMedia, thumbnailMedia])]
			let token <- finLeases.mintDandy(minter: name, 
			  nftName: "xtingle ".concat(i.toString()).concat(" of ").concat(maxEdition.toString()), 
				description: artCreativeWork.description,
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
			let artHttpFile=MetadataViews.HTTPFile(url:"https://flovatar.com/flovatars/1225/0x92ba5cba77fc1e87")
			let artMedia=MetadataViews.Media(file: artHttpFile, mediaType: "image")
			let artTag=FindViews.Tag({"flovatar Tag":"Tag1"})
			let artScalar=FindViews.Scalar({"rarity score" : 2.2})

			let schemas: [AnyStruct] = [ editioned, artCreativeWork, artMedia, minterRoyalty, rarity, artTag, artScalar, FindViews.Medias([artMedia])]
			let token <- finLeases.mintDandy(minter: name, 
			  nftName: "flovatar ".concat(i.toString()).concat(" of ").concat(maxEdition.toString()), 
				description: artCreativeWork.description,
				schemas: schemas, 
				externalUrlPrefix: "https://flovatar.com/flovatars/",
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
			let artCreativeWork=FindViews.CreativeWork(artist: artist, name: "ufcstrike ", description: "ufcstrike_NFT", type:"video/ipfs")
			let description=artCreativeWork.description.concat( " edition ").concat(i.toString()).concat( " of ").concat(maxEdition.toString())
			let artHttpFile=MetadataViews.IPFSFile(cid:"https://giglabs.mypinata.cloud/ipfs/QmdDJUobzSaFfg8PwZZcCB3cPwbZ8pthRf1x6XiR9xwS3U", path:nil)
			let thumbnailHttpFile=MetadataViews.IPFSFile(cid:"https://giglabs.mypinata.cloud/ipfs/QmeDLGnYNyunkTjd23yx36sHviWyR9L2shHshjwe1qBCqR", path:nil)
			let artMedia=MetadataViews.Media(file: artHttpFile, mediaType: "image/ipfs")
			let thumbnailMedia=MetadataViews.Media(file: thumbnailHttpFile, mediaType: "thumbnail")

			let artTag=FindViews.Tag({"ufcstrike Tag":"Tag1"})
			let artScalar=FindViews.Scalar({"rank" : 295.0})

			let schemas: [AnyStruct] = [ editioned, artCreativeWork, artMedia, minterRoyalty, rarity, artTag, artScalar, FindViews.Medias([artMedia, thumbnailMedia])]
			let token <- finLeases.mintDandy(minter: name, 
			  nftName: "ufcstrike ".concat(i.toString()).concat(" of ").concat(maxEdition.toString()), 
				description: artCreativeWork.description,
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

		i = 1

		while i <= maxEdition {
			let editioned= MetadataViews.Edition(name: "nft", number:i, max:maxEdition)
			let artCreativeWork=FindViews.CreativeWork(artist: artist, name: "Arlequin ", description: "Arlequin_NFT", type:"3d_model")
			let description=artCreativeWork.description.concat( " edition ").concat(i.toString()).concat( " of ").concat(maxEdition.toString())
			let artHttpFile=MetadataViews.HTTPFile(url:"https://www.arlequin.gg/arlee?cid=bafybeidljddi5awmjxqitiyx7pqpjywup44hi5vee7fgjyaj6wohucrxje")
			let thumbnailHttpFile=MetadataViews.HTTPFile(url:"https://bafybeidljddi5awmjxqitiyx7pqpjywup44hi5vee7fgjyaj6wohucrxje.ipfs.nftstorage.link/thumbnail.jpeg")
			let artMedia=MetadataViews.Media(file: artHttpFile, mediaType: "3d model")
			let thumbnailMedia=MetadataViews.Media(file: thumbnailHttpFile, mediaType: "thumbnail")
			
			let artTag=FindViews.Tag({"arlequin Tag":"Tag1"})
			let artScalar=FindViews.Scalar({"mint #" : 3.0})

			let schemas: [AnyStruct] = [ editioned, artCreativeWork, artMedia, minterRoyalty, rarity, artTag, artScalar, FindViews.Medias([artMedia, thumbnailMedia])]
			let token <- finLeases.mintDandy(minter: name, 
			  nftName: "Arlequin ".concat(i.toString()).concat(" of ").concat(maxEdition.toString()), 
				description: artCreativeWork.description,
				schemas: schemas, 
				externalUrlPrefix: "https://www.arlequin.gg/arlee?cid=",
				collectionDescription: "Arlequin FIND",
				collectionExternalURL: "https://www.arlequin.gg/",
				collectionSquareImage: "https://www.arlequin.gg/images/logo.webp",
				collectionBannerImage: "https://www.arlequin.gg/images/logo.webp",
			)

			collection.deposit(token: <- token)
			i=i+1
		}
	}
}
