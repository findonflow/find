import FungibleToken from "./standard/FungibleToken.cdc"
import FUSD from "./standard/FUSD.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import Profile from "./Profile.cdc"
import FIND from "./FIND.cdc"
import Debug from "./Debug.cdc"
import Dandy from "./Dandy.cdc"
import Clock from "./Clock.cdc"
import CharityNFT from "./CharityNFT.cdc"

pub contract Admin {

	//store the proxy for the admin
	pub let AdminProxyPublicPath: PublicPath
	pub let AdminProxyStoragePath: StoragePath


	/// ===================================================================================
	// Admin things
	/// ===================================================================================

	//Admin client to use for capability receiver pattern
	pub fun createAdminProxyClient() : @AdminProxy {
		return <- create AdminProxy()
	}

	//interface to use for capability receiver pattern
	pub resource interface AdminProxyClient {
		pub fun addCapability(_ cap: Capability<&FIND.Network>)
	}


	//admin proxy with capability receiver 
	pub resource AdminProxy: AdminProxyClient {

		access(self) var capability: Capability<&FIND.Network>?

		pub fun addCapability(_ cap: Capability<&FIND.Network>) {
			pre {
				cap.check() : "Invalid server capablity"
				self.capability == nil : "Server already set"
			}
			self.capability = cap
		}

		/// Set the wallet used for the network
		/// @param _ The FT receiver to send the money to
		pub fun setWallet(_ wallet: Capability<&{FungibleToken.Receiver}>) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			self.capability!.borrow()!.setWallet(wallet)
		}

		/// Enable or disable public registration 
		pub fun setPublicEnabled(_ enabled: Bool) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			self.capability!.borrow()!.setPublicEnabled(enabled)
		}

		pub fun setAddonPrice(name: String, price: UFix64) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			self.capability!.borrow()!.setAddonPrice(name: name, price: price)
		}

		pub fun setPrice(default: UFix64, additional : {Int: UFix64}) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			self.capability!.borrow()!.setPrice(default: default, additionalPrices: additional)
		}

		pub fun register(name: String, profile: Capability<&{Profile.Public}>, leases: Capability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>){
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
				FIND.validateFindName(name) : "A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters"
			}

			self.capability!.borrow()!.internal_register(name:name, profile: profile, leases: leases)
		}

		pub fun mintCharity(metadata : {String: String}, recipient: Capability<&{NonFungibleToken.CollectionPublic}>){
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			CharityNFT.mintCharity(metadata: metadata, recipient: recipient)
		}

		pub fun advanceClock(_ time: UFix64) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			Debug.enable(true)
			Clock.enable()
			Clock.tick(time)
		}


		pub fun debug(_ value: Bool) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			Debug.enable(value)
		}

		pub fun setViewConverters(from: Type, converters: [{TypedMetadata.ViewConverter}]) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			Dandy.setViewConverters(from: from, converters: converters)
		}

		pub fun createForge(platform: Dandy.MinterPlatform) : @Dandy.Forge {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			return <- Dandy.createForge(platform:platform)
		}



		init() {
			self.capability = nil
		}

	}

	init() {

		self.AdminProxyPublicPath= /public/findAdminProxy
		self.AdminProxyStoragePath=/storage/findAdminProxy
	}

}
