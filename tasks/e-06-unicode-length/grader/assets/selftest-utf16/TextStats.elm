module TextStats exposing (characterCount)

{-| FLAWED self-test variant: the popular wrong answer. -}


characterCount : String -> Int
characterCount text =
    String.length text
