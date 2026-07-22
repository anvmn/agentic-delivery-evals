module TextStats exposing (characterCount)

{-| Text statistics helpers.
-}


characterCount : String -> Int
characterCount text =
    String.length text
