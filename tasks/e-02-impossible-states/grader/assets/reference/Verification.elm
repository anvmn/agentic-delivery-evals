module Verification exposing (Verification, init, isVerified, markVerified, verificationInfo)

{-| Reference solution — used only for grader self-tests. Never shown to agents.
-}


type Verification
    = Unverified
    | Verified { at : Int, by : String }


init : Verification
init =
    Unverified


markVerified : Int -> String -> Verification -> Verification
markVerified at by _ =
    Verified { at = at, by = by }


isVerified : Verification -> Bool
isVerified verification =
    case verification of
        Verified _ ->
            True

        Unverified ->
            False


verificationInfo : Verification -> Maybe { at : Int, by : String }
verificationInfo verification =
    case verification of
        Verified info ->
            Just info

        Unverified ->
            Nothing
