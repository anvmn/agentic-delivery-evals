module Verification exposing (Verification, init, isVerified, markVerified, verificationInfo)

{-| The current, flawed model. Remodel per task.md.
-}


type alias Verification =
    { verified : Bool
    , verifiedAt : Maybe Int
    , verifier : Maybe String
    }


init : Verification
init =
    { verified = False, verifiedAt = Nothing, verifier = Nothing }


markVerified : Int -> String -> Verification -> Verification
markVerified at by _ =
    { verified = True, verifiedAt = Just at, verifier = Just by }


isVerified : Verification -> Bool
isVerified v =
    v.verified


verificationInfo : Verification -> Maybe { at : Int, by : String }
verificationInfo v =
    case ( v.verifiedAt, v.verifier ) of
        ( Just at, Just by ) ->
            Just { at = at, by = by }

        _ ->
            Nothing
