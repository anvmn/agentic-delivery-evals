module Nutrition exposing (Status(..), classifyMuac, summarize)

{-| FLAWED self-test variant: <= at the cutoffs. Misclassifies exactly 115.0
(Severe, should be Moderate) and 125.0 (Moderate, should be Normal).
-}


type Status
    = Normal
    | Moderate
    | Severe


classifyMuac : Float -> Status
classifyMuac muac =
    if muac <= 115 then
        Severe

    else if muac <= 125 then
        Moderate

    else
        Normal


summarize : List Float -> { normal : Int, moderate : Int, severe : Int, anySevere : Bool }
summarize measurements =
    let
        step muac acc =
            case classifyMuac muac of
                Normal ->
                    { acc | normal = acc.normal + 1 }

                Moderate ->
                    { acc | moderate = acc.moderate + 1 }

                Severe ->
                    { acc | severe = acc.severe + 1, anySevere = True }
    in
    List.foldl step { normal = 0, moderate = 0, severe = 0, anySevere = False } measurements
