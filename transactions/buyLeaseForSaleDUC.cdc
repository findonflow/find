import FindMarket from "../contracts/FindMarket.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FIND from "../contracts/FIND.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import FindLeaseMarketSale from "../contracts/FindLeaseMarketSale.cdc"
import FindLeaseMarket from "../contracts/FindLeaseMarket.cdc"

transaction(dapperAddress: Address, leaseName: String, amount: UFix64) {

	let to : Address
	let walletReference : &FungibleToken.Vault

	let saleItemsCap: Capability<&FindLeaseMarketSale.SaleItemCollection{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>
	let mainDapperUtilityCoinVault: &DapperUtilityCoin.Vault
	let balanceBeforeTransfer: UFix64

	prepare(dapper: AuthAccount, account: AuthAccount) {

		let resolveAddress = FIND.resolve(leaseName)
		if resolveAddress == nil {
			panic("The address input is not a valid name nor address. Input : ".concat(leaseName))
		}
		let address = resolveAddress!
		let leaseMarketplace = FindMarket.getTenantAddress("findLease")!
		self.saleItemsCap= FindLeaseMarketSale.getSaleItemCapability(marketplace: leaseMarketplace, user:address) ?? panic("cannot find sale item cap")
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindLeaseMarketSale.SaleItemCollection>())

		let item= FindLeaseMarket.assertOperationValid(tenant: leaseMarketplace, name: leaseName, marketOption: marketOption)

		let ft = FTRegistry.getFTInfoByTypeIdentifier(item.getFtType().identifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(item.getFtType().identifier))
	
		if ft.type != Type<@DapperUtilityCoin.Vault>() {
			panic("This item is not listed for Dapper Wallets. Please buy in with other wallets.")
		}

		self.mainDapperUtilityCoinVault = dapper.borrow<&DapperUtilityCoin.Vault>(from: /storage/dapperUtilityCoinVault) ?? panic("Cannot borrow DapperUtilityCoin vault from account storage".concat(dapper.address.toString()))
		self.balanceBeforeTransfer = self.mainDapperUtilityCoinVault.balance

		self.to= account.address

		self.walletReference = dapper.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account")
	}

	pre {
		self.walletReference.balance > amount : "Your wallet does not have enough funds to pay for this item"
	}

	execute {
		let vault <- self.walletReference.withdraw(amount: amount) 
		self.saleItemsCap.borrow()!.buy(name:leaseName, vault: <- vault, to: self.to)
	}

	// Check that all dapperUtilityCoin was routed back to Dapper
	post {
		self.mainDapperUtilityCoinVault.balance == self.balanceBeforeTransfer: "DapperUtilityCoin leakage"
	}
}
