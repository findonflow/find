import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"

pub contract FindMarketCutStruct {

	pub struct Cuts {
		pub let cuts : [{Cut}]
		access(contract) let extra: {String : AnyStruct}

		init(cuts: [{Cut}]) {
			self.cuts = cuts
			self.extra = {}
		}

		pub fun getEventSafeCuts() : [EventSafeCut] {
			let cuts : [EventSafeCut] = []
			for c in self.cuts {
				cuts.append(c.getEventSafeCut())
			}
			return cuts
		}
	}

	pub struct EventSafeCut {
		pub let name: String
		pub let description: String
		pub let cut: UFix64
		pub let receiver: Address
		pub let extra: {String : String}

		init(name: String, description: String, cut: UFix64, receiver: Address, extra: {String : String}) {
			self.name = name
			self.description = description
			self.cut = cut
			self.receiver = receiver
			self.extra = extra
		}
	}

	pub struct interface Cut {
		pub fun getName() : String
		pub fun getReceiverCap() : Capability<&{FungibleToken.Receiver}>
		pub fun getCut() : UFix64
		pub fun getAddress() : Address
		pub fun getDescription() : String
		pub fun getPayableLogic() : ((UFix64) : UFix64?)
		pub fun getExtra() : {String : String}

		pub fun getRoyalty() : MetadataViews.Royalty {
			let cap = self.getReceiverCap()
			return MetadataViews.Royalty(receiver: cap, cut: self.getCut(), description: self.getName())
		}

		pub fun getAmountPayable(_ salePrice: UFix64) : UFix64? {
			if let cut = self.getPayableLogic()(salePrice) {
				return cut
			}
			return nil
		}

		pub fun getEventSafeCut() : EventSafeCut {
			return EventSafeCut(
				name: self.getName(),
				description: self.getDescription(),
				cut: self.getCut(),
				receiver: self.getAddress(),
				extra: self.getExtra()
			)
		}
	}

	pub struct GeneralCut : Cut {
		// This is the description of the royalty struct
		pub let name : String
		pub let cap: Capability<&{FungibleToken.Receiver}>
		pub let cut: UFix64
		// This is the description to the cut that can be visible to give detail on detail page
		pub let description: String
		access(self) let extra : {String : AnyStruct}

		init(name : String, cap: Capability<&{FungibleToken.Receiver}>, cut: UFix64, description: String) {
			self.name = name
			self.cap = cap
			self.cut = cut
			self.description = description
			self.extra = {}
		}

		pub fun getReceiverCap() : Capability<&{FungibleToken.Receiver}> {
			return self.cap
		}
		pub fun getName() : String {
			return self.name
		}
		pub fun getCut() : UFix64 {
			return self.cut
		}
		pub fun getAddress() : Address {
			return self.cap.address
		}
		pub fun getDescription() : String {
			return self.description
		}
		pub fun getExtra() : {String : String} {
			return {}
		}

		pub fun getPayableLogic() : ((UFix64) : UFix64?) {
			return fun(_ salePrice : UFix64) : UFix64? {
				return salePrice * self.cut
			}
		}
	}

	pub struct ThresholdCut : Cut {
		// This is the description of the royalty struct
		pub let name : String
		pub let address: Address
		pub let cut: UFix64
		// This is the description to the cut that can be visible to give detail on detail page
		pub let description: String
		pub let publicPath: String
		pub let minimumPayment: UFix64?
		access(self) let extra : {String : AnyStruct}

		init(name : String , address: Address , cut: UFix64 , description: String , publicPath: String, minimumPayment: UFix64?) {
			self.name = name
			self.address = address
			self.cut = cut
			self.description = description
			self.publicPath = publicPath
			self.minimumPayment = minimumPayment
			self.extra = {}
		}

		pub fun getReceiverCap() : Capability<&{FungibleToken.Receiver}> {
			let pp = PublicPath(identifier: self.publicPath)!
			return getAccount(self.address).getCapability<&{FungibleToken.Receiver}>(pp)
		}
		pub fun getName() : String {
			return self.name
		}
		pub fun getCut() : UFix64 {
			return self.cut
		}
		pub fun getAddress() : Address {
			return self.address
		}
		pub fun getDescription() : String {
			return self.description
		}
		pub fun getExtra() : {String : String} {
			return {}
		}

		pub fun getPayableLogic() : ((UFix64) : UFix64?) {
			return fun(_ salePrice : UFix64) : UFix64? {
				let rPayable = salePrice * self.cut
				if self.minimumPayment != nil && rPayable < self.minimumPayment! {
					return self.minimumPayment!
				}
				return rPayable
			}
		}
	}

}
