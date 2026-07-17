module Events exposing (Event(..), decoder)

{-| FLAWED self-test variant: the oneOf trap. A malformed visit that carries
a text field silently decodes as a Note — the holdout's "gotcha" case.
-}

import Json.Decode as Decode exposing (Decoder)


type Event
    = Visit Int
    | Note String
    | Measurement Float


decoder : Decoder (List Event)
decoder =
    Decode.list
        (Decode.oneOf
            [ Decode.map Visit (Decode.field "clinic" Decode.int)
            , Decode.map Note (Decode.field "text" Decode.string)
            , Decode.map Measurement (Decode.field "value" Decode.float)
            ]
        )
