module TextStats exposing (characterCount)

{-| Text statistics helpers. -}


characterCount : String -> Int
characterCount text =
    text
        |> String.toList
        |> List.length
