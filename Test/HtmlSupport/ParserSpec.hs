{-|
Module: Test.HtmlSupport.QQSpec
Copyright: (c) digitally induced GmbH, 2020
-}
module Test.HtmlSupport.ParserSpec where

import Test.Hspec
import IHP.Prelude
import IHP.HtmlSupport.Parser
import qualified Text.Megaparsec as Megaparsec
import qualified Text.Megaparsec.Error as Megaparsec

tests = do
    let position = Megaparsec.SourcePos "" (Megaparsec.mkPos 0) (Megaparsec.mkPos 0)
    describe "HSX Parser" do
        it "should fail on invalid html tags" do
            let errorText = "1:15:\n  |\n1 | <my-invalid-el>\n  |               ^\nInvalid tag name: my-invalid-el\n"
            let (Left error) = parseHsx position "<my-invalid-el>"
            (Megaparsec.errorBundlePretty error) `shouldBe` errorText

        it "should fail on invalid attribute names" do
            let errorText = "1:23:\n  |\n1 | <div invalid-attribute=\"test\">\n  |                       ^\nInvalid attribute name: invalid-attribute\n"
            let (Left error) = parseHsx position "<div invalid-attribute=\"test\">"
            (Megaparsec.errorBundlePretty error) `shouldBe` errorText

        it "should fail on unmatched tags" do
            let errorText = "1:7:\n  |\n1 | <div></span>\n  |       ^\nunexpected '/'\nexpecting \"</div>\" or identifier\n"
            let (Left error) = parseHsx position "<div></span>"
            (Megaparsec.errorBundlePretty error) `shouldBe` errorText