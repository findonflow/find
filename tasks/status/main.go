package main

import (
	"fmt"
	"os"

	. "github.com/bjartek/overflow"
	"github.com/samber/lo"
)

func main() {
	network := "mainnet"
	o := Overflow(
		WithNetwork(network),
	)

	input := os.Args[1]

	user := o.Script("getFindStatus", WithArg("user", input))

	var address string
	err := user.MarshalPointerAs("/profile/address", &address)
	if err != nil {
		panic(err)
	}

	var paths []string
	err = user.MarshalPointerAs("/paths", &paths)
	if err != nil {
		panic(err)
	}
	fmt.Println("number of paths", len(paths))

	pathChunks := lo.Chunk(paths, 30)

	allReports := map[string][]uint64{}

	for _, c := range pathChunks {
		nfts := o.Script("getNFTIds", WithArg("address", address), WithArg("targetPaths", c))

		var report map[string][]uint64
		err := nfts.MarshalAs(&report)
		if err != nil {
			panic(err)
		}

		for col, ids := range report {
			allReports[col] = ids
		}

	}

	fmt.Println(len(allReports))
	/*
		collection := "GaiaCollection001"
		itemRes := o.Script("getNFTItems", WithArg("address", address), WithArg("collection", collection), WithArg("ids", allReports[collection]))

		itemRes.Print()
	*/
}
