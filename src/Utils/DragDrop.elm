module Utils.DragDrop
    exposing
        ( DragDrop
        , Msg
        , draggable
        , droppable
        , init
        , source
        , subscription
        , target
        , update
        , view
        )

import Html as H exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode as JD
import Mouse


type DragDrop source target
    = A (Model source target)


type alias Model source target =
    { source : Maybe source
    , target : Maybe target
    , position : Mouse.Position
    , dragging : Maybe (Dragging source target)
    }


type alias Dragging source target =
    { start : Mouse.Position
    , current : Mouse.Position
    , html : Html (Msg source target)
    }


type Msg source target
    = Start (Maybe source) (Html (Msg source target)) Mouse.Position
    | At (Maybe source) (Html (Msg source target)) Mouse.Position
    | End (Maybe source) (Maybe target) Mouse.Position
    | MouseOver (Maybe target)
    | MouseLeave


init : DragDrop s t
init =
    A
        { source = Nothing
        , target = Nothing
        , position = Mouse.Position 0 0
        , dragging = Nothing
        }


source : DragDrop s t -> Maybe s
source (A { source }) =
    source


target : DragDrop s t -> Maybe t
target (A { target }) =
    target


update : Msg s t -> DragDrop s t -> ( DragDrop s t, Maybe ( Maybe s, Maybe t ) )
update msg (A model) =
    let
        startDrag source html pos =
            Model source model.target pos (Just (Dragging pos pos html))

        atDrag source html pos =
            Model source model.target model.position (Maybe.map (\{ start } -> Dragging start pos html) model.dragging)
    in
    case msg of
        Start source html pos ->
            ( A (startDrag source html pos), Nothing )

        At source html pos ->
            ( A <| atDrag source html pos, Nothing )

        -- on drag end, check if it's over a droppable container
        End s t _ ->
            ( A model, Just ( s, t ) )

        --(handleMouseUp model)
        MouseOver target ->
            ( A { model | target = target }, Nothing )

        MouseLeave ->
            ( A { model | target = Nothing }, Nothing )


view : DragDrop s t -> Html (Msg s t)
view (A ({ source, position, dragging } as model)) =
    let
        px x =
            toString x ++ "px"

        ( newX, newY ) =
            getDisplacement model
                |> (\pos -> ( pos.x - 40, pos.y - 40 ))

        positionStyle =
            HA.style
                [ ( "top", px newY )
                , ( "left", px newX )
                , ( "position", "absolute" )
                , ( "cursor", "move" )
                ]

        pointerEventStyle =
            HA.style [ ( "pointer-events", "none" ) ]
    in
    case model.dragging of
        Just { start, current, html } ->
            H.div [ positionStyle, pointerEventStyle, HA.class "draggable" ] [ html ]

        _ ->
            H.div [] []


{-| DnDModel tracks where the mouse starts and where it currently is to get the absolute
movement from when mouse down happens. This is the actual drag distance.
-}
getDisplacement : Model s t -> Mouse.Position
getDisplacement { source, target, position, dragging } =
    case dragging of
        Nothing ->
            position

        Just { start, current } ->
            Mouse.Position (position.x + current.x - start.x)
                (position.y + current.y - start.y)


{-| Takes a html snippet that can be dragged and drag it around the screen.
The snippet is attached to a arbitrary Drag source which is given to the Drop target when dropped.
-}
draggable : Html (Msg a b) -> a -> DragDrop c d -> Html (Msg a b)
draggable draggableHtml source (A model) =
    let
        onMouseDown =
            HE.onWithOptions "mousedown"
                { stopPropagation = True, preventDefault = True }
                (JD.map (Start (Just source) draggableHtml) Mouse.position)

        pointerEventStyle =
            case model.dragging of
                Just _ ->
                    HA.style [ ( "pointer-events", "none" ) ]

                Nothing ->
                    HA.style [ ( "pointer-events", "inherit" ) ]
    in
    H.div [ onMouseDown, pointerEventStyle ] [ draggableHtml ]


{-| Creates a piece of html which will accept things dropped onto it.
-}
droppable : t -> DragDrop s t -> Html (Msg s t) -> Html (Msg s t)
droppable dropTarget (A model) html =
    let
        target =
            Just dropTarget

        borderStyle =
            if model.target == target && model.source /= Nothing then
                HA.style [ ( "background-color", "lightblue" ) ]
            else
                HA.style []

        mouseEvents =
            [ HE.on "mouseover" (JD.succeed <| MouseOver target)
            , HE.onMouseLeave MouseLeave
            ]

        dragDropClass =
            HA.class "dragdrop-droppable"
    in
    H.div (borderStyle :: dragDropClass :: mouseEvents) [ html ]


subscription : DragDrop s t -> Sub (Msg s t)
subscription (A model) =
    case model.source of
        Nothing ->
            Sub.none

        source ->
            case model.dragging of
                Just { html } ->
                    Sub.batch
                        [ Mouse.moves (At source html)
                        , Mouse.ups (End model.source model.target)
                        ]

                _ ->
                    Sub.none
