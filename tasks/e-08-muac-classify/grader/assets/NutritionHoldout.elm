module NutritionHoldout exposing (suite)

{-| Holdout — never enters the agent workspace. Hammers the exact cutoffs,
where <= vs < errors live.
-}

import Expect
import Nutrition exposing (Status(..))
import Test exposing (Test, describe, test)


classifies : Float -> Status -> Test
classifies muac expected =
    test ("classify " ++ String.fromFloat muac) <|
        \_ -> Nutrition.classifyMuac muac |> Expect.equal expected


suite : Test
suite =
    describe "Nutrition (holdout)"
        [ describe "classifyMuac boundaries"
            [ classifies 114.9 Severe
            , classifies 115.0 Moderate
            , classifies 115.1 Moderate
            , classifies 124.9 Moderate
            , classifies 125.0 Normal
            , classifies 125.1 Normal
            , classifies 0 Severe
            , classifies 200 Normal
            ]
        , test "summarize mixed" <|
            \_ ->
                -- 100,110 severe · 115,120 moderate · 125,130 normal
                Nutrition.summarize [ 100, 115, 120, 125, 130, 110 ]
                    |> Expect.equal { normal = 2, moderate = 2, severe = 2, anySevere = True }
        , test "summarize empty" <|
            \_ ->
                Nutrition.summarize []
                    |> Expect.equal { normal = 0, moderate = 0, severe = 0, anySevere = False }
        , test "summarize no severe" <|
            \_ ->
                Nutrition.summarize [ 125, 130, 115 ]
                    |> Expect.equal { normal = 2, moderate = 1, severe = 0, anySevere = False }
        ]
