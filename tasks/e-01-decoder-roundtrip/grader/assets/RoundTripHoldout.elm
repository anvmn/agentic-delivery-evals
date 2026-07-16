module RoundTripHoldout exposing (suite)

{-| Holdout assertions — this file never enters the agent workspace.
-}

import Codec
import Expect
import Fuzz exposing (Fuzzer)
import Json.Decode as Decode
import Patient exposing (Contact, Patient, Phone)
import Test exposing (Test, describe, fuzz, test)


phoneFuzzer : Fuzzer Phone
phoneFuzzer =
    Fuzz.map2 Phone Fuzz.string Fuzz.string


contactFuzzer : Fuzzer Contact
contactFuzzer =
    Fuzz.map2 Contact (Fuzz.maybe Fuzz.string) (Fuzz.list phoneFuzzer)


patientFuzzer : Fuzzer Patient
patientFuzzer =
    Fuzz.map4 Patient Fuzz.int Fuzz.string contactFuzzer (Fuzz.list Fuzz.string)


roundTrip : Patient -> Expect.Expectation
roundTrip p =
    Codec.encode p
        |> Decode.decodeValue Codec.decoder
        |> Expect.equal (Ok p)


suite : Test
suite =
    describe "Codec round-trip (holdout)"
        [ fuzz patientFuzzer "any patient survives encode |> decode" roundTrip
        , test "email Nothing, empty lists" <|
            \_ ->
                roundTrip
                    { id = 0
                    , name = ""
                    , contact = { email = Nothing, phones = [] }
                    , tags = []
                    }
        , test "unicode and negative id" <|
            \_ ->
                roundTrip
                    { id = -7
                    , name = "אנטולי 🌍 Ürümqi"
                    , contact =
                        { email = Just "א@example.org"
                        , phones = [ { label = "נייד", number = "+972-54-000" } ]
                        }
                    , tags = [ "עברית", "中文" ]
                    }
        ]
