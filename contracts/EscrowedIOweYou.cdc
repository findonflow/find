import FungibleToken from "./standard/FungibleToken.cdc"
import IOweYou from "./IOweYou.cdc"

pub contract EscrowedIOweYou {

	pub event IOUCreated(uuid: UInt64, by:Address?, type: String, amount: UFix64)
	pub event IOUToppedUp(uuid: UInt64, by:Address?, type: String, amount: UFix64, fromAmount: UFix64, toAmount: UFix64)
	pub event IOURedeemed(uuid: UInt64, by:Address?, type: String, amount: UFix64)
	pub event IOURedeemFailed(uuid: UInt64, by:Address?, type: String, amount: UFix64, reason: String)
	pub event IOUWithdrawn(uuid: UInt64, from: Address?, type: String, amount: UFix64)
	pub event IOUDesposited(uuid: UInt64, to: Address?, type: String, amount: UFix64)

	pub let CollectionStoragePath : StoragePath
	pub let CollectionPublicPath : PublicPath

	pub resource IOU : IOweYou.IOU {
		pub let vaultType : Type 
		pub var balance : UFix64 
		pub let receiver : Capability<&{FungibleToken.Receiver}>
		access(self) let vault : @FungibleToken.Vault

		init(vault: @FungibleToken.Vault, receiver: Capability<&{FungibleToken.Receiver}>) {
			self.receiver = receiver
			self.vaultType = vault.getType()
			self.balance = vault.balance
			self.vault <- vault
		}

		destroy() {
			if self.vault.balance != 0.0 {
				if !self.receiver.check() {
					panic("Cannot destroy this IOU. The balance of the IOU is not empty")
				}
				self.receiver.borrow()!.deposit(from: <- self.vault.withdraw(amount: self.vault.balance))
			}
			destroy self.vault
		}

		pub fun topUp(_ vault: @FungibleToken.Vault) {
			pre{
				self.vaultType == vault.getType() : "The vault type passed in does not match with the redeeming iou. Required vault type : ".concat(self.vaultType.identifier)
			}
			emit IOUToppedUp(uuid: self.uuid, by: self.owner?.address, type: self.vaultType.identifier, amount: vault.balance, fromAmount: self.balance, toAmount: self.balance + vault.balance)
			self.balance = self.balance + vault.balance
			self.vault.deposit(from: <- vault)
		}

		access(contract) fun redeem() : @FungibleToken.Vault {
			return <- self.vault.withdraw(amount: self.vault.balance)
		}

	}

	pub resource Collection : IOweYou.CollectionPublic , IOweYou.Owner { 
		access(self) let ownedIOUs : @{UInt64 : IOU}

		// Fungible Token Receiver to receive all sorts of redeeming FTs
		pub let receiver : Capability<&{FungibleToken.Receiver}>

		// Not sure if we need this here
		pub let IOUTypes : {Type : [UInt64]}

		init(_ receiver: Capability<&{FungibleToken.Receiver}>){
			self.ownedIOUs <- {} 
			self.IOUTypes = {}
			self.receiver = receiver
		}

		destroy() {
			destroy self.ownedIOUs
		}

		pub fun getIOUs() : [UInt64] {
			return self.ownedIOUs.keys
		}
		
		pub fun containsIOU(_ id: UInt64) : Bool {
			return self.ownedIOUs.containsKey(id)
		}

		pub fun deposit(_ token: @{IOweYou.IOU}) {
			pre{
				token.getType() == Type<@EscrowedIOweYou.IOU>() : "Please pass in the correct type of resource : ".concat(Type<@EscrowedIOweYou.IOU>().identifier)
			}
			let iou <- token as! @EscrowedIOweYou.IOU 
			emit IOUDesposited(uuid: iou.uuid, to: self.owner?.address, type: iou.vaultType.identifier, amount: iou.balance)

			let iouTypes = self.IOUTypes[iou.vaultType] ?? []
			iouTypes.append(iou.uuid)
			self.IOUTypes[iou.vaultType] = iouTypes

			self.ownedIOUs[iou.uuid] <-! iou
		}

		pub fun depositAndRedeemToAccount(token: @{IOweYou.IOU}, vault: @FungibleToken.Vault?) {
			pre{
				vault == nil : "Please pass in nil to redeem Escrowed IOUs"
				token.getType() == Type<@EscrowedIOweYou.IOU>() : "Please pass in the correct type of resource : ".concat(Type<@EscrowedIOweYou.IOU>().identifier)
			}
			destroy vault
			let iou <- token as! @EscrowedIOweYou.IOU 
			if self.receiver.check(){
				emit IOURedeemed(uuid: iou.uuid, by:self.owner?.address, type: iou.vaultType.identifier, amount: iou.balance)
				let vault <- iou.redeem()
				destroy iou 
				self.receiver.borrow()!.deposit(from: <- vault)
				return 
			} 
			
			emit IOURedeemFailed(uuid: iou.uuid, by:self.owner?.address, type: iou.vaultType.identifier, amount: iou.balance, reason: "Invalid receiver capability. Account : ".concat(self.receiver.address.toString()))
			emit IOUDesposited(uuid: iou.uuid, to: self.owner?.address, type: iou.vaultType.identifier, amount: iou.balance)
			let iouTypes = self.IOUTypes[iou.vaultType] ?? []
			iouTypes.append(iou.uuid)
			self.IOUTypes[iou.vaultType] = iouTypes

			self.ownedIOUs[iou.uuid] <-! iou
		}

		pub fun redeem(token: @{IOweYou.IOU}, vault: @FungibleToken.Vault?) : @FungibleToken.Vault {
			pre{
				vault == nil : "Please pass in nil to redeem Escrowed IOUs"
				token.getType() == Type<@EscrowedIOweYou.IOU>() : "Please pass in the correct type of resource : ".concat(Type<@EscrowedIOweYou.IOU>().identifier)
			}
			destroy vault
			let iou <- token as! @EscrowedIOweYou.IOU 
			emit IOURedeemed(uuid: iou.uuid, by:self.owner?.address, type: iou.vaultType.identifier, amount: iou.balance)
			let vault <- iou.redeem()
			destroy iou 
			return <- vault
		}

		pub fun redeemToAccount(id: UInt64, vault: @FungibleToken.Vault?) {
			pre{
				vault == nil : "Please pass in nil to redeem Escrowed IOUs"
				self.receiver.check() : "Invalid receiver capability. Account : ".concat(self.receiver.address.toString())
			}
			destroy vault
			let iou <- self.withdraw(id)

			emit IOURedeemed(uuid: iou.uuid, by:self.owner?.address, type: iou.vaultType.identifier, amount: iou.balance)
			let vault <- iou.redeem()
			destroy iou 
			self.receiver.borrow()!.deposit(from: <- vault)
			return 
		}

		pub fun withdraw(_ id: UInt64) : @IOU {
			pre{
				self.ownedIOUs.containsKey(id) : "Does not contain IOU with uuid : ".concat(id.toString())
			}
			let token <- self.ownedIOUs.remove(key: id)! 
			emit IOUWithdrawn(uuid: token.uuid, from: self.owner?.address, type: token.vaultType.identifier, amount: token.balance)
			return <- token
		}

		pub fun create(_ vault: @FungibleToken.Vault) : @IOU {
			pre {
				!IOweYou.DapperCoinTypes.contains(vault.getType()) : "Please use other resource types for Dapper Utility Coin types"
			}
			let iou <- create IOU(vault: <- vault, receiver: self.receiver)
			emit IOUCreated(uuid: iou.uuid, by: self.owner?.address, type: iou.vaultType.identifier, amount: iou.balance)
			return <- iou
		}

		pub fun topUp(id: UInt64, vault: @FungibleToken.Vault) {
			let iou = self.borrowIOU(id)
			iou.topUp(<- vault)
		}

		pub fun borrowIOU(_ id: UInt64) : &IOU {
			pre{
				self.ownedIOUs.containsKey(id) : "Does not contain IOU with uuid : ".concat(id.toString())
			}
			return (&self.ownedIOUs[id] as &IOU?)!
		}


	}

	pub fun createEmptyCollection(_ receiver: Capability<&{FungibleToken.Receiver}>) : @Collection {
		return <- create Collection(receiver)
	}

	init(){
		let path = IOweYou.getPathFromType(Type<@EscrowedIOweYou.IOU>())
		self.CollectionStoragePath = StoragePath(identifier: path)!
		self.CollectionPublicPath = PublicPath(identifier: path)!

		IOweYou.addTypePath(type: Type<@EscrowedIOweYou.IOU>(), path: path)
	}

}