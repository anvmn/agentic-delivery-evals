module TextStatsTest exposing (suite)

import Expect
import Test exposing (Test, describe, test)
import TextStats exposing (characterCount)


suite : Test
suite =
    describe "characterCount"
        [ test "plain ASCII" <|
            \_ -> Expect.equal (characterCount "hello") 5
        , test "Hebrew (BMP)" <|
            \_ -> Expect.equal (characterCount "שלום") 4
        , test "emoji, astral plane" <|
            \_ -> Expect.equal (characterCount "👍") 1
        , test "flag, two regional indicators" <|
            \_ -> Expect.equal (characterCount "🇮🇱") 2
        ]
