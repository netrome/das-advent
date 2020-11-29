module Calendar exposing (..)

import Browser
import Element
import Element.Background as Background
import Element.Events as Events
import Element.Font as Font
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
    { day : Int, video : String, flipped : Bool }


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
    | Flipped Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotGreetings result ->
            case result of
                Ok greetings ->
                    ( HasContent { greetings = greetings }, Cmd.none )

                _ ->
                    ( Error "I misunderstood something", Cmd.none )

        Flipped day ->
            ( tryFlip model day, Cmd.none )


tryFlip : Model -> Int -> Model
tryFlip model day =
    case model of
        HasContent content ->
            flip content day

        _ ->
            Error "This is impossibru!!!"


flip : Content -> Int -> Model
flip content day =
    HasContent { greetings = List.map (maybeFlip day) content.greetings }


maybeFlip : Int -> Greeting -> Greeting
maybeFlip day greeting =
    case ( greeting.day == day, String.isEmpty greeting.video ) of
        ( True, False ) ->
            { greeting | flipped = True }

        _ ->
            greeting



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html.Html Msg
view model =
    Element.layout [ Background.tiled "/static/seamless_snow.jpg" ]
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
    case greeting.flipped of
        True ->
            greetingVideo greeting

        False ->
            greetingCard greeting


greetingCard : Greeting -> Element.Element Msg
greetingCard greeting =
    Element.image
        [ Element.inFront <| styledDay greeting
        , Element.height <| Element.px cardHeight
        , Element.width <| Element.px cardWidth
        , Events.onClick <| Flipped greeting.day
        ]
        { src = "/static/pink_card.jpg", description = "A christmas card" }


styledDay : Greeting -> Element.Element Msg
styledDay greeting =
    Element.el
        [ cardNumberFont
        , Font.size 60
        , Font.shadow { offset = ( 1, 0.5 ), blur = 5, color = niceDark }
        , Font.color niceWhite
        , Element.centerX
        , Element.centerY
        ]
        (Element.text <| String.fromInt greeting.day)


greetingVideo : Greeting -> Element.Element Msg
greetingVideo greeting =
    Element.html <|
        Html.video [ HtmlAttrs.controls True, HtmlAttrs.height cardHeight, HtmlAttrs.width cardWidth ]
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
    Decode.map2 makeGreeting
        (Decode.field "day" Decode.int)
        (Decode.field "video" Decode.string)


makeGreeting : Int -> String -> Greeting
makeGreeting day video =
    { day = day, video = video, flipped = False }



-- Visual stuff


cardHeight =
    150


cardWidth =
    300


cardNumberFont : Element.Attribute Msg
cardNumberFont =
    Font.family
        [ Font.external
            { name = "Nerko One"
            , url = "https://fonts.googleapis.com/css2?family=Nerko+One&display=swap"
            }
        , Font.sansSerif
        ]


niceWhite =
    Element.rgb255 255 250 250


niceDark =
    Element.rgb255 149 124 124
