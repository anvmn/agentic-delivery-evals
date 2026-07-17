module UnicodeHoldout exposing (suite)

{-| Holdout assertions — never enters the agent workspace.
The popular wrong answer (String.length, UTF-16 units) fails every
non-BMP case below.
-}

import Expect
import Test exposing (Test, describe, test)
import TextStats


cases : List ( String, String, Int )
cases =
    [ ( "ascii", "abc", 3 )
    , ( "empty", "", 0 )
    , ( "hebrew", "שלום", 4 )
    , ( "hebrew with niqqud", "בְּ", 3 )
    , ( "thumbs up (astral)", "👍", 1 )
    , ( "flag = two regional indicators", "🇮🇱", 2 )
    , ( "zwj family", "👩\u{200D}👩\u{200D}👧", 5 )
    , ( "mixed", "a👍ב", 3 )
    , ( "two astral", "👍👍", 2 )
    , ( "combining acute", "e\u{0301}", 2 )
    ]


suite : Test
suite =
    describe "characterCount counts code points (holdout)"
        (cases
            |> List.map
                (\( name, input, expected ) ->
                    test name <|
                        \_ -> TextStats.characterCount input |> Expect.equal expected
                )
        )
