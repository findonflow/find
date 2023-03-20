package main

import (
	"os"

	. "github.com/bjartek/overflow"
	"github.com/samber/lo"
	"github.com/sanity-io/litter"
)

func main() {
	network := "mainnet"
	o := Overflow(
		WithNetwork(network),
	)

	input := os.Args[1]

	user := o.Script("getInfo", WithArg("user", input))

	var address string
	user.MarshalPointerAs("/profile/address", &address)

	var paths []string
	user.MarshalPointerAs("/paths", &paths)

	pathChunks := lo.Chunk(paths, 25)

	allReports := map[string][]uint64{}
	for _, c := range pathChunks {
		nfts := o.Script("getNFTIds", WithArg("address", address), WithArg("targetPaths", c))

		var report map[string][]uint64
		nfts.MarshalAs(&report)

		for col, ids := range report {
			allReports[col] = ids
		}

	}

	litter.Dump(allReports)
	collection := "GaiaCollection001"
	itemRes := o.Script("getNFTItems", WithArg("address", address), WithArg("collection", collection), WithArg("ids", allReports[collection]))

	itemRes.Print()

}
