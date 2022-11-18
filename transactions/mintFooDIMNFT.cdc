import FIND from "../contracts/FIND.cdc"
import FindFooDIM from 0x045a1763c93006ca
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FindForge from "../contracts/FindForge.cdc"
import FindUtils from "../contracts/FindUtils.cdc"

transaction(name: String, data: [AnyStruct], receivers: [String]) {

	let addresses: [Address]
	let lease: &FIND.Lease

    prepare(account: AuthAccount){

		let nftCap= account.getCapability<&{NonFungibleToken.CollectionPublic}>(FindFooDIM.CollectionPublicPath)
		if !nftCap.check() {
			account.save<@NonFungibleToken.Collection>(<- FindFooDIM.createEmptyCollection(), to: FindFooDIM.CollectionStoragePath)
			account.link<&FindFooDIM.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
				FindFooDIM.CollectionPublicPath,
				target: FindFooDIM.CollectionStoragePath
			)
			account.link<&FindFooDIM.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
				FindFooDIM.CollectionPrivatePath,
				target: FindFooDIM.CollectionStoragePath
			)
		}

		let leaseCol = account.borrow<&FIND.LeaseCollection>(from: FIND.LeaseStoragePath) ?? panic("Cannot borrow lease collection reference")
		self.lease = leaseCol.borrow(name)

		self.addresses = []
		for receiver in receivers {
			let addr = FIND.resolve(receiver) ?? panic("Cannot resolve string : ".concat(receiver))
			self.addresses.append(addr)
		}

    }

	execute{
		let forgeType = FindFooDIM.getForgeType()
		for i, d in data {
			let addr = self.addresses[i]
			let r = getAccount(addr).getCapability<&{NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(FindFooDIM.CollectionPublicPath).borrow() ?? panic("User does not setup FindFooDIM collection properly. User : ".concat(addr.toString()))
			FindForge.mint(lease: self.lease, forgeType: forgeType , data: d, receiver: r)
		}
	}
}

 