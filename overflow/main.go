package main

import (
	"encoding/json"
	"fmt"

	"github.com/bjartek/overflow/overflow"
)

func main() {
	g := overflow.NewOverflow().ExistingEmulator().Start()

	res, err := g.ParseAllWithConfig(true, []string{
		"^setup_*",
		"^mint*",
		"clock",
		"registerAdmin",
	}, []string{})
	if err != nil {
		panic(err)
	}

	file, _ := json.MarshalIndent(res, "", "   ")
	fmt.Println(string(file))

}
