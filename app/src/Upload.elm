-- Copy pasted from https://github.com/elm/file/blob/master/examples/SelectFilesWithProgress.elm


module Upload exposing (Model(..), Msg(..), filesDecoder, init, main, subscriptions, update, view)

import Base64
import Browser
import Element
import Element.Background as Background
import Element.Border as Border
import File exposing (File)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as D



-- MAIN


main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type Model
    = Waiting String
    | Uploading Float
    | Done
    | Fail


init : () -> ( Model, Cmd Msg )
init _ =
    ( Waiting ""
    , Cmd.none
    )



-- UPDATE


type Msg
    = GotFiles (List File)
    | GotProgress Http.Progress
    | Uploaded (Result Http.Error ())
    | NewPasswd String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotFiles files ->
            case model of
                Waiting password ->
                    ( Uploading 0
                    , Http.request
                        { method = "POST"
                        , url = "/upload/"
                        , headers = [ authHeader password ]
                        , body = Http.multipartBody (List.map (Http.filePart "video") files)
                        , expect = Http.expectWhatever Uploaded
                        , timeout = Nothing
                        , tracker = Just "upload"
                        }
                    )

                _ ->
                    ( Waiting "", Cmd.none )

        GotProgress progress ->
            case progress of
                Http.Sending p ->
                    ( Uploading (Http.fractionSent p), Cmd.none )

                Http.Receiving _ ->
                    ( model, Cmd.none )

        Uploaded result ->
            case result of
                Ok _ ->
                    ( Done, Cmd.none )

                Err _ ->
                    ( Fail, Cmd.none )

        NewPasswd passwd ->
            ( Waiting passwd, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Http.track "upload" GotProgress



-- VIEW


view : Model -> Html Msg
view model =
    Element.layout
        [ Background.image "/static/dark-blue.jpg" ]
        (uploadBox model)


uploadBox : Model -> Element.Element Msg
uploadBox model =
    Element.column
        [ Element.centerX
        , Element.centerY
        , Element.padding 30
        , Background.color (Element.rgba255 200 200 200 0.6)
        , Border.rounded 5
        ]
        [ Element.text "Speak friend, and upload!"
        , Element.html (innerView model)
        ]


innerView : Model -> Html Msg
innerView model =
    case model of
        Waiting text ->
            div []
                [ Html.input
                    [ type_ "text"
                    , Html.Events.onInput NewPasswd
                    ]
                    []
                , Html.input
                    [ type_ "file"
                    , multiple True
                    , on "change" (D.map GotFiles filesDecoder)
                    ]
                    []
                ]

        Uploading fraction ->
            h1 [] [ text (String.fromInt (round (100 * fraction)) ++ "%") ]

        Done ->
            h1 [] [ text "DONE" ]

        Fail ->
            h1 [] [ text "FAIL" ]


filesDecoder : D.Decoder (List File)
filesDecoder =
    D.at [ "target", "files" ] (D.list File.decoder)



-- Http


authHeader : String -> Http.Header
authHeader password =
    Http.header "Authorization" <| "Basic " ++ Base64.encode ("anyone:" ++ password)
