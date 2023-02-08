# .find

.find is a solution that aims to make it easier to .find people and their things on the flow blockchain. It is live on mainnet since Dec 13th 2021 at https://find.xyz


## Product .find

 - Name Services
 - Assets Browser
 - Marketplace
 - Launchpad
 - Find Thoughts

Find out more by surfing find.xyz

## Infrastructures .find
 - Name services
 - Assets Management
 - Marketplace
 - NFT Forger
 - NFT Pack
 - Community Tools Wrapper
 - Social Networking Tools
 - User Profile
 - Related Accounts


### Name services Contracts

[FIND](./contracts/FIND.cdc) contract is the heart of the FIND name service.
It defines a name lease (which is not implementing NFT standard therefore it is not an NFT), and the usage around it.

A Lease is a permission to own and use the domain name within a period of time (in .find's case that would be an year since register in general.) Lease owner can link themselves and their wallet address with ${name}.find. Smart contracts that implement FIND can resolve the lease owner address and tell who that is without sending in the clumsy and unreadable length wallet address.

#### Lease Attribute
Leases are created and handled as resource on flow. So that they are properly handled and stored.

Attributes :
name - name of the lease
networkCap - link to the network (In find we support multiple tenant, so lease can be connected to different network at creation, creating name services for different tenant)
market information - sale / auction / offer prices and details
addons - .find leases can support add ons to the name itself.

#### Interaction

```cadence
	// resolve takes a string address or a find name and returns an address if valid
	pub fun resolve(_ input:String) : Address?

	// lookupAddress look up the address of a find name, and return the owner if there is one (and if the lease is still valid / active)
	pub fun lookupAddress(_ name:String): Address?

	// lookup looks up the find name owner's profile public interface if there is one
	pub fun lookup(_ input:String): &{Profile.Public}?

	// reverse lookup looks up the address for the user's find name
	// If they have set a find name, then return the find name
	// If they haven't set a find name, return the first name that comes up in the array
	pub fun reverseLookup(_ address:Address): String?

	// status returns the status of a find name
	// For find lease we have 3 states
	// pub case FREE - It is not owned and free to take
	// pub case TAKEN - It is already taken and in use by someone
	// pub case LOCKED - The lease is expired now, but the lease will be locked only to the previous owner who has 3-month-time to renew it
	//
	pub fun status(_ name: String): NameStatus

	// depositWithTagAndMessage sends fund from sender to user with / without profile and emit very good events
	// for users with profile, it supports as much FT as they've set up wallets in profile
	// for users without profile, we support flow and FUSD at the moment but it can be extended pretty easily
	pub fun depositWithTagAndMessage(to:String, message:String, tag: String, vault: @FungibleToken.Vault, from: &Sender.Token)



