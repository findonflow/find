package main

import (
	"encoding/json"
	"fmt"

	"github.com/bjartek/overflow"
)

func main() {
	g := overflow.NewOverflow().ExistingEmulator().Start()

	res, err := g.ParseAllWithConfig(true, []string{
		"^setup_*",
		"^mint*",
		"^admin*",
		"^dev*",
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
