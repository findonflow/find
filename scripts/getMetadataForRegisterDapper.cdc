import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import FIND from "../contracts/FIND.cdc"

pub fun main(merchAccount: Address, name: String, amount: UFix64) : PurchaseData {

	let price = FIND.calculateCost(name)
	if amount != price {
		panic("Amount passed in does not match. Required price : ".concat(price.toString()))
	}
	let nameStatus=FIND.status(name)
	if nameStatus.status == FIND.LeaseStatus.TAKEN {
		panic("Name already registered")
	}

	if nameStatus.status == FIND.LeaseStatus.LOCKED {
		panic("Name is locked")
	}
	let description = "Name :".concat(name).concat(" for Dapper Credit ").concat(amount.toString())
	let imageURL = "https://i.imgur.com/8W8NoO1.png"

	return PurchaseData(
			// what should we put here?
			id: 0, 
			name: name, 
			amount: amount, 
			description: description, 
			imageURL: imageURL
			)

}

pub struct PurchaseData {
	pub let id: UInt64
	pub let name: String
	pub let amount: UFix64
	pub let description: String
	pub let imageURL: String

	init(id: UInt64, name: String, amount: UFix64, description: String, imageURL: String) {
		self.id = id
		self.name = name
		self.amount = amount
		self.description = description
		self.imageURL = imageURL
	}
}