import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"

access(all) contract FindMarketCutStruct {

	access(all) struct Cuts {
		access(all) let cuts : [{Cut}]
		access(contract) let extra: {String : AnyStruct}

		init(cuts: [{Cut}]) {
			self.cuts = cuts
			self.extra = {}
		}

		access(all) getEventSafeCuts() : [EventSafeCut] {
			let cuts : [EventSafeCut] = []
			for c in self.cuts {
				cuts.append(c.getEventSafeCut())
			}
			return cuts
		}
	}

	access(all) struct EventSafeCut {
		access(all) let name: String
		access(all) let description: String
		access(all) let cut: UFix64
		access(all) let receiver: Address
		access(all) let extra: {String : String}

		init(name: String, description: String, cut: UFix64, receiver: Address, extra: {String : String}) {
			self.name = name
			self.description = description
			self.cut = cut
			self.receiver = receiver
			self.extra = extra
		}
	}

	access(all) struct interface Cut {
		access(all) getName() : String
		access(all) getReceiverCap() : Capability<&{FungibleToken.Receiver}>
		access(all) getCut() : UFix64
		access(all) getAddress() : Address
		access(all) getDescription() : String
		access(all) getPayableLogic() : ((UFix64) : UFix64?)
		access(all) getExtra() : {String : String}

		access(all) getRoyalty() : MetadataViews.Royalty {
			let cap = self.getReceiverCap()
			return MetadataViews.Royalty(receiver: cap, cut: self.getCut(), description: self.getName())
		}

		access(all) getAmountPayable(_ salePrice: UFix64) : UFix64? {
			if let cut = self.getPayableLogic()(salePrice) {
				return cut
			}
			return nil
		}

		access(all) getEventSafeCut() : EventSafeCut {
			return EventSafeCut(
				name: self.getName(),
				description: self.getDescription(),
				cut: self.getCut(),
				receiver: self.getAddress(),
				extra: self.getExtra()
			)
		}
	}

	access(all) struct GeneralCut : Cut {
		// This is the description of the royalty struct
		access(all) let name : String
		access(all) let cap: Capability<&{FungibleToken.Receiver}>
		access(all) let cut: UFix64
		// This is the description to the cut that can be visible to give detail on detail page
		access(all) let description: String
		access(self) let extra : {String : AnyStruct}

		init(name : String, cap: Capability<&{FungibleToken.Receiver}>, cut: UFix64, description: String) {
			self.name = name
			self.cap = cap
			self.cut = cut
			self.description = description
			self.extra = {}
		}

		access(all) getReceiverCap() : Capability<&{FungibleToken.Receiver}> {
			return self.cap
		}
		access(all) getName() : String {
			return self.name
		}
		access(all) getCut() : UFix64 {
			return self.cut
		}
		access(all) getAddress() : Address {
			return self.cap.address
		}
		access(all) getDescription() : String {
			return self.description
		}
		access(all) getExtra() : {String : String} {
			return {}
		}

		access(all) getPayableLogic() : ((UFix64) : UFix64?) {
			return fun(_ salePrice : UFix64) : UFix64? {
				return salePrice * self.cut
			}
		}
	}

	access(all) struct ThresholdCut : Cut {
		// This is the description of the royalty struct
		access(all) let name : String
		access(all) let address: Address
		access(all) let cut: UFix64
		// This is the description to the cut that can be visible to give detail on detail page
		access(all) let description: String
		access(all) let publicPath: String
		access(all) let minimumPayment: UFix64
		access(self) let extra : {String : AnyStruct}

		init(name : String , address: Address , cut: UFix64 , description: String , publicPath: String, minimumPayment: UFix64) {
			self.name = name
			self.address = address
			self.cut = cut
			self.description = description
			self.publicPath = publicPath
			self.minimumPayment = minimumPayment
			self.extra = {}
		}

		access(all) getReceiverCap() : Capability<&{FungibleToken.Receiver}> {
			let pp = PublicPath(identifier: self.publicPath)!
			return getAccount(self.address).getCapability<&{FungibleToken.Receiver}>(pp)
		}
		access(all) getName() : String {
			return self.name
		}
		access(all) getCut() : UFix64 {
			return self.cut
		}
		access(all) getAddress() : Address {
			return self.address
		}
		access(all) getDescription() : String {
			return self.description
		}
		access(all) getExtra() : {String : String} {
			return {}
		}

		access(all) getPayableLogic() : ((UFix64) : UFix64?) {
			return fun(_ salePrice : UFix64) : UFix64? {
				let rPayable = salePrice * self.cut
				if rPayable < self.minimumPayment {
					return self.minimumPayment
				}
				return rPayable
			}
		}
	}

}
