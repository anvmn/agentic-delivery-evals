module Events exposing (Event(..), decoder)

{-| Reference solution — grader self-tests only.
Dispatch on "type" via andThen, so a malformed known variant fails AS that
variant instead of falling through (the oneOf trap).
-}

import Json.Decode as Decode exposing (Decoder)


type Event
    = Visit Int
    | Note String
    | Measurement Float


eventDecoder : Decoder Event
eventDecoder =
    Decode.field "type" Decode.string
        |> Decode.andThen
            (\tag ->
                case tag of
                    "visit" ->
                        Decode.map Visit (Decode.field "clinic" Decode.int)

                    "note" ->
                        Decode.map Note (Decode.field "text" Decode.string)

                    "measurement" ->
                        Decode.map Measurement (Decode.field "value" Decode.float)

                    other ->
                        Decode.fail ("unknown event type: " ++ other)
            )


decoder : Decoder (List Event)
decoder =
    Decode.list eventDecoder
