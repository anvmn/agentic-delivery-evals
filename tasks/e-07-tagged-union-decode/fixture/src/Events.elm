module Events exposing (Event(..), decoder)

{-| Implement `decoder` per task.md. Keep the type and exposing list as given.
-}

import Json.Decode as Decode exposing (Decoder)


type Event
    = Visit Int
    | Note String
    | Measurement Float


decoder : Decoder (List Event)
decoder =
    Debug.todo "implement Events.decoder"
