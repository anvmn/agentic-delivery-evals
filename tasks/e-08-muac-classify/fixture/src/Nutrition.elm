module Nutrition exposing (Status(..), classifyMuac, summarize)

{-| Implement per task.md. Keep the type and exposing list as given.
-}


type Status
    = Normal
    | Moderate
    | Severe


classifyMuac : Float -> Status
classifyMuac muac =
    Debug.todo "implement classifyMuac"


summarize : List Float -> { normal : Int, moderate : Int, severe : Int, anySevere : Bool }
summarize measurements =
    Debug.todo "implement summarize"
