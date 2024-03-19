package main

import (
	"encoding/json"
	"fmt"

	"github.com/bjartek/overflow/v2"
)

func main() {
	g := overflow.Overflow(overflow.WithExistingEmulator())

	res, err := g.ParseAllWithConfig(true, []string{
		"^setup_*",
		"^mint*",
		"^admin*",
		"dev",
		"clock",
		"registerAdmin",
		"transferAllFusd",
		"fillUpTheChest",
		"setSellDandyForFlow.cdc",
	}, []string{})
	if err != nil {
		panic(err)
	}

	merged := res.MergeSpecAndCode()

	file, _ := json.MarshalIndent(merged, "", "   ")
	fmt.Println(string(file))

}
