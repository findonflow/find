import "FIND"

access(all) fun main(merchAccount: Address, name: String, amount: UFix64) : PurchaseData {

	let description = "Renew name :".concat(name).concat(" for DUC ").concat(amount.toString())
	let imageURL = "https://ik.imagekit.io/xyvsisxky/tr:ot-".concat(name).concat(",ots-55,otc-58B792,ox-N166,oy-N24,ott-b/https://i.imgur.com/8W8NoO1.png")

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
