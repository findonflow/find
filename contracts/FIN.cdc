

import FungibleToken from "./standard/FungibleToken.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import Profile from "./Profile.cdc"

pub contract FIN {

	pub let NetworkStoragePath: StoragePath
	pub let NetworkPrivatePath: PrivatePath
	pub let AdministratorPrivatePath: PrivatePath
	pub let AdministratorStoragePath: StoragePath
	pub let AdminClientPublicPath: PublicPath
	pub let AdminClientStoragePath: StoragePath

	access(contract) var networkCap: Capability<&Network>?


	//These methods are basically just here for convenience
	pub fun calculateCost(_ tag:String) : UFix64 {
		pre {
			self.networkCap != nil : "Network is not set up"
		}
		return self.networkCap!.borrow()!.calculateCost(tag)
	}

	pub fun lookup(_ tag:String): &{Profile.Public}? {
		pre {
			self.networkCap != nil : "Network is not set up"
		}
		return self.networkCap!.borrow()!.lookup(tag)
	}

	pub fun deposit(to:String, from: @FungibleToken.Vault) {
		pre {
			self.networkCap != nil : "Network is not set up"
		}
		let profile=self.lookup(to) ?? panic("could not find tag")
		profile.deposit(from: <- from)
	}

	pub fun status(_ tag: String): LeaseStatus {
		pre {
			self.networkCap != nil : "Network is not set up"
		}
		return self.networkCap!.borrow()!.status(tag)
	}

	pub fun register(tag: String, vault: @FungibleToken.Vault, profile: Capability<&{Profile.Public}>) {
		pre {
			self.networkCap != nil : "Network is not set up"
		}
		self.networkCap!.borrow()!.register(tag:tag, vault: <- vault, profile: profile)
	}

	//TODO: Should this be renamed to Minter? To Mint networks?
	pub resource Administrator {

		pub fun createNetwork(
			leasePeriod: UFix64, 
			lockPeriod: UFix64, 
			wallet:Capability<&{FungibleToken.Receiver}>
		): @Network {
			return  <-  create Network(
				leasePeriod: leasePeriod,
				lockPeriod: lockPeriod,
				wallet: wallet
			)
		}

	}


	pub fun createAdminClient() : @Admin {
		return <- create Admin()
	}

	pub resource interface AdminClient {
		pub fun addCapability(_ cap: Capability<&Administrator>)
	}

	pub resource Admin: AdminClient {

		access(self) var capability: Capability<&Administrator>?

		init() {
			self.capability = nil
		}

		pub fun addCapability(_ cap: Capability<&Administrator>) {
			pre {
				cap.check() : "Invalid server capablity"
				self.capability == nil : "Server already set"
			}
			self.capability = cap
		}

		pub fun createNetwork(
			admin: AuthAccount,
			leasePeriod: UFix64, 
			lockPeriod: UFix64, 
			wallet:Capability<&{FungibleToken.Receiver}>) {

				pre {
					self.capability != nil: "Cannot create FIN, capability is not set"
				}

				let network <- self.capability!.borrow()!.createNetwork(
					leasePeriod: leasePeriod,
					lockPeriod: lockPeriod,
					wallet: wallet
				)
				admin.save(<-network, to: FIN.NetworkStoragePath)
				admin.link<&Network>( FIN.NetworkPrivatePath, target: FIN.NetworkStoragePath)
				FIN.networkCap= admin.getCapability<&Network>(FIN.NetworkPrivatePath)
			}
		}



		pub struct NetworkLease {
			pub(set) var status: LeaseStatus
			pub(set) var time: UFix64
			pub(set) var profile: Capability<&{Profile.Public}>
			pub var address: Address
			pub var tag: String

			init(status:LeaseStatus, time:UFix64, profile: Capability<&{Profile.Public}>, tag: String) {
				self.status=status
				self.time=time
				self.profile=profile
				self.address= profile.borrow()!.owner!.address
				self.tag=tag
			}

		}


		/*
		FREE, does not exist in profiles dictionary
		TAKEN, registered with a time that is currentTime + leasePeriod
		LOCKED, after TAKEN.time you will get a new  status and the new time will be 

		*/

		pub enum LeaseStatus: UInt8 {
			pub case FREE
			pub case TAKEN
			pub case LOCKED
		}

		pub resource Network  {

			access(contract) let wallet: Capability<&{FungibleToken.Receiver}>
			access(contract) var leasePeriod: UFix64
			access(contract) var lockPeriod: UFix64

			access(contract) let profiles: { String: NetworkLease}
			access(contract) let addresses: { Address: NetworkLease}

			init(leasePeriod: UFix64, lockPeriod: UFix64, wallet:Capability<&{FungibleToken.Receiver}>) {
				self.leasePeriod=leasePeriod
				self.lockPeriod=lockPeriod
				self.profiles={}
				self.addresses={}
				self.wallet=wallet
			}

			pub fun register(tag: String, vault: @FungibleToken.Vault, profile: Capability<&{Profile.Public}>) {

				let status=self.status(tag)
				if status == LeaseStatus.TAKEN {
					panic("Tag already registered")
				}

				let registrant= profile.borrow()!.owner!.address
				//if we have a locked profile that is not owned by the same identity then panic
				if status == LeaseStatus.LOCKED && self.profiles[tag]!.address != registrant {
					panic("Tag is locked")
				}

				let cost= self.calculateCost(tag)
				if vault.balance != cost {
					panic("Vault did not contain ".concat(cost.toString()).concat(" amount of flow"))
				}
				self.wallet.borrow()!.deposit(from: <- vault)

				let block=getCurrentBlock()

				let lease= NetworkLease(
					status: LeaseStatus.TAKEN,
					time:block.timestamp + self.leasePeriod,
					profile: profile,
					tag: tag
				)

				self.profiles[tag] =  lease
				self.addresses[registrant] = lease
			}

			pub fun status(_ tag: String): LeaseStatus {
				let currentTime=getCurrentBlock().timestamp
				log("Check status at time=".concat(currentTime.toString()))
				if let  lease= self.profiles[tag] {
					let owner=lease.profile.borrow()!.owner!.address
					log("lease time is=".concat(lease.time.toString()))
					let diff= Int64(lease.time) - Int64(currentTime)
					log("time diff is=".concat(diff.toString()))
					log("lease status was=".concat(lease.status.rawValue.toString()))
					if currentTime <= lease.time {
						log("Still valid")
						return lease.status
					}

					if lease.status == LeaseStatus.LOCKED {
						self.profiles.remove(key: tag)
						self.addresses.remove(key: owner)
						log("was locked that is expired")
						return LeaseStatus.FREE
					}

					if lease.status == LeaseStatus.TAKEN {
						lease.status= LeaseStatus.LOCKED
						log("lock period is")
						log(self.lockPeriod)
						lease.time = currentTime + self.lockPeriod
						self.profiles[tag] = lease
						self.addresses[owner] = lease
						log("was taken is now locked")
						log(lease.time)
						log(lease.status)
					}
					return lease.status
				}
				log("FREE")
				return LeaseStatus.FREE
			}

			pub fun lookup(_ tag: String) : &{Profile.Public}? {
				let status=self.status(tag)
				if status != LeaseStatus.TAKEN {
					return nil
				}

				if let lease=self.profiles[tag] {
					return lease.profile.borrow()
				}
				return nil
			}

			/*
			  Do we want to be able to set the parameters?
			*/
			pub fun calculateCost(_ tag: String) : UFix64 {
				let length= tag.length

				if length==3 {
					return 500.0
				} else if length == 4 {
					return 100.0
				} else   {
					return 5.0
				}
			}

			pub fun setLeasePeriod(_ period: UFix64)  {
				self.leasePeriod=period
			}

			pub fun setLockPeriod(_ period: UFix64) {
				self.lockPeriod=period
			}

		}

		init() {
			self.NetworkPrivatePath= /private/FIN
			self.NetworkStoragePath= /storage/FIN
			self.AdministratorStoragePath=/storage/finAdmin
			self.AdministratorPrivatePath=/private/finAdmin
			self.AdminClientPublicPath= /public/finAdminClient
			self.AdminClientStoragePath=/storage/finAdminClient
			self.account.save(<- create Administrator(), to: self.AdministratorStoragePath)
			self.account.link<&Administrator>(self.AdministratorPrivatePath, target: self.AdministratorStoragePath) 
			self.networkCap = nil
		}



	}
