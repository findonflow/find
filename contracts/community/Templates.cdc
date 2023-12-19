// SPDX-License-Identifier: MIT
import MetadataViews from "../standard/MetadataViews.cdc"
import FungibleToken from "../standard/FungibleToken.cdc"

// This contracts stores all the defined interfaces and structs.
// Interfaces can span on both Characters and Wearables therefore it is better to have them in a central contract
access(all) contract Templates {

	access(contract) let counters : {String : UInt64}
	access(contract) let features : {String : Bool}

	pub event CountersReset()

	access(account) fun createEditionInfoManually(name: String, counter:String, edition:UInt64?) : EditionInfo {
		let oldMax=Templates.counters[counter] ?? 0
		if let e = edition {
			// If edition is passed in, check if the edition is larger than the existing max.
			// If so, set it as max, otherwise just mint with edition
			if e > oldMax {
				Templates.counters[counter] = e
			}
			return EditionInfo(counter: counter, name:name, number:e)
		}
		// If edition is NOT passed in, increment by 1 and set new max as edition
		let max=oldMax+1
		Templates.counters[counter] = max
		return EditionInfo(counter: counter, name:name, number:max)
	}

	pub struct interface Editionable {

		access(all) getCounterSuffix() : String
		// e.g. set , position
		access(all) getClassifier() : String
		// e.g. character, wearable
		access(all) getContract() : String

		access(all) getCounter() : String {
			return self.getContract().concat("_").concat(self.getClassifier()).concat("_").concat(self.getCounterSuffix())
		}

		access(account) fun createEditionInfo(_ edition: UInt64?) : EditionInfo {
			return Templates.createEditionInfoManually(name:self.getClassifier(), counter:self.getCounter(), edition:edition)
		}

		access(all) getCurrentCount() : UInt64 {
			return Templates.counters[self.getCounter()] ?? 0
		}

	}

	pub struct interface Retirable{

		pub var active:Bool

		access(all) getCounterSuffix() : String
		access(all) getClassifier() : String
		access(all) getContract() : String

		access(account) fun enable(_ bool : Bool) {
			pre{
				self.active : self.getContract().concat("-").concat(self.getClassifier()).concat(" is already retired : ").concat(self.getCounterSuffix())
			}
			self.active = bool
		}
	}

	pub struct interface RoyaltyHolder {
		pub let royalties: [Templates.Royalty]

		access(all) getRoyalties() : [MetadataViews.Royalty] {
			let royalty : [MetadataViews.Royalty] = []
			for r in self.royalties {
				royalty.append(r.getRoyalty())
			}
			return royalty
		}
	}

	pub struct EditionInfo {
		pub let counter :String
		pub let name : String
		pub let number:UInt64

		init(counter: String, name:String, number:UInt64) {
			self.counter=counter
			self.name=name
			self.number=number
		}

		access(all) getSupply() : UInt64 {
			return Templates.counters[self.counter] ?? 0
		}

		access(all) getAsMetadataEdition(_ active:Bool) : MetadataViews.Edition {
			var max : UInt64?=nil
			if !active  {
				max=Templates.counters[self.counter]
			}
			return MetadataViews.Edition(name:self.name, number:self.number, max:max)
		}

		access(all) getMaxEdition() : UInt64 {
			return Templates.counters[self.counter]!
		}

	}

	pub struct Royalty {
		pub let name : String
		pub let address: Address
		pub let cut: UFix64
		pub let description: String
		pub let publicPath: String

		init(name : String , address: Address , cut: UFix64 , description: String , publicPath: String) {
			self.name = name
			self.address = address
			self.cut = cut
			self.description = description
			self.publicPath = publicPath
		}

		access(all) getPublicPath() : PublicPath {
			return PublicPath(identifier: self.publicPath)!
		}

		access(all) getRoyalty() : MetadataViews.Royalty {
			let cap = getAccount(self.address).getCapability<&{FungibleToken.Receiver}>(self.getPublicPath())
			return MetadataViews.Royalty(receiver: cap, cut: self.cut, description: self.name)
		}

	}

	access(all) featureEnabled(_ action: String) : Bool {
		return self.features[action] ?? false
	}

	access(all) assertFeatureEnabled(_ action: String) {
		if !Templates.featureEnabled(action) {
			panic("Action cannot be taken, feature is not enabled : ".concat(action))
		}
	}

	access(account) fun resetCounters() {
		// The counter is in let, therefore we have to do this.
		for key in self.counters.keys {
			self.counters.remove(key: key)
		}
		emit CountersReset()
	}

	access(account) fun setFeature(action: String, enabled: Bool) {
		self.features[action] = enabled
	}

	init() {
		self.counters = {}
		self.features = {}
	}

}
