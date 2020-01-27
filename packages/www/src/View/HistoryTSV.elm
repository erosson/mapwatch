module View.HistoryTSV exposing (view)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Mapwatch
import Model exposing (Msg, OkModel)
import View.History
import View.Home
import View.Nav
import View.Setup
import View.Spreadsheet as Spreadsheet


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
            viewMain model


viewMain : OkModel -> Html Msg
viewMain model =
    let
        sheet =
            Spreadsheet.viewData model (View.History.listRuns model)
    in
    div []
        [ p []
            [ text "Copy and paste the "
            , b [] [ text "Tab-Separated Values" ]
            , text " below into your favorite spreadsheet application."
            ]
        , textarea [ readonly True, rows 40, cols 100 ]
            [ model
                |> View.History.listRuns
                |> Spreadsheet.viewData model
                |> viewSheet
            ]
        ]


viewSheet : Spreadsheet.Sheet -> Html msg
viewSheet sheet =
    sheet.headers
        ++ (sheet.rows |> List.map (List.map viewCell))
        |> List.map (String.join "\t")
        |> String.join "\n"
        |> text


viewCell : Spreadsheet.Cell -> String
viewCell c =
    esc <|
        case c of
            Spreadsheet.CellEmpty ->
                ""

            Spreadsheet.CellString s ->
                "'" ++ s

            Spreadsheet.CellDuration d ->
                "'" ++ View.Home.formatDuration d

            Spreadsheet.CellPosix tz t ->
                Spreadsheet.posixToString tz t

            Spreadsheet.CellBool b ->
                if b then
                    "TRUE"

                else
                    ""

            Spreadsheet.CellInt n ->
                String.fromInt n

            Spreadsheet.CellFloat n ->
                String.fromFloat n

            Spreadsheet.CellIcon src ->
                "=IMAGE(\"" ++ src ++ "\")"


esc : String -> String
esc =
    String.replace "\\" "\\\\" >> String.replace "\t" "\\t"
