module Codec exposing (decoder, encode)

{-| Implement both functions. See task.md for the JSON shape.
-}

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Patient exposing (Patient)


decoder : Decoder Patient
decoder =
    Debug.todo "implement Codec.decoder"


encode : Patient -> Encode.Value
encode patient =
    Debug.todo "implement Codec.encode"
