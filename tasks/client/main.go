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
		"clock",
		"registerAdmin",
		"adminSendFlow",
		"transferAllFusd",
		"fillUpTheChest",
		"setSellDandyForFlow.cdc",
		"test*",
	}, []string{})
	if err != nil {
		panic(err)
	}

	merged := res.MergeSpecAndCode()

	file, _ := json.MarshalIndent(merged, "", "   ")
	fmt.Println(string(file))

}
