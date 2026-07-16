module HoldoutTest exposing (suite)

{-| Behavioral holdout for the required API — never enters the agent workspace.
-}

import Expect
import Test exposing (Test, describe, test)
import Verification


suite : Test
suite =
    describe "Verification API behavior (holdout)"
        [ test "init is not verified" <|
            \_ -> Verification.isVerified Verification.init |> Expect.equal False
        , test "init has no verification info" <|
            \_ -> Verification.verificationInfo Verification.init |> Expect.equal Nothing
        , test "markVerified sets verified with exact info" <|
            \_ ->
                let
                    v =
                        Verification.markVerified 1721000000 "Nurse Chana" Verification.init
                in
                ( Verification.isVerified v, Verification.verificationInfo v )
                    |> Expect.equal ( True, Just { at = 1721000000, by = "Nurse Chana" } )
        ]
