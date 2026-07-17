module EventsHoldout exposing (suite)

{-| Holdout — never enters the agent workspace. The `oneOf` trap fails the
"gotcha" case: a malformed visit carrying a text field must not become a Note.
-}

import Events exposing (Event(..))
import Expect
import Json.Decode as Decode
import Test exposing (Test, describe, test)


ok : String -> String -> List Event -> Test
ok label json expected =
    test label <|
        \_ ->
            Decode.decodeString Events.decoder json
                |> Expect.equal (Ok expected)


errCase : String -> String -> Test
errCase label json =
    test label <|
        \_ ->
            case Decode.decodeString Events.decoder json of
                Ok _ ->
                    Expect.fail "expected Err, got Ok (silent mis-decode?)"

                Err _ ->
                    Expect.pass


suite : Test
suite =
    describe "Events.decoder (holdout)"
        [ ok "visit" """[{"type":"visit","clinic":7}]""" [ Visit 7 ]
        , ok "note" """[{"type":"note","text":"hi"}]""" [ Note "hi" ]
        , ok "measurement" """[{"type":"measurement","value":12.5}]""" [ Measurement 12.5 ]
        , ok "mixed order"
            """[{"type":"note","text":"a"},{"type":"visit","clinic":3}]"""
            [ Note "a", Visit 3 ]
        , ok "empty" "[]" []
        , errCase "malformed visit (missing clinic)" """[{"type":"visit"}]"""
        , errCase "unknown type" """[{"type":"xray","n":1}]"""
        , errCase "the gotcha: bad visit with a text field must NOT become a Note"
            """[{"type":"visit","clinic":"NaN","text":"gotcha"}]"""
        , errCase "measurement with non-number value" """[{"type":"measurement","value":"x"}]"""
        ]
