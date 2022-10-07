import FindMarketDirectOfferIOU from "../contracts/FindMarketDirectOfferIOU.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import TokenForwarding from "../contracts/standard/TokenForwarding.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import Profile from "../contracts/Profile.cdc"

transaction(marketplace:Address, id: UInt64) {

	let market : &FindMarketDirectOfferIOU.SaleItemCollection
	let pointer : FindViews.AuthNFTPointer
	let mainDapperUtilityCoinVault: &DapperUtilityCoin.Vault
	let balanceBeforeTransfer: UFix64
	let amount: UFix64

	prepare(dapper: AuthAccount, account: AuthAccount) {

		let ducReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
		if !ducReceiver.check() {
			// Create a new Forwarder resource for DUC and store it in the new account's storage
			let ducForwarder <- TokenForwarding.createNewForwarder(recipient: dapper.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver))
			account.save(<-ducForwarder, to: /storage/dapperUtilityCoinReceiver)
			// Publish a Receiver capability for the new account, which is linked to the DUC Forwarder
			account.link<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver,target: /storage/dapperUtilityCoinReceiver)
		}

		let profile=account.borrow<&Profile.User>(from: Profile.storagePath)!
		if !profile.hasWallet("DUC") {
			profile.addWallet(Profile.Wallet( name:"DUC", receiver:ducReceiver, balance: dapper.getCapability<&{FungibleToken.Balance}>(/public/dapperUtilityCoinBalance), accept: Type<@DapperUtilityCoin.Vault>(), tags: ["duc", "dapperUtilityCoin","dapper"]))
			profile.emitUpdatedEvent()
		}


		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferIOU.SaleItemCollection>())
		self.market = account.borrow<&FindMarketDirectOfferIOU.SaleItemCollection>(from: storagePath)!
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketDirectOfferIOU.SaleItemCollection>())
		let item = FindMarket.assertOperationValid(tenant: marketplace, address: account.address, marketOption: marketOption, id: id)
		let nftIdentifier = item.getItemType().identifier

		//If this is nil, there must be something wrong with FIND setup
		// let nft = getCollectionData(nftIdentifier)
		let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftIdentifier)) 
		let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])! 
		let nft = collection.collectionData

		let providerCap=account.getCapability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection, NonFungibleToken.CollectionPublic}>(nft.privatePath)
		self.pointer= FindViews.AuthNFTPointer(cap: providerCap, id: item.getItemID())

		self.mainDapperUtilityCoinVault = dapper.borrow<&DapperUtilityCoin.Vault>(from: /storage/dapperUtilityCoinVault) ?? panic("Cannot borrow DapperUtilityCoin vault from account storage")
		self.balanceBeforeTransfer = self.mainDapperUtilityCoinVault.balance
		self.amount = item.getBalance()

	}

	execute {
		self.market.acceptDirectOffer(pointer: self.pointer, vault: <- self.mainDapperUtilityCoinVault.withdraw(amount: self.amount) )
	}

	post {
		self.mainDapperUtilityCoinVault.balance == self.balanceBeforeTransfer: "DapperUtilityCoin leakage"
	}
	
}
