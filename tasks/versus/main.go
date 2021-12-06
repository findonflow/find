package main

import (
	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {

	g := gwtf.NewGoWithTheFlowDevNet()

	g.ScriptFromFile("versus-list").RawAccountArgument("0xdc5b887c1bfb1b10").Run()

}
