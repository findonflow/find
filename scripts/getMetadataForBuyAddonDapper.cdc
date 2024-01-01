import FIND from "../contracts/FIND.cdc"

access(all) fun main(merchAccount: Address, name: String, addon:String, amount:UFix64) : PurchaseData {
	let description = "Purchase addon ".concat(addon).concat(" for name :").concat(name).concat(" for DUC ").concat(amount.toString())
	let imageURL = "https://i.imgur.com/8W8NoO1.png"

	return PurchaseData(
			id: 0, 
			name: name, 
			amount: amount, 
			description: description, 
			imageURL: imageURL
			)


}

access(all) struct PurchaseData {
	access(all) let id: UInt64
	access(all) let name: String
	access(all) let amount: UFix64
	access(all) let description: String
	access(all) let imageURL: String

	init(id: UInt64, name: String, amount: UFix64, description: String, imageURL: String) {
		self.id = id
		self.name = name
		self.amount = amount
		self.description = description
		self.imageURL = imageURL
	}
}
