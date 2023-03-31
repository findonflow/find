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

	o.Script("getNameSearchbar", WithArg("name", input)).
		Print()

	user := o.Script("getFindPaths", WithArg("user", input)).
		Print()

	var address string
	err := user.MarshalPointerAs("/address", &address)
	if err != nil {
		panic(err)
	}

	var paths []string
	err = user.MarshalPointerAs("/paths", &paths)
	if err != nil {
		panic(err)
	}

	// NFT IDs
	pathChunks := lo.Chunk(paths, 25)

	allReports := map[string][]uint64{}

	for _, c := range pathChunks {
		nfts := o.Script("getNFTIds", WithArg("address", address), WithArg("targetPaths", c)).Print()

		var report map[string]map[string]interface{}
		err := nfts.MarshalAs(&report)
		if err != nil {
			panic(err)
		}

		for _, m := range report {
			ids := m["ids"].([]interface{})
			arr := []uint64{}
			for _, i := range ids {
				arr = append(arr, uint64(i.(float64)))
			}
			key := m["key"].(string)
			allReports[key] = arr
		}

	}

	// NFT Items (MetadataViews)
	collection := "versusArtCollection"
	o.Script("getNFTItems", WithArg("user", address), WithArg("collectionIDs", map[string][]uint64{collection: allReports[collection]})).
		Print()

	// NFT Items (Alchemy)
	alCollection := "Moments"
	o.Script(fmt.Sprintf("%s%s", o.Network, "getAlchemy4Items"), WithArg("user", address), WithArg("collectionIDs", map[string][]uint64{alCollection: allReports[alCollection]})).
		Print()

	// NFT Details
	project := "FlovatarCollection"
	o.Script("getNFTDetails", WithArg("user", address), WithArg("project", project), WithArg("id", allReports[project][0]), WithArg("views", []string{})).
		Print()

	if true {
		return
	}

	// Find Market
	o.Script("getFindMarket", WithArg("user", address)).
		Print()

	// Find Lease Market
	o.Script("getFindLeaseMarket", WithArg("user", address)).
		Print()

}
