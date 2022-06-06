pub contract CuratedCollection {

	pub let storagePath: StoragePath
	pub let publicPath: PublicPath

	pub resource interface Public {
		pub fun getCuratedCollection() : {String : [String]}
	}

	pub resource Collection : Public {
		pub let curatedCollection : {String : [String]} 

		init() {
			self.curatedCollection = {}
		}

		pub fun getCuratedCollection() : {String : [String]} {
			return self.curatedCollection
		}

		pub fun setCuratedCollection(name: String, items: [String]?) {
			if items == nil {
				self.curatedCollection.remove(key: name)
				return
			}
			self.curatedCollection[name] = items
		}

	}

	pub fun createCuratedCollection() : @Collection {
		return <- create Collection()
	}

	init() {
		self.storagePath = /storage/FindCuratedCollections 
		self.publicPath = /public/FindCuratedCollections
	}

}

