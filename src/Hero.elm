module Hero
    exposing
        ( Hero
        , addExperience
        , init
        , injured
        , levelUp
        , move
        , pickup
        , setEquipment
        , setPosition
        , setStats
        , tick
        , view
        )

import Attributes exposing (Attributes)
import Equipment exposing (Equipment, EquipmentSlot)
import Html exposing (..)
import Html.Attributes as HA
import Item
import Item.Data
import Stats exposing (Stats)
import Types exposing (..)
import Utils.Direction as Direction exposing (Direction)
import Utils.Misc as Misc
import Utils.Vector as Vector exposing (Vector)


type alias Hero =
    { name : Name
    , type_ : Types.CreatureType
    , position : Vector
    , stats : Stats
    , gender : Gender
    , attributes : Attributes
    , equipment : Equipment
    , expLevel : Int
    , expPoints : Int
    , bodySize : Types.BodySize
    , attacks : Int
    }


type alias Name =
    String


init : Name -> Attributes -> Gender -> Hero
init name ({ str, int, con } as attributes) gender =
    { name = name
    , type_ = Types.Hero
    , position = ( 11, 17 )
    , stats = Stats.init attributes
    , gender = gender
    , attributes = attributes
    , equipment = Equipment.init
    , expLevel = 1
    , expPoints = 0
    , bodySize = Types.Medium
    , attacks = 1
    }


{-| Experience level increases
2 - 225
3 - 337
-}
addExperience : Int -> Hero -> Hero
addExperience expIncrease ({ expLevel, expPoints } as hero) =
    let
        increasedExperiencePoints =
            expPoints + expIncrease

        pointsRequiredToLevel =
            expLevel * 100
    in
    case increasedExperiencePoints > pointsRequiredToLevel of
        True ->
            hero
                |> levelUp
                |> addExperience (increasedExperiencePoints - pointsRequiredToLevel)

        False ->
            { hero | expPoints = increasedExperiencePoints }


setEquipment : Equipment -> Hero -> Hero
setEquipment equipment hero =
    { hero | equipment = equipment }


setPosition : Vector -> Hero -> Hero
setPosition newPosition model =
    { model | position = newPosition }


setStats : Stats -> Hero -> Hero
setStats stats model =
    { model | stats = stats }


tick : Hero -> Hero
tick hero =
    { hero | stats = Stats.tick hero.stats }


injured : Hero -> Bool
injured { stats } =
    stats.currentHP < stats.maxHP


levelUp : Hero -> Hero
levelUp hero =
    { hero
        | stats = Stats.incLevel 1 hero.attributes hero.stats
        , expLevel = hero.expLevel + 1
    }


move : Direction -> Hero -> Hero
move direction model =
    direction
        |> Vector.fromDirection
        |> Vector.add model.position
        |> (\x -> { model | position = x })


pickup : List Item.Data.Item -> Hero -> ( Hero, List Item.Data.Item, List String )
pickup items hero =
    let
        ( hero_, msgs, failedToPickup ) =
            List.foldl pickup_ ( hero, [], [] ) items
    in
    ( hero_, failedToPickup, msgs )


pickup_ : Item.Data.Item -> ( Hero, List String, List Item.Data.Item ) -> ( Hero, List String, List Item.Data.Item )
pickup_ item ( hero, messages, remainingItems ) =
    let
        heroUpdate equipment =
            { hero | equipment = equipment }
    in
    case Equipment.putInPack item hero.equipment of
        Result.Ok eq ->
            ( heroUpdate eq, messages, remainingItems )

        Result.Err errMsg ->
            ( hero, ("Failed to pick up item: " ++ Item.name item ++ " because: " ++ errMsg) :: messages, item :: remainingItems )



-- View


view : Hero -> Html a
view model =
    let
        heroCss =
            if model.gender == Male then
                "male-hero"
            else
                "female-hero"
    in
    div
        [ HA.class ("tile " ++ heroCss)
        , HA.style (Misc.vectorToHtmlStyle model.position)
        ]
        []
