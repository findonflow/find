import FindMarketTenant from "../contracts/FindMarketTenant.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FindViews from "../contracts/FindViews.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindMarketOptions from "../contracts/FindMarketOptions.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(user: String, id: UInt64, amount: UFix64) {

	let targetCapability : Capability<&{NonFungibleToken.Receiver}>
	let walletReference : &FungibleToken.Vault

	let saleItemsCap: Capability<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic}> 
	let balanceBeforeBid: UFix64

	prepare(account: AuthAccount) {

		let resolveAddress = FIND.resolve(user)
		if resolveAddress == nil {panic("The address input is not a valid name nor address. Input : ".concat(user))}
		let address = resolveAddress!

		self.saleItemsCap= FindMarketSale.getFindSaleItemCapability(address) ?? panic("cannot find sale item cap")
		let marketOption = FindMarketOptions.getMarketOptionFromType(Type<@FindMarketSale.SaleItemCollection>())
		let saleInformation = FindMarketOptions.getFindSaleInformation(address: address, marketOption: marketOption, id:id) 
		if saleInformation==nil {
			panic("This listing is a ghost listing")
		}

		let nft = NFTRegistry.getNFTInfoByTypeIdentifier(saleInformation!.nftIdentifier) ?? panic("This NFT is not supported by the Find Market yet ")
		let ft = FTRegistry.getFTInfoByTypeIdentifier(saleInformation!.ftTypeIdentifier) ?? panic("This FT is not supported by the Find Market yet")
	
		self.targetCapability= account.getCapability<&{NonFungibleToken.Receiver}>(nft.publicPath)
		self.walletReference = account.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account")
		self.balanceBeforeBid=self.walletReference.balance
	}

	pre {
		self.saleItemsCap.check() : "The sale item cap is not linked"
		self.walletReference.balance > amount : "Your wallet does not have enough funds to pay for this item"
		self.targetCapability.check() : "The target collection for the item your are bidding on does not exist"
	}

	execute {
		let vault <- self.walletReference.withdraw(amount: amount) 
		self.saleItemsCap.borrow()!.buy(id:id, vault: <- vault, nftCap: self.targetCapability)
	}
}
