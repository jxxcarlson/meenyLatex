module MiniLatex.Edit exposing (Data, emptyData, init, update, get, parse, LaTeXMsg(..))

{-| Data structures and functions for managing interactive edits. The parse tree, rendered text, and other information needed
for this is stored in a value of type

    MiniLatex.Edit.Data

That data is initialized using

    data =
        init version text

where the version is an integer that distinguishes
different edits.


# API

@docs Data, emptyData, init, update, get, parse, LaTeXMsg

-}

import Html exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Html.Keyed as Keyed
import Internal.Differ
import Internal.LatexDiffer
import Internal.Paragraph
import Internal.Parser
import Internal.Render2
import MiniLatex.Render exposing (MathJaxRenderOption)


{-| Data for differential parsing and rendering
-}
type alias Data a =
    Internal.Differ.EditRecord a


{-| Use this type so that clicks in the rendered text can be detected
-}
type LaTeXMsg
    = IDClicked String


{-| Create Data from a string of MiniLaTeX text and a version number.
The version number should be different for each call of init.
-}
init : MathJaxRenderOption -> Int -> String -> Data (Html LaTeXMsg)
init mathJaxRenderOption version source =
    Internal.LatexDiffer.update
        version
        Internal.Parser.parse
        (Internal.Render2.renderLatexList mathJaxRenderOption source)
        (Internal.Render2.renderString mathJaxRenderOption)
        Internal.Differ.emptyHtmlMsgRecord
        source


{-| Update Data with modified text, re-parsing and re-rerendering changed elements.
-}
update : MathJaxRenderOption -> Int -> String -> Data (Html LaTeXMsg) -> Data (Html LaTeXMsg)
update mathJaxRenderOption version source editRecord =
    Internal.LatexDiffer.update
        version
        Internal.Parser.parse
        (Internal.Render2.renderLatexList mathJaxRenderOption source)
        (Internal.Render2.renderString mathJaxRenderOption)
        editRecord
        source


{-| Retrieve Html from a Data object.
-}
get : Data (Html LaTeXMsg) -> List (Html LaTeXMsg)
get editRecord =
    let
        paragraphs =
            editRecord.renderedParagraphs

        ids =
            editRecord.idList
    in
    List.map2 (\para id -> Keyed.node "p" [ HA.id id, HE.onClick (IDClicked id), HA.style "margin-bottom" "10px" ] [ ( id, para ) ]) paragraphs ids


{-| Used for initialization.
-}
emptyData : Data (Html LaTeXMsg)
emptyData =
    Internal.Differ.emptyHtmlMsgRecord


{-| Parse the given text and return an AST representing it.
-}
parse : String -> ( List String, List (List Internal.Parser.LatexExpression) )
parse text =
    let
        paragraphs =
            Internal.Paragraph.logicalParagraphify text
    in
    ( paragraphs, List.map Internal.Parser.parse paragraphs )