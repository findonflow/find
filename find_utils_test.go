package test_main

import (
	"fmt"
	"strings"
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/hexops/autogold"
	"github.com/onflow/cadence"
	"github.com/sanity-io/litter"
	"github.com/stretchr/testify/assert"
)

func TestFindUtils(t *testing.T) {
	otu := &OverflowTestUtils{T: t, O: ot.O}
	o := otu.O

	devCheckContainsChar := `import FindUtils from "../contracts/FindUtils.cdc"

	access(all) fun main(string: String, char:Character) : Bool {
		return FindUtils.containsChar(string, char: char)
	}`
	// containsChar
	ot.Run(t, "containsChar should return false if string does not contain", func(t *testing.T) {
		o.Script(devCheckContainsChar,
			WithArg("string", "bam.find"),
			WithArg("char", cadence.Character(",")),
		).
			AssertWant(t, autogold.Want("false", false))
	})

	ot.Run(t, "containsChar should return true if string contains", func(t *testing.T) {
		o.Script(devCheckContainsChar,
			WithArg("string", "bam.find"),
			WithArg("char", cadence.Character(".")),
		).
			AssertWant(t, autogold.Want("true", true))
	})

	devCheckContains := `import FindUtils from "../contracts/FindUtils.cdc"

	access(all) fun main(string: String, element:String) : Bool {
		return FindUtils.contains(string, element: element)
	}`

	// contains
	ot.Run(t, "contains should be able to check contains", func(t *testing.T) {
		o.Script(devCheckContains,
			WithArg("string", "string"),
			WithArg("element", "string"),
		).
			AssertWant(t, autogold.Want("true", true))
	})

	ot.Run(t, "contains should return false if string does not contain", func(t *testing.T) {
		o.Script(devCheckContains,
			WithArg("string", "string"),
			WithArg("element", "stt"),
		).
			AssertWant(t, autogold.Want("false", false))
	})

	ot.Run(t, "contains should return true if string partially contains", func(t *testing.T) {
		o.Script(devCheckContains,
			WithArg("string", "string"),
			WithArg("element", "ing"),
		).
			AssertWant(t, autogold.Want("true", true))
	})

	t.Run("contains should return false if element is longer than string", func(t *testing.T) {
		o.Script(devCheckContains,
			WithArg("string", "string"),
			WithArg("element", "substring"),
		).
			AssertWant(t, autogold.Want("false", false))
	})

	t.Run("contains should return true if element is empty string", func(t *testing.T) {
		o.Script(devCheckContains,
			WithArg("string", "string"),
			WithArg("element", `""`),
		).
			AssertWant(t, autogold.Want("true", true))
	})

	t.Run("contains should return false if string is empty string", func(t *testing.T) {
		o.Script(devCheckContains,
			WithArg("string", `""`),
			WithArg("element", "string"),
		).
			AssertWant(t, autogold.Want("false", false))
	})

	devCheckHasSuffix := `import FindUtils from "../contracts/FindUtils.cdc"

	access(all) fun main(string: String, suffix:String) : Bool {
		return FindUtils.hasSuffix(string, suffix: suffix)
	}`

	// hasSuffix
	t.Run("hasSuffix should return true if suffix is valid", func(t *testing.T) {
		o.Script(devCheckHasSuffix,
			WithArg("string", "bam.find"),
			WithArg("suffix", ".find"),
		).
			AssertWant(t, autogold.Want("true", true))
	})

	t.Run("hasSuffix should return false if suffix is not valid", func(t *testing.T) {
		o.Script(devCheckHasSuffix,
			WithArg("string", "bam.find"),
			WithArg("suffix", "..find"),
		).
			AssertWant(t, autogold.Want("false", false))
	})

	t.Run("hasSuffix should return true if entire string is passed in", func(t *testing.T) {
		o.Script(devCheckHasSuffix,
			WithArg("string", "bam.find"),
			WithArg("suffix", "bam.find"),
		).
			AssertWant(t, autogold.Want("true", true))
	})

	t.Run("hasSuffix should return true if empty string is passed in", func(t *testing.T) {
		o.Script(devCheckHasSuffix,
			WithArg("string", "bam.find"),
			WithArg("suffix", `""`),
		).
			AssertWant(t, autogold.Want("true", true))
	})

	t.Run("hasSuffix should return false if suffix is longer than string", func(t *testing.T) {
		o.Script(devCheckHasSuffix,
			WithArg("string", "bam.find"),
			WithArg("suffix", "bambambambambam"),
		).
			AssertWant(t, autogold.Want("false", false))
	})

	devCheckHasPrefix := `import FindUtils from "../contracts/FindUtils.cdc"

	access(all) fun main(string: String, prefix:String) : Bool {
		return FindUtils.hasPrefix(string, prefix: prefix)
	}`

	// hasPrefix
	t.Run("hasPrefix should return true if prefix is valid", func(t *testing.T) {
		o.Script(devCheckHasPrefix,
			WithArg("string", "bam.find"),
			WithArg("prefix", "bam."),
		).
			AssertWant(t, autogold.Want("true", true))
	})

	t.Run("hasPrefix should return false if prefix is not valid", func(t *testing.T) {
		o.Script(devCheckHasPrefix,
			WithArg("string", "bam.find"),
			WithArg("prefix", "bamm"),
		).
			AssertWant(t, autogold.Want("false", false))
	})

	t.Run("hasPrefix should return true if entire string is passed in", func(t *testing.T) {
		o.Script(devCheckHasPrefix,
			WithArg("string", "bam.find"),
			WithArg("prefix", "bam.find"),
		).
			AssertWant(t, autogold.Want("true", true))
	})

	t.Run("hasPrefix should return true if empty string is passed in", func(t *testing.T) {
		o.Script(devCheckHasPrefix,
			WithArg("string", "bam.find"),
			WithArg("prefix", `""`),
		).
			AssertWant(t, autogold.Want("true", true))
	})

	t.Run("hasPrefix should return false if prefix is longer than string", func(t *testing.T) {
		o.Script(devCheckHasPrefix,
			WithArg("string", "bam.find"),
			WithArg("prefix", "bambambambambam"),
		).
			AssertWant(t, autogold.Want("false", false))
	})

	t.Run("hasPrefix should return false if prefix is longer than string", func(t *testing.T) {
		o.Script(devCheckHasPrefix,
			WithArg("string", "bam.find"),
			WithArg("prefix", "bambambambambam"),
		).
			AssertWant(t, autogold.Want("false", false))
	})

	devCheckToUpper := `import FindUtils from "../contracts/FindUtils.cdc"

	access(all) fun main(string: String) : String {
		return FindUtils.toUpper(string)
	}
	`

	// toUpper
	t.Run("toUpper should return upper cases", func(t *testing.T) {
		s := "bam.find"
		o.Script(devCheckToUpper,
			WithArg("string", s),
		).
			AssertWant(t, autogold.Want("should return upper cases", strings.ToUpper(s)))
	})

	t.Run("toUpper should return upper cases if they are already upper cases", func(t *testing.T) {
		s := "bam.find"
		o.Script(devCheckToUpper,
			WithArg("string", strings.ToUpper(s)),
		).
			AssertWant(t, autogold.Want("if they are already upper cases", strings.ToUpper(s)))
	})

	devCheckFirstUpperLetter := `import FindUtils from "../contracts/FindUtils.cdc"

	access(all) fun main(string: String) : String {
		return FindUtils.firstUpperLetter(string)
	}
	`

	// first Upper Letter
	t.Run("firstUpperLetter should return upper case for first letter", func(t *testing.T) {
		s := "Bam.find"
		o.Script(devCheckFirstUpperLetter,
			WithArg("string", strings.ToLower(s)),
		).
			AssertWant(t, autogold.Want("should return upper case for first letter", s))
	})

	t.Run("firstUpperLetter should returns same if first letter is already upper case", func(t *testing.T) {
		s := "Bam.find"
		o.Script(devCheckFirstUpperLetter,
			WithArg("string", s),
		).
			AssertWant(t, autogold.Want("should returns same if first letter is already upper case", s))
	})

	t.Run("firstUpperLetter should returns same if first letter is not alphabet", func(t *testing.T) {
		s := ".Bam.find"
		o.Script(devCheckFirstUpperLetter,
			WithArg("string", s),
		).
			AssertWant(t, autogold.Want("should returns same if first letter is already upper case", s))
	})

	dev_check_to_snake_case := `import FindUtils from "../contracts/FindUtils.cdc"

access(all) fun main(string: String) : String {
	return FindUtils.to_snake_case(string)
}
`

	// to_snake_case
	t.Run("to_snake_case should returns snake case CamelCase", func(t *testing.T) {
		s := "CamelCase"
		o.Script(dev_check_to_snake_case,
			WithArg("string", s),
		).
			AssertWant(t, autogold.Want("CamelCase", "camel_case"))
	})

	t.Run("to_snake_case should returns snake case Camel Case", func(t *testing.T) {
		s := "Camel Case"
		o.Script(dev_check_to_snake_case,
			WithArg("string", s),
		).
			AssertWant(t, autogold.Want("Camel Case", "camel_case"))
	})

	t.Run("to_snake_case should returns snake case Camel case", func(t *testing.T) {
		s := "Camel case"
		o.Script(dev_check_to_snake_case,
			WithArg("string", s),
		).
			AssertWant(t, autogold.Want("Camel case", "camel_case"))
	})

	devCheckToCamelCase := `import FindUtils from "../contracts/FindUtils.cdc"

access(all) fun main(string: String) : String {
	return FindUtils.toCamelCase(string)
}
`

	// toCamelCase
	t.Run("toCamelCase should returns camel case Camel case", func(t *testing.T) {
		s := "Camel case"
		o.Script(devCheckToCamelCase,
			WithArg("string", s),
		).
			AssertWant(t, autogold.Want("CamelCase", "camelCase"))
	})

	t.Run("toCamelCase should returns camel case Camel Case", func(t *testing.T) {
		s := "Camel Case"
		o.Script(devCheckToCamelCase,
			WithArg("string", s),
		).
			AssertWant(t, autogold.Want("Camel Case", "camelCase"))
	})

	t.Run("toCamelCase should returns camel case Camel_case", func(t *testing.T) {
		s := "Camel_case"
		o.Script(devCheckToCamelCase,
			WithArg("string", s),
		).
			AssertWant(t, autogold.Want("Camel case", "camelCase"))
	})

	t.Run("toCamelCase should returns camel case Camel_Case", func(t *testing.T) {
		s := "Camel_Case"
		o.Script(devCheckToCamelCase,
			WithArg("string", s),
		).
			AssertWant(t, autogold.Want("Camel case", "camelCase"))
	})

	devTrimSuffix := `import FindUtils from "../contracts/FindUtils.cdc"

access(all) fun main(string: String, suffix:String) : String {
	return FindUtils.trimSuffix(string, suffix:suffix)
}
`

	t.Run("trimSuffix should trim bam.find", func(t *testing.T) {
		o.Script(devTrimSuffix,
			WithArg("string", "bam.find"),
			WithArg("suffix", ".find"),
		).
			AssertWant(t, autogold.Want("trimSuffix : bam.find", "bam"))
	})

	t.Run("trimSuffix should not trim christian.fine", func(t *testing.T) {
		o.Script(devTrimSuffix,
			WithArg("string", "christian.fine"),
			WithArg("suffix", ".find"),
		).
			AssertWant(t, autogold.Want("trimSuffix : christian.fine", "christian.fine"))
	})

	t.Run("trimSuffix should not trim bam", func(t *testing.T) {
		o.Script(devTrimSuffix,
			WithArg("string", "bam"),
			WithArg("suffix", ".find"),
		).
			AssertWant(t, autogold.Want("trimSuffix : bam", "bam"))
	})

	// Extra tests on trimFindSuffix on FIND

	devTrimFindSuffix := `import FIND from "../contracts/FIND.cdc"

access(all) fun main(name: String) : String {
	return FIND.trimFindSuffix(name)
}
`
	t.Run("trimFindSuffix should trim bam.find", func(t *testing.T) {
		o.Script(devTrimFindSuffix,
			WithArg("name", "bam.find"),
		).
			AssertWant(t, autogold.Want("trimFindSuffix : bam.find", "bam"))
	})

	t.Run("trimFindSuffix should return bam", func(t *testing.T) {
		o.Script(devTrimFindSuffix,
			WithArg("name", "bam"),
		).
			AssertWant(t, autogold.Want("trimFindSuffix : bam", "bam"))
	})

	// splitString
	devSplitString := `import FindUtils from "../contracts/FindUtils.cdc"

	access(all) fun main(string: String, sep: Character) : [String] {
		return FindUtils.splitString(string, sep:sep)
	}
	`
	t.Run("splitString should split Hello_World_And_All", func(t *testing.T) {
		o.Script(devSplitString,
			WithArg("string", "Hello_World_And_All"),
			WithArg("sep", cadence.Character("_")),
		).
			AssertWant(t, autogold.Want("splitString : Hello_World_And_All", litter.Sdump([]interface{}{"Hello", "World", "And", "All"})))
	})

	t.Run("splitString should split Hello_World.And_All", func(t *testing.T) {
		o.Script(devSplitString,
			WithArg("string", "Hello_World.And_All"),
			WithArg("sep", cadence.Character("_")),
		).
			AssertWant(t, autogold.Want("splitString : Hello_World.And_All", litter.Sdump([]interface{}{"Hello", "World.And", "All"})))
	})

	t.Run("splitString should not split Hello.World.And.All", func(t *testing.T) {
		o.Script(devSplitString,
			WithArg("string", "Hello.World.And.All"),
			WithArg("sep", cadence.Character("_")),
		).
			AssertWant(t, autogold.Want("splitString : Hello.World.And.All", litter.Sdump([]interface{}{"Hello.World.And.All"})))
	})

	t.Run("splitString should not split HelloWorldAndAll", func(t *testing.T) {
		o.Script(devSplitString,
			WithArg("string", "HelloWorldAndAll"),
			WithArg("sep", cadence.Character("_")),
		).
			AssertWant(t, autogold.Want("splitString : HelloWorldAndAll", litter.Sdump([]interface{}{"HelloWorldAndAll"})))
	})

	// joinMapToString
	devJoinMapToString := `import FindUtils from "../contracts/FindUtils.cdc"

access(all) fun main(map: {String : String}) : String {
	return FindUtils.joinMapToString(map)
}
`
	t.Run("joinMapToString should join the map and return as expected", func(t *testing.T) {
		o.Script(devJoinMapToString,
			WithArg("map", map[string]string{
				"1+1": "2",
				"2+2": "4",
				"3*3": "9",
			}),
		).
			AssertWant(t, autogold.Want("joinMapToString : 1+1=2 2+2=4 3*3=9", "2+2=4 3*3=9 1+1=2"))
	})

	// joinString
	devJoinString := `import FindUtils from "../contracts/FindUtils.cdc"

access(all) fun main(s: [String], sep: String) : String {
	return FindUtils.joinString(s, sep:sep)
}
`
	t.Run("devJoinString should join the string with sep and return as expected", func(t *testing.T) {
		o.Script(devJoinString,
			WithArg("s", []string{
				"1+1=2",
				"2+2=4",
				"3*3=9",
			}),
			WithArg("sep", " "),
		).
			AssertWant(t, autogold.Want("devJoinString : 1+1=2 2+2=4 3*3=9", "1+1=2 2+2=4 3*3=9"))
	})

	// deDupTypeArray
	devDeDupTypeArray := `import FindUtils from "../contracts/FindUtils.cdc"

access(all) fun main(s: [String]) : [Type] {
	var typ : [Type] = []
	for t in s {
		typ.append(CompositeType(t) ?? panic("value ".concat(t).concat(" is not a composite type")))
	}
	return FindUtils.deDupTypeArray(typ)
}
`
	t.Run("deDupTypeArray should dedup duplicated as expected", func(t *testing.T) {
		flow, err := o.QualifiedIdentifier("FlowToken", "Vault")
		assert.NoError(t, err)
		ft, err := o.QualifiedIdentifier("FUSD", "Vault")
		assert.NoError(t, err)
		nft, err := o.QualifiedIdentifier("ExampleNFT", "NFT")
		assert.NoError(t, err)
		collection, err := o.QualifiedIdentifier("Dandy", "Collection")
		assert.NoError(t, err)
		o.Script(devDeDupTypeArray,
			WithArg("s", []string{
				flow,
				ft,
				nft,
				nft,
				collection,
				flow,
				flow,
				flow,
				ft,
				ft,
				ft,
				nft,
				nft,
			}),
		).
			AssertWant(t, autogold.Want("deDupTypeArray : flow, ft, nft, collection", fmt.Sprintf(`[]interface {}{
  "%s",
  "%s",
  "%s",
  "%s",
}`, flow, ft, nft, collection)))
	})
}
