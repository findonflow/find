import FindLeaseMarketDirectOfferSoft from "../contracts/FindLeaseMarketDirectOfferSoft.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FindLeaseMarket from "../contracts/FindLeaseMarket.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import TokenForwarding from "../contracts/standard/TokenForwarding.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import Profile from "../contracts/Profile.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(dapperAddress: Address, leaseName: String) {

	let market : &FindLeaseMarketDirectOfferSoft.SaleItemCollection
	let pointer : FindLeaseMarket.AuthLeasePointer

	prepare(account: AuthAccount) {

		let ducReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
		if !ducReceiver.check() {
			let dapper = getAccount(dapperAddress)
			// Create a new Forwarder resource for DUC and store it in the new account's storage
			let ducForwarder <- TokenForwarding.createNewForwarder(recipient: dapper.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver))
			account.save(<-ducForwarder, to: /storage/dapperUtilityCoinReceiver)
			// Publish a Receiver capability for the new account, which is linked to the DUC Forwarder
			account.link<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver,target: /storage/dapperUtilityCoinReceiver)
		}

		let profile=account.borrow<&Profile.User>(from: Profile.storagePath)!
		if !profile.hasWallet("DUC") {
			profile.addWallet(Profile.Wallet( name:"DUC", receiver:ducReceiver, balance:getAccount(dapperAddress).getCapability<&{FungibleToken.Balance}>(/public/dapperUtilityCoinBalance), accept: Type<@DapperUtilityCoin.Vault>(), names: ["duc", "dapperUtilityCoin","dapper"]))
			profile.emitUpdatedEvent()
		}

		let marketplace = FindMarket.getTenantAddress("findLease")!
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindLeaseMarketDirectOfferSoft.SaleItemCollection>())
		self.market = account.borrow<&FindLeaseMarketDirectOfferSoft.SaleItemCollection>(from: storagePath)!
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindLeaseMarketDirectOfferSoft.SaleItemCollection>())
		let item = FindLeaseMarket.assertOperationValid(tenant: marketplace, name: leaseName, marketOption: marketOption)

		let ref = account.borrow<&FIND.LeaseCollection>(from: FIND.LeaseStoragePath) ?? panic("Cannot borrow reference to Find lease collection. Account : ".concat(account.address.toString()))
		self.pointer= FindLeaseMarket.AuthLeasePointer(ref: ref, name: leaseName)

	}

	execute {
		self.market.acceptOffer(self.pointer)
	}
	
}
