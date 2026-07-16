module Patient exposing (Contact, Patient, Phone)

{-| Domain types for the codec task. Do not modify this file.
-}


type alias Patient =
    { id : Int
    , name : String
    , contact : Contact
    , tags : List String
    }


type alias Contact =
    { email : Maybe String
    , phones : List Phone
    }


type alias Phone =
    { label : String
    , number : String
    }
