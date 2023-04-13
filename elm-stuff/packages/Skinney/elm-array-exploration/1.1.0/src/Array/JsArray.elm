module Array.JsArray
    exposing
        ( JsArray
        , empty
        , singleton
        , length
        , initialize
        , listInitialize
        , unsafeGet
        , unsafeSet
        , push
        , foldl
        , foldr
        , map
        , slice
        , merge
        )

import Native.JsArray


type JsArray a
    = JsArray a


empty : JsArray a
empty =
    Native.JsArray.empty


singleton : a -> JsArray a
singleton =
    Native.JsArray.singleton


length : JsArray a -> Int
length =
    Native.JsArray.length


initialize : Int -> Int -> (Int -> a) -> JsArray a
initialize =
    Native.JsArray.initialize


listInitialize : List a -> Int -> ( List a, JsArray a )
listInitialize =
    Native.JsArray.listInitialize


unsafeGet : Int -> JsArray a -> a
unsafeGet =
    Native.JsArray.unsafeGet


unsafeSet : Int -> a -> JsArray a -> JsArray a
unsafeSet =
    Native.JsArray.unsafeSet


push : a -> JsArray a -> JsArray a
push =
    Native.JsArray.push


foldl : (a -> b -> b) -> b -> JsArray a -> b
foldl =
    Native.JsArray.foldl


foldr : (a -> b -> b) -> b -> JsArray a -> b
foldr =
    Native.JsArray.foldr


map : (a -> b) -> JsArray a -> JsArray b
map =
    Native.JsArray.map


slice : Int -> Int -> JsArray a -> JsArray a
slice =
    Native.JsArray.slice


merge : JsArray a -> JsArray a -> Int -> JsArray a
merge =
    Native.JsArray.merge
