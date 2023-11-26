module Calendar exposing (..)

import Browser
import Element
import Element.Background as Background
import Element.Border
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
    Element.layout [ Background.image "/static/buble.jpg" ]
        (case model of
            HasContent content ->
                mainDisplay content

            Error reason ->
                Element.text reason

            Loading ->
                Element.text "Loading..."
        )


mainDisplay : Content -> Element.Element Msg
mainDisplay content =
    Element.column []
        [ styledHeader
        , displayContent content
        ]


styledHeader : Element.Element Msg
styledHeader =
    Element.el
        [ Font.size 60
        , Font.shadow { offset = ( 1, 0.5 ), blur = 5, color = niceDark }
        , Font.color niceDark
        , Element.centerX
        , Element.centerY
        , fancyFont
        , Element.padding 10
        ]
        (Element.text "Adventskalender 2023")


displayContent : Content -> Element.Element Msg
displayContent content =
    Element.wrappedRow
        [ Element.spaceEvenly
        , Element.padding 40
        ]
    <|
        List.map greetingBox
            content.greetings


greetingBox : Greeting -> Element.Element Msg
greetingBox greeting =
    Element.el [ Element.padding 20 ]
        (case greeting.flipped of
            True ->
                greetingVideo greeting

            False ->
                greetingCard greeting
        )


greetingCard : Greeting -> Element.Element Msg
greetingCard greeting =
    Element.el
        [ Element.inFront <| styledDay greeting
        , Element.height <| Element.px cardHeight
        , Element.width <| Element.px cardWidth
        , Events.onClick <| Flipped greeting.day
        , Element.pointer
        , Element.Border.width 1
        , Element.Border.color niceWhite
        ]
        (Element.text "")

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


fancyFont : Element.Attribute Msg
fancyFont =
    Font.family
        [ Font.external
            { name = "Dancing Script"
            , url = "https://fonts.googleapis.com/css2?family=Dancing+Script&display=swa"
            }
        , Font.sansSerif
        ]


niceWhite =
    Element.rgb255 255 250 250


niceDark =
    Element.rgb255 149 124 124
