import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"

transaction(marketplace:Address, users: [Address], ids: [UInt64], amounts: [UFix64]) {

	let targetCapability : [Capability<&{NonFungibleToken.Receiver}>]
	var walletReference : [&FungibleToken.Vault]
	let walletBalance : {Type : UFix64}

	let saleItems: [&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}]
	var totalPrice : UFix64
	let prices : [UFix64]
	prepare(dapper: AuthAccount, account: AuthAccount) {

		if users.length != ids.length {
			panic("The array length of users and ids should be the same")
		}

		//the code below has some dead code for this specific transaction, but it is hard to maintain otherwise

		var counter = 0
		self.walletReference= []
		self.targetCapability = []
		self.walletBalance = {}

		self.saleItems = []
		let nfts : {String : NFTCatalog.NFTCollectionData} = {}
		let fts : {String : FTRegistry.FTInfo} = {}
		let saleItems : {Address : &FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}} = {}

		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketSale.SaleItemCollection>())

		let tenantCapability= FindMarket.getTenantCapability(marketplace)!
		let tenant = tenantCapability.borrow()!
		let publicPath=FindMarket.getPublicPath(Type<@FindMarketSale.SaleItemCollection>(), name: tenant.name)
		var vaultType : Type? = nil

		self.totalPrice = 0.0
		self.prices = []

		while counter < users.length {

			let address=users[counter]

			if saleItems[address] == nil {
				let saleItem = getAccount(address).getCapability<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(publicPath).borrow() ?? panic("cannot find sale item cap")
				self.saleItems.append(saleItem)
				saleItems[address] = saleItem 
			} else {
				self.saleItems.append(saleItems[address]!)
			}


			// let item= FindMarket.assertOperationValid(tenant: marketplace, address: address, marketOption: marketOption, id: ids[counter])
			let item=saleItems[address]!.borrowSaleItem(ids[counter])

			self.prices.append(item.getBalance())
			self.totalPrice = self.totalPrice + self.prices[counter]

			var nft : NFTCatalog.NFTCollectionData? = nil
			var ft : FTRegistry.FTInfo? = nil
			let nftIdentifier = item.getItemType().identifier
			let ftIdentifier = item.getFtType().identifier

			if nfts[nftIdentifier] != nil {
				nft = nfts[nftIdentifier]
			} else {
				let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftIdentifier)) 
				let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])! 
				nft = collection.collectionData
				nfts[nftIdentifier] = nft
			}

			if fts[ftIdentifier] != nil {
				ft = fts[ftIdentifier]
			} else {
				ft = FTRegistry.getFTInfo(ftIdentifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(ftIdentifier))
				fts[ftIdentifier] = ft 
			}

			let dapperVault = dapper.borrow<&FungibleToken.Vault>(from: ft!.vaultPath) ?? panic("Cannot borrow Dapper Coin Vault : ".concat(ft!.type.identifier))

			self.walletReference.append(
				dapperVault
			)

			if self.walletBalance[dapperVault.getType()] == nil {
				self.walletBalance[dapperVault.getType()] = dapperVault.balance
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
		while counter < users.length {
			if self.prices[counter] != amounts[counter] {
				panic("Please pass in the correct price of the buy items. Required : ".concat(self.prices[counter].toString()).concat(" . saleItem ID : ".concat(ids[counter].toString())))
			}
			if self.walletReference[counter].balance < amounts[counter] {
				panic("Your wallet does not have enough funds to pay for this item. Required : ".concat(self.prices[counter].toString()).concat(" . saleItem ID : ".concat(ids[counter].toString())))
			}

			self.saleItems[counter].buy(id:ids[counter], vault: <- self.walletReference[counter].withdraw(amount: amounts[counter]) , nftCap: self.targetCapability[counter])
			counter = counter + 1
		}

		// post 
		for vault in self.walletReference {
			if vault.balance != self.walletBalance[vault.getType()] {
				panic("Dapper Coin Leakage : ".concat(vault.getType().identifier))
			}
		}
	}


}
