port module Main exposing (main)

import Browser
import Html exposing (Html, button, div, input, li, option, select, span, text, ul)
import Html.Attributes exposing (id, placeholder, value)
import Html.Events exposing (onClick, onInput)
import Json.Decode as Decode
import Json.Encode as Encode


port saveVisits : Encode.Value -> Cmd msg


type alias Visit =
    { patient : String
    , kind : String
    }


type alias Model =
    { patient : String
    , kind : String
    , visits : List Visit
    }


main : Program Decode.Value Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }


visitDecoder : Decode.Decoder Visit
visitDecoder =
    Decode.map2 Visit
        (Decode.field "patient" Decode.string)
        (Decode.field "kind" Decode.string)


encodeVisit : Visit -> Encode.Value
encodeVisit visit =
    Encode.object
        [ ( "patient", Encode.string visit.patient )
        , ( "kind", Encode.string visit.kind )
        ]


init : Decode.Value -> ( Model, Cmd Msg )
init flags =
    ( { patient = ""
      , kind = "checkup"
      , visits =
            flags
                |> Decode.decodeValue (Decode.list visitDecoder)
                |> Result.withDefault []
      }
    , Cmd.none
    )


type Msg
    = SetPatient String
    | SetKind String
    | AddVisit


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AddVisit ->
            if String.isEmpty (String.trim model.patient) then
                ( model, Cmd.none )

            else
                let
                    visits =
                        model.visits ++ [ { patient = model.patient, kind = model.kind } ]
                in
                ( { model | visits = visits, patient = "" }
                , saveVisits (Encode.list encodeVisit visits)
                )

        SetKind kind ->
            ( { model | kind = kind }, Cmd.none )

        SetPatient patient ->
            ( { model | patient = patient }, Cmd.none )


view : Model -> Html Msg
view model =
    div []
        [ input [ id "patient-name", placeholder "Patient name", value model.patient, onInput SetPatient ] []
        , select [ id "visit-type", onInput SetKind ]
            [ option [ value "checkup" ] [ text "checkup" ]
            , option [ value "vaccination" ] [ text "vaccination" ]
            , option [ value "followup" ] [ text "followup" ]
            ]
        , button [ id "add-visit", onClick AddVisit ] [ text "Add visit" ]
        , span [ id "visit-count" ] [ text (String.fromInt (List.length model.visits)) ]
        , ul [ id "visit-list" ]
            (List.map
                (\v ->
                    li [ Html.Attributes.class "visit-item" ]
                        [ text (v.patient ++ " — " ++ v.kind) ]
                )
                model.visits
            )
        ]
