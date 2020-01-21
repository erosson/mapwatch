module SpeechTest exposing (..)

import Dict exposing (Dict)
import Expect
import Mapwatch.Instance as Instance exposing (Address)
import Mapwatch.MapRun as MapRun exposing (MapRun)
import Speech exposing (Speech)
import Test exposing (..)
import Time exposing (Posix)


emptyAddr : Address
emptyAddr =
    { zone = "nowhere", addr = "127.0.0.1:6112", worldArea = Nothing }


emptySettings =
    { volume = 100 }


emptyRaw =
    { address = emptyAddr
    , startedAt = Time.millisToPosix 0
    , portals = 0
    , npcSays = Dict.empty
    , visits = []
    }


emptyVisit =
    { instance = Instance.Instance emptyAddr
    , joinedAt = Time.millisToPosix 0
    , leftAt = Time.millisToPosix 0
    }


emptyRun =
    MapRun.fromRaw emptyRaw


all : Test
all =
    describe "Speech"
        [ test "nothing" <|
            \_ ->
                Speech.joinInstance emptySettings True Nothing Nothing
                    |> Expect.equal Nothing
        , test "now starting" <|
            \_ ->
                Speech.joinInstance emptySettings True (Just emptyRaw) Nothing
                    |> Expect.equal (Just { text = "mapwatch now starting nowhere. ", volume = 1.0 })
        , test "not starting; nonempty visits" <|
            \_ ->
                Speech.joinInstance emptySettings True (Just { emptyRaw | visits = [ emptyVisit ] }) Nothing
                    |> Expect.equal Nothing
        , test "history not done" <|
            \_ ->
                Speech.joinInstance emptySettings False (Just emptyRaw) Nothing
                    |> Expect.equal Nothing
        , test "timer stopped" <|
            \_ ->
                Speech.joinInstance emptySettings True Nothing (Just emptyRun)
                    |> Expect.equal (Just { text = "mapwatch finished in 0 minutes 0 seconds for nowhere.  timer stopped. ", volume = 1.0 })
        , test "finished > now starting" <|
            \_ ->
                Speech.joinInstance emptySettings True (Just emptyRaw) (Just emptyRun)
                    |> Expect.equal (Just { text = "mapwatch finished in 0 minutes 0 seconds for nowhere.  now starting nowhere. ", volume = 1.0 })
        ]