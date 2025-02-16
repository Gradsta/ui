{--
Copyright (c) 2022 Target Brands, Inc. All rights reserved.
Use of this source code is governed by the LICENSE file in this repository.
--}


module Pages.Secrets.Form exposing
    ( viewAllowCommandCheckbox
    , viewEventsSelect
    , viewHelp
    , viewImagesInput
    , viewInput
    , viewNameInput
    , viewSubmitButtons
    , viewValueInput
    )

import Html
    exposing
        ( Html
        , a
        , button
        , code
        , div
        , em
        , input
        , label
        , p
        , section
        , span
        , strong
        , text
        , textarea
        )
import Html.Attributes
    exposing
        ( checked
        , class
        , disabled
        , for
        , href
        , id
        , placeholder
        , rows
        , target
        , type_
        , value
        , wrap
        )
import Html.Events exposing (onClick, onInput)
import Pages.RepoSettings exposing (checkbox)
import Pages.Secrets.Model exposing (DeleteSecretState(..), Model, Msg(..), SecretForm)
import Util
import Vela exposing (Field)


{-| viewAddedImages : renders added images
-}
viewAddedImages : List String -> List (Html Msg)
viewAddedImages images =
    if List.length images > 0 then
        List.map addedImage <| List.reverse images

    else
        noImages


{-| noImages : renders when no images have been added
-}
noImages : List (Html Msg)
noImages =
    [ div [ class "added-image" ]
        [ div [ class "name" ] [ code [] [ text "enabled for all images" ] ]

        -- add button to match style
        , button
            [ class "button"
            , class "-outline"
            , class "visually-hidden"
            , disabled True
            ]
            [ text "remove"
            ]
        ]
    ]


{-| addedImage : renders added image
-}
addedImage : String -> Html Msg
addedImage image =
    div [ class "added-image", class "chevron" ]
        [ div [ class "name" ] [ text image ]
        , button
            [ class "button"
            , class "-outline"
            , onClick <| RemoveImage image
            ]
            [ text "remove"
            ]
        ]


{-| viewHelp : renders help msg pointing to Vela docs
-}
viewHelp : Html Msg
viewHelp =
    div [ class "help" ] [ text "Need help? Visit our ", a [ href secretsDocsURL, target "_blank" ] [ text "docs" ], text "!" ]


{-| viewNameInput : renders name input box
-}
viewNameInput : String -> Bool -> Html Msg
viewNameInput val disable =
    section [ class "form-control", class "-stack" ]
        [ label [ class "form-label", for <| "secret-name" ] [ strong [] [ text "Name" ] ]
        , input
            [ disabled disable
            , value val
            , onInput <|
                OnChangeStringField "name"
            , class "secret-name"
            , placeholder "Secret Name"
            , id "secret-name"
            ]
            []
        ]


{-| viewInput : renders value input box
-}
viewInput : String -> String -> String -> Html Msg
viewInput name val placeholder_ =
    section [ class "form-control", class "-stack" ]
        [ label [ class "form-label", for <| name ] [ strong [] [ text name ] ]
        , input
            [ value val
            , onInput <| OnChangeStringField name
            , class "secret-name"
            , placeholder placeholder_
            , id name
            ]
            []
        ]


{-| viewValueInput : renders value input box
-}
viewValueInput : String -> String -> Html Msg
viewValueInput val placeholder_ =
    section [ class "form-control", class "-stack" ]
        [ label [ class "form-label", for <| "secret-value" ] [ strong [] [ text "Value" ] ]
        , textarea
            [ value val
            , onInput <| OnChangeStringField "value"
            , class "secret-value"
            , class "form-control"
            , rows 2
            , wrap "soft"
            , placeholder placeholder_
            , id "secret-value"
            ]
            []
        ]


{-| viewEventsSelect : renders events input selection
-}
viewEventsSelect : SecretForm -> Html Msg
viewEventsSelect secretUpdate =
    section []
        [ div [ for "events-select" ]
            [ strong [] [ text "Limit to Events" ]
            , span [ class "field-description" ]
                [ text "( "
                , em [] [ text "at least one event must be selected" ]
                , text " )"
                ]
            , pullRequestWarning
            ]
        , div
            [ class "form-controls"
            , class "-stack"
            ]
            [ checkbox "Push"
                "push"
                (eventEnabled "push" secretUpdate.events)
              <|
                OnChangeEvent "push"
            , checkbox "Pull Request"
                "pull_request"
                (eventEnabled "pull_request" secretUpdate.events)
              <|
                OnChangeEvent "pull_request"
            , checkbox "Tag"
                "tag"
                (eventEnabled "tag" secretUpdate.events)
              <|
                OnChangeEvent "tag"
            , checkbox "Release"
                "release"
                (eventEnabled "release" secretUpdate.events)
              <|
                OnChangeEvent "release"
            , checkbox "Comment"
                "comment"
                (eventEnabled "comment" secretUpdate.events)
              <|
                OnChangeEvent "comment"
            , checkbox "Deployment"
                "deployment"
                (eventEnabled "deployment" secretUpdate.events)
              <|
                OnChangeEvent "deployment"
            ]
        ]


