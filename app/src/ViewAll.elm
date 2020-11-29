module ViewAll exposing (..)

import Browser
import Element
import Html
import Html.Attributes as HtmlAttrs
import Http
import Json.Decode as Decode



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
    = Loading
    | HasContent Content
    | Error Reason


type alias Reason =
    String


type alias Content =
    { videos : List String }


init : () -> ( Model, Cmd Msg )
init _ =
    ( Loading
    , getVideos
    )



-- UPDATE


type Msg
    = GotVideoNames (Result Http.Error (List String))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotVideoNames result ->
            case result of
                Ok video_names ->
                    ( HasContent { videos = video_names }, Cmd.none )

                _ ->
                    ( Error "I misunderstood something", Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html.Html Msg
view model =
    Element.layout []
        (case model of
            HasContent content ->
                displayContent content

            Error reason ->
                Element.text reason

            Loading ->
                Element.text "Loading..."
        )


displayContent : Content -> Element.Element Msg
displayContent content =
    Element.wrappedRow [] <|
        List.map videoBox
            content.videos


videoBox : String -> Element.Element Msg
videoBox name =
    Element.html <|
        Html.video [ HtmlAttrs.controls True, HtmlAttrs.height 300, HtmlAttrs.width 600]
            [ Html.source [ HtmlAttrs.src <| videoUrl name ] []
            , Html.text "No comprendo senior"
            ]


videoUrl : String -> String
videoUrl name =
    "/video/" ++ name



-- Http


getVideos : Cmd Msg
getVideos =
    Http.get { url = "/videos/", expect = Http.expectJson GotVideoNames videoDecoder }



-- Json


videoDecoder : Decode.Decoder (List String)
videoDecoder =
    Decode.field "videos" <| Decode.list Decode.string
