package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/hexops/autogold"
	"github.com/onflow/cadence"
)

func TestFindUtils(t *testing.T) {

	otu := NewOverflowTest(t)
	o := otu.O

	// containsChar
	t.Run("containsChar should return false if string does not contain", func(t *testing.T) {
		o.Script("testCheckContainsChar",
			WithArg("string", "bam.find"),
			WithArg("char", cadence.Character(",")),
		).
			AssertWant(t, autogold.Want("false", false))
	})

	t.Run("containsChar should return true if string contains", func(t *testing.T) {
		o.Script("testCheckContainsChar",
			WithArg("string", "bam.find"),
			WithArg("char", cadence.Character(".")),
		).
			AssertWant(t, autogold.Want("true", true))
	})

	// contains
	t.Run("contains should be able to check contains", func(t *testing.T) {
		o.Script("testCheckContains",
			WithArg("string", "string"),
			WithArg("element", "string"),
		).
			AssertWant(t, autogold.Want("true", true))
	})

	t.Run("contains should return false if string does not contain", func(t *testing.T) {
		o.Script("testCheckContains",
			WithArg("string", "string"),
			WithArg("element", "stt"),
		).
			AssertWant(t, autogold.Want("false", false))
	})

	t.Run("contains should return true if string partially contains", func(t *testing.T) {
		o.Script("testCheckContains",
			WithArg("string", "string"),
			WithArg("element", "ing"),
		).
			AssertWant(t, autogold.Want("true", true))
	})

	t.Run("contains should return false if element is longer than string", func(t *testing.T) {
		o.Script("testCheckContains",
			WithArg("string", "string"),
			WithArg("element", "substring"),
		).
			AssertWant(t, autogold.Want("false", false))
	})

	t.Run("contains should return true if element is empty string", func(t *testing.T) {
		o.Script("testCheckContains",
			WithArg("string", "string"),
			WithArg("element", `""`),
		).
			AssertWant(t, autogold.Want("true", true))
	})

	t.Run("contains should return false if string is empty string", func(t *testing.T) {
		o.Script("testCheckContains",
			WithArg("string", `""`),
			WithArg("element", "string"),
		).
			AssertWant(t, autogold.Want("false", false))
	})

	// hasSuffix
	t.Run("hasSuffix should return true if suffix is valid", func(t *testing.T) {
		o.Script("testCheckHasSuffix",
			WithArg("string", "bam.find"),
			WithArg("suffix", ".find"),
		).
			AssertWant(t, autogold.Want("true", true))
	})

	t.Run("hasSuffix should return false if suffix is not valid", func(t *testing.T) {
		o.Script("testCheckHasSuffix",
			WithArg("string", "bam.find"),
			WithArg("suffix", "..find"),
		).
			AssertWant(t, autogold.Want("false", false))
	})

	t.Run("hasSuffix should return true if entire string is passed in", func(t *testing.T) {
		o.Script("testCheckHasSuffix",
			WithArg("string", "bam.find"),
			WithArg("suffix", "bam.find"),
		).
			AssertWant(t, autogold.Want("true", true))
	})

	t.Run("hasSuffix should return true if empty string is passed in", func(t *testing.T) {
		o.Script("testCheckHasSuffix",
			WithArg("string", "bam.find"),
			WithArg("suffix", `""`),
		).
			AssertWant(t, autogold.Want("true", true))
	})

	t.Run("hasSuffix should return false if suffix is longer than string", func(t *testing.T) {
		o.Script("testCheckHasSuffix",
			WithArg("string", "bam.find"),
			WithArg("suffix", "bambambambambam"),
		).
			AssertWant(t, autogold.Want("false", false))
	})

	// hasPrefix
	t.Run("hasPrefix should return true if prefix is valid", func(t *testing.T) {
		o.Script("testCheckHasPrefix",
			WithArg("string", "bam.find"),
			WithArg("prefix", "bam."),
		).
			AssertWant(t, autogold.Want("true", true))
	})

	t.Run("hasPrefix should return false if prefix is not valid", func(t *testing.T) {
		o.Script("testCheckHasPrefix",
			WithArg("string", "bam.find"),
			WithArg("prefix", "bamm"),
		).
			AssertWant(t, autogold.Want("false", false))
	})

	t.Run("hasPrefix should return true if entire string is passed in", func(t *testing.T) {
		o.Script("testCheckHasPrefix",
			WithArg("string", "bam.find"),
			WithArg("prefix", "bam.find"),
		).
			AssertWant(t, autogold.Want("true", true))
	})

	t.Run("hasPrefix should return true if empty string is passed in", func(t *testing.T) {
		o.Script("testCheckHasPrefix",
			WithArg("string", "bam.find"),
			WithArg("prefix", `""`),
		).
			AssertWant(t, autogold.Want("true", true))
	})

	t.Run("hasPrefix should return false if prefix is longer than string", func(t *testing.T) {
		o.Script("testCheckHasPrefix",
			WithArg("string", "bam.find"),
			WithArg("prefix", "bambambambambam"),
		).
			AssertWant(t, autogold.Want("false", false))
	})

}
