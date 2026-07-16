module InvalidUsage exposing (bad)

{-| The impossible-state probe. This file MUST FAIL to compile against a
correct solution. If it compiles, the model still admits invalid states.
-}

import Verification exposing (Verification)


bad : Verification
bad =
    { verified = True, verifiedAt = Nothing, verifier = Nothing }
