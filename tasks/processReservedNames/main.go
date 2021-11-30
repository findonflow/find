package main

import (
	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	"github.com/davecgh/go-spew/spew"
)

func main() {

	adminName := "find"
	g := gwtf.NewGoWithTheFlowEmulator()

	result := g.ScriptFromFile("reserveStatus").AccountArgument(adminName).RunReturnsInterface()
	spew.Dump(result)
	// run script to fetch all names with direct offers

}
