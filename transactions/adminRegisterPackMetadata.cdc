import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FindPack from "../contracts/FindPack.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"

import Admin from "../contracts/Admin.cdc"

// this is a simple tx to update the metadata of a given type of NeoVoucher

transaction(typeId: UInt64, thumbnailHash: String, wallet: Address, price: UFix64, buyTime:UFix64, openTime:UFix64,  royaltyCut: UFix64, royaltyAddress: Address, floatEventId:UInt64, whiteListTime: UFix64) {


	let admin: &Admin.AdminProxy
	let wallet: Capability<&{FungibleToken.Receiver}>
	let royaltyWallet: Capability<&{FungibleToken.Receiver}>

	prepare(account: AuthAccount) {
		self.admin =account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Could not borrow admin")
		self.wallet = getAccount(wallet).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
		self.royaltyWallet = getAccount(royaltyAddress).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
	}

	execute {

		if !self.wallet.check() {
			panic("wallet has to exist")
		}
		//TODO: we need to rethink this, fetch from NFTRegistry?
		let providerCap= self.admin.getProviderCap()

		/* For testing only */
		var whiteListTimeInput : UFix64? = nil
		if whiteListTime != 0.0 {
			whiteListTimeInput = whiteListTime
		}

		var floatEventIdInput : UInt64? = nil
		if floatEventId != 0 {
			floatEventIdInput = floatEventId
		}


		let season=typeId-1
		let name="Bl0x Season #".concat(season.toString())

		let metadata = FindPack.Metadata(name: name,
		description: name, 
		thumbnailUrl: nil, 
		thumbnailHash: thumbnailHash, 
		wallet: self.wallet, 
		price: price, 
		buyTime:buyTime,
		openTime:openTime, 
		walletType: Type<@FlowToken.Vault>(),
		providerCap: providerCap, 
		requiresReservation:false,
		royaltyCut:royaltyCut,
		royaltyWallet:self.royaltyWallet,
		floatEventId:floatEventIdInput,
		whiteListTime:whiteListTimeInput,
		storageRequirement:10000)

		self.admin.registerPackMetadata(typeId: typeId, metadata: metadata)
	}
}
