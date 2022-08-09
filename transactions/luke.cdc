import FUSD from "../contracts/standard/FUSD.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"
import NFGv3 from "../contracts/NFGv3.cdc"
import FindForge from "../contracts/FindForge.cdc"

transaction() {

	let leases : &FIND.LeaseCollection?
	let vaultRef : &FUSD.Vault? 
	let nftReceiver: &NFGv3.Collection{NonFungibleToken.Receiver, MetadataViews.ResolverCollection}

	prepare(account: AuthAccount) {

		self.leases= account.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)
		self.vaultRef = account.borrow<&FUSD.Vault>(from: /storage/fusdVault)

		let collectionCap= account.getCapability<&{NonFungibleToken.CollectionPublic}>(NFGv3.CollectionPublicPath)
		if !collectionCap.check() {
			account.save<@NonFungibleToken.Collection>(<- NFGv3.createEmptyCollection(), to: NFGv3.CollectionStoragePath)
			account.link<&NFGv3.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
				NFGv3.CollectionPublicPath,
				target: NFGv3.CollectionStoragePath
			)
			account.link<&NFGv3.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
				NFGv3.CollectionPrivatePath,
				target: NFGv3.CollectionStoragePath
			)
		}
		self.nftReceiver=account.getCapability<&NFGv3.Collection{NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(NFGv3.CollectionPublicPath).borrow() ?? panic("Cannot borrow reference to NFGv3 collection.")
	}

	pre{
		self.leases != nil : "Could not borrow reference to the leases collection"
		self.vaultRef != nil : "Could not borrow reference to the fusdVault!"
	}

	execute {
		let name = "nonfungerbils"
		let addon  = "forge"
		let amount= 50.0
		let minterCut = 0.075

		let vault <- self.vaultRef!.withdraw(amount: amount) as! @FUSD.Vault
		self.leases!.buyAddon(name: name, addon: addon, vault: <- vault)
		let lease=self.leases!.borrow(name)

		let forgeType = NFGv3.getForgeType()
		FindForge.setMinterPlatform(
			lease: lease, 
	  	forgeType: forgeType, 
	    minterCut: minterCut, 
	    description: "NonFunGerbils", 
	    externalURL: "https://nonfungerbils.com", 
	    squareImage: "https://find.mypinata.cloud/ipfs/QmeG1rPaLWmn4uUSjQ2Wbs7QnjxdQDyeadCGWyGwvHTB7c",
	    bannerImage: "https://find.mypinata.cloud/ipfs/QmWmDRnSrv8HK5QsiHwUNR4akK95WC8veydq6dnnFbMja1",
	    socials: { "Twitter" : "https://twitter.com/NonFunGerbils" },
	  ) 


		let maxEditions = UInt64(6)
		let nftName= "Pepe gerbil"
		let nftDescription = "#PEPEgerbil is besotted, obsessed by their precious, They cradle it, love it, perhaps it's devine.\n\nThis NFT pairs with a physical painting of mixed technique on canvas, size 24x30cm by Pepelangelo.\n\n Only the the owner of the physical can see what is uniquely precious."
		let imageHash = "QmbGVd9281kdD65wdD8QRqLzXN56KCgvBB4HySQuv24rmC"
		let externalURL= "https://nonfungerbils.com/pepegerbil"
		let traits = {
			"Released":     "9 August 2022",
			"Artist":       "@Pepelangelo",
			"Story Author": "NonFunGerbils"
		}
		let scalars = {
			"Gerbil Number": 29.0
		}
		let birthday = 1653427403.0
		let levels = {
			"Cuddles":         14.0,
			"Top Wheel Speed": 21.0,
			"Battle Squak":    78.0,
			"Degen":           92.0,
			"Maximalism":      64.0,
			"Funds are Safu":  70.0
		}

		var i = UInt64(1)
		while  i <= maxEditions {
			let mintData = NFGv3.Info(
				name: nftName,
				description: nftDescription, 
				thumbnailHash: imageHash,
				edition: i, 
				maxEdition: maxEditions,
				externalURL: externalURL,
				traits: traits,
				levels: levels, 
				scalars: scalars, 
				birthday: birthday, 
				medias: {}
			)
			FindForge.mint(lease: lease, forgeType: forgeType, data: mintData, receiver: self.nftReceiver)
			i=i+1
		}
	}
}
