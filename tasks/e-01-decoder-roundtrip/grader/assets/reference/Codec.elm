module Codec exposing (decoder, encode)

{-| Reference solution — used only for grader self-tests. Never shown to agents.
-}

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Patient exposing (Contact, Patient, Phone)


decoder : Decoder Patient
decoder =
    Decode.map4 Patient
        (Decode.field "id" Decode.int)
        (Decode.field "name" Decode.string)
        (Decode.field "contact" contactDecoder)
        (Decode.field "tags" (Decode.list Decode.string))


contactDecoder : Decoder Contact
contactDecoder =
    Decode.map2 Contact
        (Decode.field "email" (Decode.nullable Decode.string))
        (Decode.field "phones" (Decode.list phoneDecoder))


phoneDecoder : Decoder Phone
phoneDecoder =
    Decode.map2 Phone
        (Decode.field "label" Decode.string)
        (Decode.field "number" Decode.string)


encode : Patient -> Encode.Value
encode patient =
    Encode.object
        [ ( "id", Encode.int patient.id )
        , ( "name", Encode.string patient.name )
        , ( "contact", encodeContact patient.contact )
        , ( "tags", Encode.list Encode.string patient.tags )
        ]


encodeContact : Contact -> Encode.Value
encodeContact contact =
    Encode.object
        [ ( "email"
          , case contact.email of
                Just email ->
                    Encode.string email

                Nothing ->
                    Encode.null
          )
        , ( "phones", Encode.list encodePhone contact.phones )
        ]


encodePhone : Phone -> Encode.Value
encodePhone phone =
    Encode.object
        [ ( "label", Encode.string phone.label )
        , ( "number", Encode.string phone.number )
        ]
