package main

import (
	. "github.com/bjartek/overflow"
)

func main() {

	o := Overflow(
		WithNetwork("mainnet"),
	)

	// var paths []string
	// err := o.Script(
	// 	`
	// 	import FIND from "../contracts/FIND.cdc"
	// 	pub fun main(address: String): AnyStruct {
	// 		let account = getAuthAccount(FIND.resolve(address)!)
	// 		return account.storagePaths
	// 	  }
	// 	`,
	// 	WithArg("address", "bam"),
	// ).
	// 	MarshalAs(&paths)

	// if err != nil {
	// 	panic(err)
	// }

	// litter.Dump(len(paths))
	// litter.Dump(paths)

	// chunks := lo.Chunk(paths, 25)

	// for _, chunk := range chunks {
	// 	res := o.Script("getAccountByPath",
	// 		WithArg("user", "bam"),
	// 		WithArg("targetPaths", chunk),
	// 	)

	// 	if res.Err == nil {
	// 		res.Print()
	// 	} else {
	// 		panic(res.Err.Error())
	// 	}

	// }

	res := o.Script("getPathNFTDetail",
		WithArg("user", "bjartek"),
		WithArg("path", "/storage/FlovatarCollection"),
		WithArg("id", 4048),
		WithArg("views", []string{}),
	)

	if res.Err == nil {
		res.Print()
	} else {
		panic(res.Err.Error())
	}

}