{-| pullRequestWarning : renders disclaimer for pull request exposure
-}
pullRequestWarning : Html Msg
pullRequestWarning =
    p [ class "notice" ]
        [ text "Disclaimer: Native secrets do NOT have the "
        , strong [] [ text "pull_request" ]
        , text " event enabled by default. This is intentional to help mitigate exposure via a pull request against the repo. You can override this behavior, at your own risk, for each secret."
        ]


{-| viewImagesInput : renders images input box and images
-}
viewImagesInput : SecretForm -> String -> Html Msg
viewImagesInput secret imageInput =
    section [ class "image" ]
        [ div [ id "images-select", class "form-control", class "-stack" ]
            [ label [ for "images-select", class "form-label" ]
                [ strong [] [ text "Limit to Docker Images" ]
                , span
                    [ class "field-description" ]
                    [ em [] [ text "(Leave blank to enable this secret for all images)" ]
                    ]
                ]
            , input
                [ placeholder "Image Name"
                , onInput <| OnChangeStringField "imageInput"
                , value imageInput
                ]
                []
            , button
                [ class "button"
                , class "-outline"
                , class "add-image"
                , onClick <| AddImage <| String.toLower imageInput
                , disabled <| String.isEmpty <| String.trim imageInput
                ]
                [ text "Add Image"
                ]
            ]
        , div [ class "images" ] <| viewAddedImages secret.images
        ]


{-| radio : takes current value, field id, title for label, and click action and renders an input radio.
-}
radio : String -> String -> Field -> msg -> Html msg
radio value field title msg =
    div [ class "form-control", Util.testAttribute <| "secret-radio-" ++ field ]
        [ input
            [ type_ "radio"
            , id <| "radio-" ++ field
            , checked (value == field)
            , onClick msg
            ]
            []
        , label [ class "form-label", for <| "radio-" ++ field ] [ strong [] [ text title ] ]
        ]


{-| allowCommandCheckbox : renders checkbox inputs for selecting allowcommand
-}
viewAllowCommandCheckbox : SecretForm -> Html Msg
viewAllowCommandCheckbox secretUpdate =
    section [ Util.testAttribute "" ]
        [ div [ class "form-control" ]
            [ strong []
                [ text "Allow Commands"
                , span [ class "field-description" ]
                    [ text "( "
                    , em [] [ text "\"No\" will disable this secret in " ]
                    , code [] [ text "commands" ]
                    , text " )"
                    ]
                ]
            ]
        , div
            [ class "form-controls", class "-stack" ]
            [ radio (Util.boolToYesNo secretUpdate.allowCommand) "yes" "Yes" <| OnChangeAllowCommand "yes"
            , radio (Util.boolToYesNo secretUpdate.allowCommand) "no" "No" <| OnChangeAllowCommand "no"
            ]
        ]


viewSubmitButtons : Model msg -> Html Msg
viewSubmitButtons secretsModel =
    div [ class "buttons" ]
        [ viewUpdateButton secretsModel
        , viewCancelButton secretsModel
        , viewDeleteButton secretsModel
        ]


viewUpdateButton : Model msg -> Html Msg
viewUpdateButton secretsModel =
    button
        [ class "button"
        , onClick <| Pages.Secrets.Model.UpdateSecret secretsModel.engine
        ]
        [ text "Update" ]


viewDeleteButton : Model msg -> Html Msg
viewDeleteButton secretsModel =
    let
        secretDeleteConfirm =
            "-secret-delete-confirm"

        secretDeleteLoading =
            "-loading"

        ( deleteButtonText, deleteButtonClass ) =
            case secretsModel.deleteState of
                NotAsked_ ->
                    ( "Remove", "" )

                Confirm ->
                    ( "Confirm", secretDeleteConfirm )

                Deleting ->
                    ( "Removing", secretDeleteLoading )
    in
    button
        [ class "button"
        , class "-outline"
        , class deleteButtonClass
        , Util.testAttribute "secret-delete-button"
        , onClick <| Pages.Secrets.Model.DeleteSecret secretsModel.engine
        ]
        [ text deleteButtonText ]


viewCancelButton : Model msg -> Html Msg
viewCancelButton secretsModel =
    case secretsModel.deleteState of
        NotAsked_ ->
            text ""

        Confirm ->
            button
                [ class "button"
                , class "-outline"
                , Util.testAttribute "secret-cancel-button"
                , onClick <| Pages.Secrets.Model.CancelDeleteSecret
                ]
                [ text "Cancel" ]

        Deleting ->
            text ""



-- HELPERS


{-| eventEnabled : takes event and returns if it is enabled
-}
eventEnabled : String -> List String -> Bool
eventEnabled event =
    List.member event


secretsDocsURL : String
secretsDocsURL =
    "https://go-vela.github.io/docs/tour/secrets/"
