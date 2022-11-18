import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FlowStorageFees from "../contracts/standard/FlowStorageFees.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FindViews from "../contracts/FindViews.cdc"
import FIND from "../contracts/FIND.cdc"
import FindAirdropper from "../contracts/FindAirdropper.cdc"

transaction(nftIdentifiers: [String], allReceivers: [String] , ids:[UInt64], memos: [String]) {

	let authPointers : [FindViews.AuthNFTPointer]
	let paths : [PublicPath]
    let flowVault : &FungibleToken.Vault
    let flowTokenRepayment : Capability<&FlowToken.Vault{FungibleToken.Receiver}>
    let defaultTokenAvailableBalance : UFix64 

	prepare(account : AuthAccount) {

		self.authPointers = []
		self.paths = []

		let contractData : {Type : NFTCatalog.NFTCatalogMetadata} = {}


		for i , typeIdentifier in nftIdentifiers {
			let type = CompositeType(typeIdentifier) ?? panic("Cannot refer to type with identifier : ".concat(typeIdentifier))

			var data : NFTCatalog.NFTCatalogMetadata? = contractData[type]
			if data == nil {
				data = FINDNFTCatalog.getMetadataFromType(type) ?? panic("NFT Type is not supported by NFT Catalog. Type : ".concat(type.identifier))
				contractData[type] = data
			}

			let path = data!.collectionData

			var providerCap=account.getCapability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection, NonFungibleToken.CollectionPublic}>(path.privatePath)
			if !providerCap.check() {
				let newCap = account.link<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
					path.privatePath,
					target: path.storagePath
				)
				if newCap == nil {
					// If linking is not successful, we link it using finds custom link 
					let pathIdentifier = path.privatePath.toString()
					let findPath = PrivatePath(identifier: pathIdentifier.slice(from: "/private/".length , upTo: pathIdentifier.length).concat("_FIND"))!
					account.link<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
						findPath,
						target: path.storagePath
					)
					providerCap = account.getCapability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(findPath)
				}
			}
			let pointer = FindViews.AuthNFTPointer(cap: providerCap, id: ids[i])
			self.authPointers.append(pointer)
			self.paths.append(path.publicPath)
		}

        self.flowVault = account.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault) ?? panic("Cannot borrow reference to sender's flow vault")
        self.flowTokenRepayment = account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver) 
        self.defaultTokenAvailableBalance = FlowStorageFees.defaultTokenAvailableBalance(account.address)

	}

	execute {
		let addresses : {String : Address} = {} 
        let estimatedStorageFee = 0.0002 * UFix64(self.authPointers.length) 
        // we pass in the least amount as possible for storage fee here
        let tempVault <- self.flowVault.withdraw(amount: 0.0)
        var vaultRef = &tempVault as &FungibleToken.Vault
        if self.defaultTokenAvailableBalance <= estimatedStorageFee {
            vaultRef = self.flowVault as &FungibleToken.Vault
        } else {
            tempVault.deposit(from: <- self.flowVault.withdraw(amount: estimatedStorageFee))
        }
		for i,  pointer in self.authPointers {
			let receiver = allReceivers[i]
			let id = ids[i] 
			let message = memos[i]
			let path = self.paths[i]

			var user = addresses[receiver]
			if user == nil {
				user = FIND.resolve(receiver) ?? panic("Cannot resolve user with name / address : ".concat(receiver))
				addresses[receiver] = user
			}

			// airdrop thru airdropper
			FindAirdropper.forcedAirdrop(pointer: pointer, receiver: user!, path: path, context: {"message" : message}, storagePayment: vaultRef, flowTokenRepayment: self.flowTokenRepayment)
		}
        self.flowVault.deposit(from: <- tempVault)
	}
}
