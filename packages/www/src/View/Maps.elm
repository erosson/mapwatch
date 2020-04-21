module View.Maps exposing (GroupedRuns, applySort, groupRuns, view)

import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Json.Encode as Json
import Localized
import Mapwatch
import Mapwatch.Datamine as Datamine exposing (Datamine, WorldArea)
import Mapwatch.Instance as Instance exposing (Instance)
import Mapwatch.MapRun as MapRun exposing (MapRun)
import Mapwatch.MapRun.Sort as RunSort
import Maybe.Extra
import Model as Model exposing (Msg(..), OkModel)
import Route exposing (Route)
import Route.QueryDict as QueryDict exposing (QueryDict)
import Time exposing (Posix)
import View.History
import View.Home
import View.Icon
import View.Nav
import View.Setup
import View.Util


view : OkModel -> Html Msg
view model =
    div [ class "main" ]
        [ View.Home.viewHeader model
        , View.Nav.view model
        , View.Setup.view model
        , viewBody model
        ]


viewBody : OkModel -> Html Msg
viewBody model =
    case Mapwatch.ready model.mapwatch of
        Mapwatch.NotStarted ->
            div [] []

        Mapwatch.LoadingHistory p ->
            View.Home.viewProgress p

        Mapwatch.Ready p ->
            div []
                [ viewMain model
                , View.Home.viewProgress p
                ]


applySearch : Datamine -> Maybe String -> List MapRun -> List MapRun
applySearch dm mq =
    case mq of
        Nothing ->
            identity

        Just q ->
            RunSort.search dm q


{-| parse and apply the "?o=..." querytring parameter
-}
applySort : Maybe String -> List GroupedRuns -> List GroupedRuns
applySort o =
    let
        ( col, dir ) =
            case Maybe.map (String.split "-") o of
                Just [ c, "desc" ] ->
                    ( c, List.reverse )

                Just [ c, _ ] ->
                    ( c, identity )

                Just [ c ] ->
                    ( c, identity )

                _ ->
                    ( "runs", List.reverse )
    in
    (case col of
        "name" ->
            List.sortBy .name

        "region" ->
            List.sortBy (.worldArea >> .atlasRegion >> Maybe.withDefault Datamine.defaultAtlasRegion)

        "tier" ->
            List.sortBy (.worldArea >> Datamine.tier >> Maybe.withDefault 0)

        "runs" ->
            List.sortBy (.runs >> .num)

        "bestdur" ->
            List.sortBy (.runs >> .best >> .mainMap >> Maybe.withDefault 0)

        "meandur" ->
            List.sortBy (.runs >> .mean >> .duration >> .all)

        "portals" ->
            List.sortBy (.runs >> .mean >> .portals)

        _ ->
            List.sortBy (.worldArea >> Datamine.tier >> Maybe.withDefault 0)
    )
        >> dir


type alias GroupedRuns =
    { name : String, worldArea : WorldArea, runs : MapRun.Aggregate }


viewMain : OkModel -> Html Msg
viewMain model =
    let
        before =
            QueryDict.getPosix Route.keys.before model.query

        after =
            QueryDict.getPosix Route.keys.after model.query

        search =
            Dict.get Route.keys.search model.query

        runs : List MapRun
        runs =
            model.mapwatch.runs
                |> List.filter (\r -> not r.isAbandoned)
                |> applySearch model.mapwatch.datamine search
                |> RunSort.filterBetween { before = before, after = after }

        rows : List (Html msg)
        rows =
            runs
                |> groupRuns model.mapwatch.datamine
                |> applySort (Dict.get Route.keys.sort model.query)
                |> List.map (viewMap model.query)
    in
    div []
        [ View.Util.viewSearch [] model.query
        , View.Util.viewDateSearch model.query model.route
        , table [ class "by-map" ]
            [ thead [] [ header model.query ]
            , tbody [] rows
            ]
        ]


groupRuns : Datamine -> List MapRun -> List GroupedRuns
groupRuns dm =
    RunSort.groupByMap
        >> Dict.toList
        >> List.filterMap
            (\( id, runGroup ) ->
                case runGroup of
                    [] ->
                        Nothing

                    firstMap :: _ ->
                        firstMap.address.worldArea
                            |> Maybe.map
                                (\w ->
                                    { name = firstMap.address.zone
                                    , worldArea = w
                                    , runs = MapRun.aggregate runGroup
                                    }
                                )
            )


header : QueryDict -> Html msg
header query =
    let
        cell : String -> Html msg -> Html msg
        cell col label =
            th [] [ a [ headerHref query col ] [ label ] ]
    in
    tr []
        [ cell "name" <| Localized.text0 "maps-header-name"
        , cell "region" <| Localized.text0 "maps-header-region"
        , cell "tier" <| Localized.text0 "maps-header-tier"
        , cell "meandur" <| Localized.text0 "maps-header-meandur"
        , cell "portals" <| Localized.text0 "maps-header-portals"
        , cell "runs" <| Localized.text0 "maps-header-count"
        , cell "bestdur" <| Localized.text0 "maps-header-bestdur"
        ]


headerHref : QueryDict -> String -> Attribute msg
headerHref query col =
    let
        sort =
            if Just col == Dict.get Route.keys.sort query then
                col ++ "-desc"

            else
                col
    in
    Route.href (View.Util.insertSearch sort query) Route.Maps


viewMap : QueryDict -> GroupedRuns -> Html msg
viewMap query { name, worldArea, runs } =
    let
        { mean, best, num } =
            runs
    in
    tr []
        [ td [ class "zone" ] [ viewMapName query name worldArea ]
        , td [] [ viewRegionName query worldArea ]
        , td []
            (case Datamine.tier worldArea of
                Nothing ->
                    []

                Just tier ->
                    [ Localized.text "maps-row-tier" [ ( "tier", Json.int tier ) ] ]
            )
        , td [] [ Localized.text "maps-row-meandur" [ ( "duration", Json.string <| View.Home.formatDuration mean.duration.mainMap ) ] ]
        , td [] [ Localized.text "maps-row-portals" [ ( "count", Json.float mean.portals ) ] ]
        , td [] [ Localized.text "maps-row-count" [ ( "count", Json.int num ) ] ]
        , td [] [ Localized.text "maps-row-bestdur" [ ( "duration", Json.string <| Maybe.Extra.unwrap "--:--" View.Home.formatDuration best.mainMap ) ] ]
        ]


viewRegionName : QueryDict -> WorldArea -> Html msg
viewRegionName query w =
    let
        name =
            w.atlasRegion |> Maybe.withDefault Datamine.defaultAtlasRegion
    in
    View.Home.viewRegion (View.Util.insertSearch name query) (Just w)


viewMapName : QueryDict -> String -> WorldArea -> Html msg
viewMapName query name worldArea =
    a [ Route.href (View.Util.insertSearch name query) Route.History ]
        [ View.Icon.mapOrBlank { isBlightedMap = False } (Just worldArea), text name ]
