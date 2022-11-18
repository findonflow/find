
pub contract PartyFavorzExtraData {
	pub let extraData : {UInt64 : {String : AnyStruct}}

	access(account) fun setData(id: UInt64, field: String, value: AnyStruct) {
		let previousData = self.extraData[id] ?? {}
		previousData[field] = value
		self.extraData[id] = previousData
	}

	access(account) fun removeData(id: UInt64, field: String) {
		pre{
			self.extraData.containsKey(id) : "Extra data for ID : ".concat(id.toString()).concat(" does not exist")
			self.extraData[id]!.containsKey(field) : "Field does not exist : ".concat(field)
		}
		
		self.extraData[id]!.remove(key: field)!
	}

	pub fun getData(id: UInt64, field: String) : AnyStruct? {
		let partyfavorz = self.extraData[id]
		if partyfavorz == nil {
			return nil
		}
		return partyfavorz![field]
	}

	init(){
		self.extraData = {}
	}
}