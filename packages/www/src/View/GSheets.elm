module View.GSheets exposing (view)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import ISO8601
import Json.Encode as E
import Mapwatch
import Mapwatch.MapRun as MapRun exposing (MapRun)
import Maybe.Extra
import Model exposing (Msg, OkModel)
import RemoteData exposing (RemoteData)
import Route.Feature as Feature exposing (Feature)
import Time exposing (Posix)
import View.History
import View.Home
import View.Icon
import View.Nav
import View.NotFound
import View.Setup
import View.Spreadsheet as Spreadsheet


view : OkModel -> Html Msg
view model =
    if Feature.isActive Feature.GSheets model.query then
        div [ class "main" ]
            [ View.Home.viewHeader model
            , View.Nav.view model
            , View.Setup.view model
            , viewBody model
            ]

    else
        View.NotFound.view model


viewBody : OkModel -> Html Msg
viewBody model =
    case Mapwatch.ready model.mapwatch of
        Mapwatch.NotStarted ->
            div [] []

        Mapwatch.LoadingHistory p ->
            View.Home.viewProgress p

        Mapwatch.Ready p ->
            viewMain model


viewMain : OkModel -> Html Msg
viewMain model =
    case model.gsheets of
        RemoteData.NotAsked ->
            div []
                [ p [] [ text "Login to your Google account below to create a spreadsheet with your Mapwatch data." ]
                , button [ onClick Model.GSheetsLogin ] [ text "Login to Google Sheets" ]
                ]

        RemoteData.Loading ->
            div []
                [ button [ disabled True ] [ View.Icon.fasPulse "spinner", text " Login to Google Sheets" ]
                ]

        RemoteData.Failure err ->
            div []
                [ button [ onClick Model.GSheetsLogin ] [ text "Login to Google Sheets" ]
                , pre [] [ text err ]
                ]

        RemoteData.Success gsheets ->
            let
                runs =
                    View.History.listRuns model
            in
            div []
                [ div []
                    [ button [ onClick Model.GSheetsLogout ]
                        [ text "Logout of Google Sheets" ]
                    ]
                , div []
                    [ case ( gsheets.url, model.settings.spreadsheetId ) of
                        ( RemoteData.Loading, _ ) ->
                            button [ disabled True ]
                                [ View.Icon.fasPulse "spinner", text <| " Write " ++ String.fromInt (List.length runs) ++ " maps to spreadsheet id: " ]

                        ( _, Nothing ) ->
                            button [ onClick <| gsheetsWrite model runs Nothing ]
                                [ text <| "Write " ++ String.fromInt (List.length runs) ++ " maps to a new spreadsheet" ]

                        ( _, Just id ) ->
                            button [ onClick <| gsheetsWrite model runs (Just id) ]
                                [ text <| "Write " ++ String.fromInt (List.length runs) ++ " maps to spreadsheet id: " ]
                    , input
                        [ type_ "text"
                        , value <| Maybe.withDefault "" model.settings.spreadsheetId
                        , onInput Model.InputSpreadsheetId
                        ]
                        []
                    ]
                , case gsheets.url of
                    RemoteData.NotAsked ->
                        div [] []

                    RemoteData.Loading ->
                        div [] [ View.Icon.fasPulse "spinner" ]

                    RemoteData.Failure err ->
                        div [] [ pre [] [ text err ] ]

                    RemoteData.Success url ->
                        div []
                            [ p []
                                [ text "Export successful! "
                                , a [ target "_blank", href url ] [ text "View your spreadsheet." ]
                                ]
                            ]
                ]


gsheetsWrite : OkModel -> List MapRun -> Maybe String -> Msg
gsheetsWrite model runs spreadsheetId =
    Model.GSheetsWrite
        { spreadsheetId = spreadsheetId
        , title = "Mapwatch"
        , content =
            [ Spreadsheet.viewData model runs
            ]
                |> List.map encodeSheet
        }


encodeSheet : Spreadsheet.Sheet -> Model.Sheet
encodeSheet s =
    { title = s.title
    , headers = s.headers
    , rows = s.rows |> List.map (List.map encodeCell)
    }


encodeCell : Spreadsheet.Cell -> E.Value
encodeCell c =
    -- https://developers.google.com/sheets/api/reference/rest/v4/spreadsheets/other#ExtendedValue
    case c of
        Spreadsheet.CellEmpty ->
            stringValue ""

        Spreadsheet.CellString s ->
            stringValue s

        Spreadsheet.CellDuration d ->
            stringValue <| View.Home.formatDuration d

        Spreadsheet.CellPosix tz d ->
            posixValue tz d

        Spreadsheet.CellBool b ->
            boolValue b

        Spreadsheet.CellInt n ->
            numberValue <| toFloat n

        Spreadsheet.CellFloat n ->
            numberValue n

        Spreadsheet.CellIcon src ->
            formulaValue <| "=IMAGE(\"" ++ src ++ "\")"


cellValue : String -> E.Value -> E.Value
cellValue k v =
    E.object [ ( "userEnteredValue", E.object [ ( k, v ) ] ) ]


posixValue : Time.Zone -> Posix -> E.Value
posixValue tz d =
    let
        t =
            Spreadsheet.posixToString tz d
    in
    E.object
        -- [ ( "userEnteredValue", E.object [ ( "formulaValue", E.string <| "=TO_DATE(DATEVALUE(\"" ++ t ++ "\") + TIMEVALUE(\"" ++ t ++ "\"))" ) ] )
        [ ( "userEnteredValue", E.object [ ( "stringValue", E.string t ) ] )
        , ( "userEnteredFormat", E.object [ ( "numberFormat", E.object [ ( "type", E.string "DATE_TIME" ) ] ) ] )
        ]


stringValue : String -> E.Value
stringValue s =
    cellValue "stringValue" <| E.string s


boolValue : Bool -> E.Value
boolValue b =
    if b then
        cellValue "boolValue" <| E.bool b

    else
        stringValue ""


numberValue : Float -> E.Value
numberValue n =
    cellValue "numberValue" <| E.float n


formulaValue : String -> E.Value
formulaValue f =
    cellValue "formulaValue" <| E.string f
