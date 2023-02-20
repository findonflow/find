package main

import (
	. "github.com/bjartek/overflow"
	"github.com/samber/lo"
	"github.com/sanity-io/litter"
)

func main() {

	o := Overflow(
		WithNetwork("mainnet"),
	)

	var paths []string
	err := o.Script(
		`
		import FIND from "../contracts/FIND.cdc"
		pub fun main(address: String): AnyStruct {
			let account = getAuthAccount(FIND.resolve(address)!)
			return account.storagePaths
		  }
		`,
		WithArg("address", "bjartek"),
	).
		MarshalAs(&paths)

	if err != nil {
		panic(err)
	}

	litter.Dump(len(paths))

	chunks := lo.Chunk(paths, 25)

	for _, chunk := range chunks {
		res := o.Script("getAccountByPath",
			WithArg("user", "bjartek"),
			WithArg("targetPaths", chunk),
		)

		if res.Err == nil {
			res.Print()
		} else {
			panic(res.Err.Error())
		}

	}

}
