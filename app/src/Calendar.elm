module Calendar exposing (..)

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


type alias Greeting =
    { day : Int, video : String }


type alias Content =
    { greetings : List Greeting }


init : () -> ( Model, Cmd Msg )
init _ =
    ( Loading
    , getGreetings
    )



-- UPDATE


type Msg
    = GotGreetings (Result Http.Error (List Greeting))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotGreetings result ->
            case result of
                Ok greetings ->
                    ( HasContent { greetings = greetings }, Cmd.none )

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
        List.map greetingBox
            content.greetings


greetingBox : Greeting -> Element.Element Msg
greetingBox greeting =
    Element.html <|
        Html.video [ HtmlAttrs.controls True, HtmlAttrs.height 300, HtmlAttrs.width 600 ]
            [ Html.source [ HtmlAttrs.src <| videoUrl greeting.video ] []
            , Html.text "No comprendo senior"
            ]


videoUrl : String -> String
videoUrl name =
    "/video/" ++ name



-- Http


getGreetings : Cmd Msg
getGreetings =
    Http.get { url = "/calendar_info/", expect = Http.expectJson GotGreetings greetingsDecoder }



-- Json


greetingsDecoder : Decode.Decoder (List Greeting)
greetingsDecoder =
    Decode.list greetingDecoder


greetingDecoder : Decode.Decoder Greeting
greetingDecoder =
    Decode.map2 Greeting
        (Decode.field "day" Decode.int)
        (Decode.field "video" Decode.string)
