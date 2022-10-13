import FindMarket from "../contracts/FindMarket.cdc"
import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import FindLeaseMarketSale from "../contracts/FindLeaseMarketSale.cdc"
import FindLeaseMarket from "../contracts/FindLeaseMarket.cdc"

//TODO: test, and rename to Dapper, repeat for other tx
transaction(leaseName: String, amount: UFix64) {

	let to : Address
	let saleItemsCap: Capability<&FindLeaseMarketSale.SaleItemCollection{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>
	let mainDapperUtilityCoinVault: &DapperUtilityCoin.Vault
	let balanceBeforeTransfer: UFix64

	prepare(dapper: AuthAccount, account: AuthAccount) {

		let profile=account.borrow<&Profile.User>(from: Profile.storagePath) ?? panic("You do not have a profile set up, initialize the user first")
	
		let address = FIND.resolve(leaseName) ?? panic("The address input is not a valid name nor address. Input : ".concat(leaseName))
		let leaseMarketplace = FindMarket.getTenantAddress("findLease") ?? panic("Cannot find findLease tenant")
		self.saleItemsCap= FindLeaseMarketSale.getSaleItemCapability(marketplace: leaseMarketplace, user:address) ?? panic("cannot find sale item cap for findLease")

		self.mainDapperUtilityCoinVault = dapper.borrow<&DapperUtilityCoin.Vault>(from: /storage/dapperUtilityCoinVault) ?? panic("Cannot borrow DapperUtilityCoin vault from account storage".concat(dapper.address.toString()))
		self.balanceBeforeTransfer = self.mainDapperUtilityCoinVault.balance
		self.to= account.address
	}

	execute {
		let vault <- self.mainDapperUtilityCoinVault.withdraw(amount: amount) 
		self.saleItemsCap.borrow()!.buy(name:leaseName, vault: <- vault, to: self.to)
	}

	// Check that all dapperUtilityCoin was routed back to Dapper
	post {
		self.mainDapperUtilityCoinVault.balance == self.balanceBeforeTransfer: "DapperUtilityCoin leakage"
	}
}
