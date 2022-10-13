import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FIND from "../contracts/FIND.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"

transaction(dapperAddress: Address, marketplace:Address, users: [String], ids: [UInt64], amounts: [UFix64]) {

	let targetCapability : [Capability<&{NonFungibleToken.Receiver}>]
	var walletReference : &FungibleToken.Vault

	let saleItemsCap: [Capability<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic}> ]
	let balanceBeforeTransfer: UFix64

	var totalPrice : UFix64 
	let prices : [UFix64]

	prepare(dapper: AuthAccount, account: AuthAccount) {

		if users.length != ids.length {
			panic("The array length of users and ids should be the same")
		}

		var counter = 0
		self.targetCapability = []
		self.walletReference = dapper.borrow<&DapperUtilityCoin.Vault>(from: /storage/dapperUtilityCoinVault) ?? panic("Cannot borrow DapperUtilityCoin vault from account storage".concat(dapper.address.toString()))
		self.balanceBeforeTransfer = self.walletReference.balance

		self.saleItemsCap = []
		let addresses : {String : Address} = {}
		let nfts : {String : NFTCatalog.NFTCollectionData} = {}

		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketSale.SaleItemCollection>())

		self.totalPrice = 0.0
		self.prices = []

		while counter < users.length {
			var resolveAddress : Address? = nil
			if addresses[users[counter]] != nil {
				resolveAddress = addresses[users[counter]]!
			} else {
				let address = FIND.resolve(users[counter])
				if address == nil {
					panic("The address input is not a valid name nor address. Input : ".concat(users[counter]))
				}
				addresses[users[counter]] = address!
				resolveAddress = address!
			}
			let address = resolveAddress!
			let saleItemCap = FindMarketSale.getSaleItemCapability(marketplace: marketplace, user:address) ?? panic("cannot find sale item cap")
			self.saleItemsCap.append(saleItemCap)

			let item= FindMarket.assertOperationValid(tenant: marketplace, address: address, marketOption: marketOption, id: ids[counter])

			self.prices.append(item.getBalance())
			if self.prices[counter] != amounts[counter] {
				panic("Please pass in the correct amount for item. saleID : ".concat(ids[counter].toString()).concat(" . Required : ".concat(self.prices[counter].toString())))
			}

			var nft : NFTCatalog.NFTCollectionData? = nil
			let nftIdentifier = item.getItemType().identifier
			let ftType = item.getFtType()

			if nfts[nftIdentifier] != nil {
				nft = nfts[nftIdentifier]
			} else {
				let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftIdentifier)) 
				let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])! 
				nft =  collection.collectionData
				nfts[nftIdentifier] = nft
			}
			
			if ftType != Type<@DapperUtilityCoin.Vault>() {
				panic("This item is not listed for Dapper Wallets. Please buy in with other wallets.")
			}

			var targetCapability= account.getCapability<&{NonFungibleToken.Receiver}>(nft!.publicPath)
			/* Check for nftCapability */
			if !targetCapability.check() {
				let cd = item.getNFTCollectionData()
				// should use account.type here instead
				if account.type(at: cd.storagePath) != nil {
					let pathIdentifier = nft!.publicPath.toString()
					let findPath = PublicPath(identifier: pathIdentifier.slice(from: "/public/".length , upTo: pathIdentifier.length).concat("_FIND"))!
					account.link<&{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
						findPath,
						target: nft!.storagePath
					)
					targetCapability = account.getCapability<&{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(findPath)
				} else {
					account.save(<- cd.createEmptyCollection(), to: cd.storagePath)
					account.link<&{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(cd.publicPath, target: cd.storagePath)
					account.link<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(cd.providerPath, target: cd.storagePath)
				}

			}
			self.targetCapability.append(targetCapability)
			counter = counter + 1
		}
	}

	execute {
		var counter = 0 
		while counter < ids.length {
			if self.walletReference.balance < amounts[counter] {
				panic("Your wallet does not have enough funds to pay for this item. Required : ".concat(self.totalPrice.toString()))
			}
			let vault <- self.walletReference.withdraw(amount: self.prices[counter]) 
			self.saleItemsCap[counter].borrow()!.buy(id:ids[counter], vault: <- vault, nftCap: self.targetCapability[counter])
			counter = counter + 1
		}
	}

	// Check that all dapperUtilityCoin was routed back to Dapper
	post {
		self.walletReference.balance == self.balanceBeforeTransfer: "DapperUtilityCoin leakage"
	}
}
