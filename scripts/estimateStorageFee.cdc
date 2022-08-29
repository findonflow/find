import FindLostAndFoundWrapper from "../contracts/FindLostAndFoundWrapper.cdc"
import LostAndFound from "../contracts/standard/LostAndFound.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import FIND from "../contracts/FIND.cdc"

pub fun main(sender: Address, nftIdentifiers: [String], allReceivers: [String] , ids:[UInt64], random: Bool) : Payment {
	let account = getAuthAccount(sender)

        if allReceivers.length != nftIdentifiers.length || allReceivers.length != ids.length {
            let err = "The length of arrays passed in are not equal"
			return logErr(err)
        }

		var receivers = allReceivers
		if random {
			receivers = FindLostAndFoundWrapper.shuffleStringArray(allReceivers)
		}

		// Mimic the transaction to get all the required amount of storage 
        let pointers : [FindViews.AuthNFTPointer] = []
        let nftInfos : {String : NFTCatalog.NFTCollectionData} = {}
        let providerCaps : {String : Capability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection, NonFungibleToken.CollectionPublic}>} = {}
        let receivingAddresses : {String : Address} = {}
        let fees : [UFix64] = []
		var totalPayment : UFix64 = 0.0

        for i, id in ids {
            if nftInfos[nftIdentifiers[i]] == nil {
                let collections = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftIdentifiers[i]) 
					if collections == nil {
						return logErr("NFT type is not supported at the moment. Type : ".concat(nftIdentifiers[i]))
					}
                nftInfos[nftIdentifiers[i]] = FINDNFTCatalog.getCatalogEntry(collectionIdentifier: collections!.keys[0])!.collectionData
            }

			let nftInfo = nftInfos[nftIdentifiers[i]]!

            if providerCaps[nftIdentifiers[i]] == nil {
                // Initialize the providerCap if the user doesn't have one
                var providerCap=account.getCapability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection, NonFungibleToken.CollectionPublic}>(nftInfo.privatePath)

                if !providerCap.check() {
                    let newCap = account.link<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
                        nftInfo.privatePath,
                        target: nftInfo.storagePath
                    )
                    if newCap == nil {
                        // If linking is not successful, we link it using finds custom link 
                        let pathIdentifier = nftInfo.privatePath.toString()
                        let findPath = PrivatePath(identifier: pathIdentifier.slice(from: "/private/".length , upTo: pathIdentifier.length).concat("_FIND"))!
                        account.link<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
                            findPath,
                            target: nftInfo.storagePath
                        )
                        providerCap = account.getCapability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(findPath)
                    }
                }
                providerCaps[nftIdentifiers[i]] = providerCap
            }

            let providerCap = providerCaps[nftIdentifiers[i]]!
			let pointer = FindViews.AuthNFTPointer(cap: providerCap, id: id)
            if receivingAddresses[receivers[i]] == nil {
                let receivingAddress = FIND.resolve(receivers[i]) 
				if receivingAddress == nil {
					return logErr("invalid find name or address")
				}
                receivingAddresses.insert(key: receivers[i], receivingAddress!)
            }
            let receivingAddress = receivingAddresses[receivers[i]]!

			let display = pointer.getDisplay()
			let estimate <- LostAndFound.estimateDeposit(
										redeemer: receivingAddress,
										item: <- pointer.withdraw(),
										memo: "",
										display: display
									)
			let fee = estimate.storageFee 
			fees.append(fee)
			totalPayment = totalPayment + fee
			destroy estimate.withdraw()
			destroy  estimate
        }

		let flowVault = account.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault) 
		if flowVault == nil {
			return logErr("Cannot borrow reference to sender's flow vault")
		}
		let userFlowBalance = flowVault!.balance

		return Payment(nftIdentifiers : nftIdentifiers , receivers : receivers , ids : ids , fees : fees ,totalPayment : totalPayment, userFlowBalance : userFlowBalance ,sufficientBalance : userFlowBalance > totalPayment, error: nil)


}


pub struct Payment {

	pub let inputNftIdentifiers : [String]
	pub let inputReceivers : [String] 
	pub let inputIds : [UInt64] 
	pub let inputFees : [UFix64] 
	pub let totalPayment : UFix64?
	pub let userFlowBalance : UFix64? 
	pub let sufficientBalance : Bool?
	pub let error : String?

	init(nftIdentifiers : [String] , receivers : [String] , ids : [UInt64] , fees : [UFix64] ,totalPayment : UFix64?, userFlowBalance : UFix64? ,sufficientBalance : Bool?, error: String?) {
		self.inputNftIdentifiers = nftIdentifiers
		self.inputReceivers = receivers
		self.inputIds = ids
		self.inputFees = fees
		self.totalPayment = totalPayment
		self.userFlowBalance = userFlowBalance
		self.sufficientBalance = sufficientBalance
		self.error = error
	}
}

pub fun logErr(_ err: String) : Payment {
	return Payment(nftIdentifiers : [] , receivers : [] , ids : [] , fees : [] ,totalPayment : nil, userFlowBalance : nil ,sufficientBalance : nil, error: err)
}