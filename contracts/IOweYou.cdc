import FungibleToken from "./standard/FungibleToken.cdc"
import DapperUtilityCoin from "./standard/DapperUtilityCoin.cdc"
import FlowUtilityToken from "./standard/FlowUtilityToken.cdc"

// This is a contract that specifies the IOweYou resource interface. 
// IOUs are resources of proof of payments.  
// Pass in a vault to create an equal balance IOU, and redeem the IOU to get the monry back. 
pub contract IOweYou {

	pub var DapperCoinTypes : [Type]
	pub let IOUTypePathMap : {Type : String}

	pub resource interface IOU {
		// Type of the vault 
		pub let vaultType : Type 
		// value of the IOU
		pub var balance : UFix64 
		// receiver Cap of the issuer, if the IOU is destroyed, the funds goes back to the issuer
		pub let receiver : Capability<&{FungibleToken.Receiver}>
		// function to topUp the value of a specific IOU
		pub fun topUp(_ vault: @FungibleToken.Vault)

	}

	pub resource interface CollectionPublic {
		// Fungible Token Receiver for specific typed IOU 
		// For most FTs, this can be Profile receiver (Other switch receivers) 
		// For DUC / FUC, they can have their own receivers 
		pub let receiver : Capability<&{FungibleToken.Receiver}>

		// Do we need these? 
		pub fun getIOUs() : [UInt64]
		pub fun containsIOU(_ id: UInt64) : Bool 

		// Function to deposit the IOU to the collection
		pub fun deposit(_ token: @{IOU})
		// Function to deposit and redeem the IOU for a User to the FT capability they specified in the collection
		pub fun depositAndRedeemToAccount(token: @{IOU}, vault: @FungibleToken.Vault?)
	}

	pub resource interface Owner {
		pub let receiver : Capability<&{FungibleToken.Receiver}>
		pub fun getIOUs() : [UInt64]
		pub fun containsIOU(_ id: UInt64) : Bool 
		pub fun deposit(_ token: @{IOU})
		pub fun depositAndRedeemToAccount(token: @{IOU}, vault: @FungibleToken.Vault?)
		pub fun redeemToAccount(id: UInt64, vault: @FungibleToken.Vault?)
		pub fun redeem(token: @{IOU}, vault: @FungibleToken.Vault?) : @FungibleToken.Vault
	}

	access(account) fun changeDapperCoinTypes(_ types : [Type]) {
		self.DapperCoinTypes = types
	}

	access(account) fun addTypePath(type : Type, path: String) {
		pre{
			type.isSubtype(of: Type<&{IOweYou.IOU}>()) : "The type passed in is not implementing IOU Interface. Type : ".concat(type.identifier)
		}

	}

	pub fun getPathFromType(_ type: Type) : String {
			let identifier=type.identifier

		var i=0
		var newIdentifier=""
		while i < identifier.length {

			let item= identifier.slice(from: i, upTo: i+1) 
			if item=="." {
				newIdentifier=newIdentifier.concat("_")
			} else {
				newIdentifier=newIdentifier.concat(item)
			}
			i=i+1
		}
		return newIdentifier
	}

	init(){
		self.DapperCoinTypes=[
			Type<@DapperUtilityCoin.Vault>(),
			Type<@FlowUtilityToken.Vault>()
		]

		self.IOUTypePathMap = {}
	}
}