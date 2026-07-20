module TextStatsTest exposing (suite)

import Expect
import Test exposing (Test, describe, test)
import TextStats exposing (characterCount)


suite : Test
suite =
    describe "characterCount"
        [ test "counts plain ASCII characters" <|
            \_ -> Expect.equal (characterCount "hello") 5
        , test "empty string has length zero" <|
            \_ -> Expect.equal (characterCount "") 0
        , test "counts a phrase with spaces" <|
            \_ -> Expect.equal (characterCount "a b c") 5
        ]
