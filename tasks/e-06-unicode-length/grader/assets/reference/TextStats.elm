module TextStats exposing (characterCount)

{-| Reference solution — grader self-tests only.
String.toList yields one Char per code point (surrogate pairs handled),
unlike String.length which counts UTF-16 units.
-}


characterCount : String -> Int
characterCount text =
    text
        |> String.toList
        |> List.length
