module Item.Purse
    exposing
        ( add
        , addCoins
        , init
        , initCoppers
        , initGolds
        , initPlatinums
        , initSilvers
        , merge
        , ppCoins
        , remove
        , toLeastCoins
        )

import Item.Data exposing (..)
import Utils.Mass as Mass exposing (Mass)


init : Purse
init =
    ( BaseItem "Purse" (ItemValue 0) "Purse" (Mass.Mass 0 0) Normal Identified
    , { coins = Coins 100 10 1 1
      }
    )


initCoinBaseItem : String -> String -> Int -> BaseItem
initCoinBaseItem name css value =
    BaseItem name (ItemValue value) css (Mass.Mass 0 0) Normal Identified


initCoppers : Int -> ( BaseItem, Int )
initCoppers value =
    ( initCoinBaseItem "Copper" "coins-copper" value, value )


initSilvers : Int -> ( BaseItem, Int )
initSilvers value =
    ( initCoinBaseItem "Silver" "coins-silver" value, value )


initGolds : Int -> ( BaseItem, Int )
initGolds value =
    ( initCoinBaseItem "Gold" "coins-gold" value, value )


initPlatinums : Int -> ( BaseItem, Int )
initPlatinums value =
    ( initCoinBaseItem "Platinum" "coins-platinum" value, value )


add : Int -> Purse -> Purse
add coppers ( base, { coins } as detail ) =
    let
        leastCoins =
            toLeastCoins coppers
    in
    ( base
    , { detail
        | coins =
            Coins (coins.copper + leastCoins.copper)
                (coins.silver + leastCoins.silver)
                (coins.gold + leastCoins.gold)
                (coins.platinum + leastCoins.platinum)
      }
    )


addCoins : Coins -> Purse -> Purse
addCoins newCoins ( base, { coins } ) =
    ( base, { coins = merge_ (+) newCoins coins } )


merge : Purse -> Purse -> Purse
merge ( base1, detail1 ) ( base2, detail2 ) =
    ( base1, { coins = merge_ (+) detail1.coins detail2.coins } )


{-| Perform an operation (+, -, etc...) on each denomination of two purses
-}
merge_ : (Int -> Int -> Int) -> Coins -> Coins -> Coins
merge_ op c1 c2 =
    Coins (op c1.copper c2.copper)
        (op c1.silver c2.silver)
        (op c1.gold c2.gold)
        (op c1.platinum c2.platinum)


remove : Int -> Purse -> Result String Purse
remove copperToRemove ( base, { coins } as detail ) =
    let
        totalSilvers =
            coins.copper + coins.silver * 10

        totalGold =
            totalSilvers + coins.gold * 100

        totalPlatinum =
            totalGold + coins.platinum * 1000
    in
    if copperToRemove <= coins.copper then
        Result.Ok ( base, { detail | coins = { coins | copper = coins.copper - copperToRemove } } )
    else if copperToRemove <= totalSilvers then
        let
            ( copper_, silver_ ) =
                toLeastSilvers (totalSilvers - copperToRemove)
        in
        Result.Ok ( base, { detail | coins = { coins | copper = copper_, silver = silver_ } } )
    else if copperToRemove <= totalGold then
        let
            ( copper_, silver_, gold_ ) =
                toLeastGold (totalGold - copperToRemove)
        in
        Result.Ok ( base, { detail | coins = { coins | copper = copper_, silver = silver_, gold = gold_ } } )
    else if copperToRemove <= totalPlatinum then
        let
            coins =
                toLeastCoins (totalPlatinum - copperToRemove)
        in
        Result.Ok ( base, { detail | coins = { coins | copper = coins.copper, silver = coins.silver, gold = coins.gold, platinum = coins.platinum } } )
    else
        Result.Err "Ops! Looks like you don't have enough coins."


{-| Prints coins out in a nice readable way: 4 platinum, 3 silver and 10 copper pieces
-}
ppCoins : Coins -> String
ppCoins { copper, silver, gold, platinum } =
    let
        coinPairs : List ( Int, String )
        coinPairs =
            [ ( platinum, "platinum" ), ( gold, "gold" ), ( silver, "silver" ), ( copper, "copper" ) ]

        greaterThanZero : ( Int, String ) -> Bool
        greaterThanZero ( x, _ ) =
            x > 0

        joinValueToUnit : ( Int, String ) -> String
        joinValueToUnit ( val, unit ) =
            toString val ++ " " ++ unit
    in
    coinPairs
        |> List.filter greaterThanZero
        |> List.map joinValueToUnit
        |> flip ppCoins_ ""


ppCoins_ : List String -> String -> String
ppCoins_ coinPairs currentString =
    case coinPairs of
        [] ->
            currentString

        a :: [] ->
            currentString ++ " " ++ a ++ " pieces"

        a :: b :: [] ->
            currentString ++ " " ++ a ++ " and " ++ b ++ " pieces"

        a :: rest ->
            (currentString ++ a ++ ", ")
                |> ppCoins_ rest


{-| Simplifies x coppers to the least number of coins of each denomination
-}
toLeastCoins : Int -> Coins
toLeastCoins coppers =
    let
        ( copper, silver, gold ) =
            toLeastGold coppers
    in
    Coins copper silver (gold % 10) (gold // 10)


toLeastGold : Int -> ( Int, Int, Int )
toLeastGold coins =
    let
        ( copper, silver ) =
            toLeastSilvers coins
    in
    ( copper, silver % 10, silver // 10 )


toLeastSilvers : Int -> ( Int, Int )
toLeastSilvers coins =
    ( coins % 10, coins // 10 )
