module MiniLatex.EditSimple exposing (Data, emptyData, init, update, get, render, renderWithVersion, LaTeXMsg)

{-| This module is like MiniLaTeX.Edit, except that the Data type, which is an
alias of the record type `Internal.DifferSimple.EditRecord`, contains no functions.


# API

@docs Data, emptyData, init, update, get, render, renderWithVersion, LaTeXMsg

-}

import Html exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Html.Keyed as Keyed
import Internal.Accumulator as Accumulator
import Internal.DifferSimple
import Internal.LatexDifferSimple
import Internal.Paragraph
import Internal.Parser
import Internal.Render


{-| Data structures and functions for managing interactive edits. The parse tree, rendered text, and other information needed
for this is stored in a value of type

    MiniLatex.Edit.Data

That data is initialized using

    data =
        init version text

where the version is an integer that distinguishes
different edits.


# API

@docs Data, emptyData, init, update, get, LaTeXMsg

-}
type alias Data =
    Internal.DifferSimple.EditRecord


{-| Use this type so that clicks in the rendered text can be detected
-}
type LaTeXMsg
    = IDClicked String



-- render : String -> Html LaTeXMsg
-- render source =
--     init 0 source
--         |> get "-"
--         |> (\list -> Html.div [] list)


{-| Simplest function for rendering a string of LaTeX
-}
render : String -> List (Html LaTeXMsg)
render source =
    init 1 source Nothing |> get "-"


{-| Like 'render', but adds a 'version' id to the Html.
This is used in applications that edit LaTeX text
-}
renderWithVersion : Int -> String -> List (Html LaTeXMsg)
renderWithVersion version source =
    init version source Nothing |> get "-"


{-| Create Data from a string of MiniLaTeX text and a version number.
The version number should be different for each call of init.
-}
init : Int -> String -> Maybe String -> Data
init seed source mpreamble =
    Internal.LatexDifferSimple.update
        seed
        Internal.Parser.parse
        Internal.DifferSimple.emptyEditRecord
        source
        mpreamble



--update : Int -> (String -> List LatexExpression) -> EditRecord -> String -> Maybe String -> EditRecord
--update seed parser editRecord text mpreamble


{-| Update Data with modified text, re-parsing and re-rerendering changed elements.
-}
update : Int -> String -> Maybe String -> Data -> Data
update version source mpreamble editRecord =
    Internal.LatexDifferSimple.update
        version
        Internal.Parser.parse
        editRecord
        source
        mpreamble


{-| Retrieve Html from a Data object and construct
the click handlers used to highlight the selected paragraph
(if any). Example:

    get "p.1.10" data

will retrieve the rendered text and will hightlight the paragraph
with ID "p.1.10". The ID decodes
as "paragraph 10, version 1". The version number
of a paragraph is incremented when it is edited.

-}
get : String -> Data -> List (Html LaTeXMsg)
get selectedId data =
    let
        ( _, paragraphs_ ) =
            Accumulator.renderNew Internal.Render.renderLatexListToList data.latexState data.astList

        paragraphs =
            List.map
                (Html.div [ HA.style "white-space" "normal", HA.style "line-height" "1.5" ])
                paragraphs_

        mark id_ =
            if selectedId == id_ then
                "select:" ++ id_

            else if String.left 7 id_ == "selected:" then
                String.dropLeft 7 id_

            else
                id_

        ids =
            data.idList
                |> List.map mark

        keyedNode : String -> Html LaTeXMsg -> Html LaTeXMsg
        keyedNode id para =
            Keyed.node "p"
                [ HA.id id
                , selectedStyle selectedId id
                , HE.onClick (IDClicked id)

                -- , HA.style "margin-bottom" "0px"
                ]
                [ ( id, para ) ]
    in
    List.map2 keyedNode ids paragraphs


selectedStyle : String -> String -> Html.Attribute LaTeXMsg
selectedStyle targetId currentId =
    case ("select:" ++ targetId) == currentId of
        True ->
            HA.style "background-color" highlightColor

        False ->
            HA.style "background-color" "#fff"


highlightColor =
    "#d7d6ff"


{-| Used for initialization.
-}
emptyData : Data
emptyData =
    Internal.DifferSimple.emptyEditRecord


{-| Parse the given text and return an AST representing it.
-}
parse : String -> ( List String, List (List Internal.Parser.LatexExpression) )
parse text =
    let
        paragraphs =
            Internal.Paragraph.logicalParagraphify text
    in
    ( paragraphs, List.map Internal.Parser.parse paragraphs )
