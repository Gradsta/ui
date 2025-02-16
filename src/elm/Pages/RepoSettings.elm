{--
Copyright (c) 2022 Target Brands, Inc. All rights reserved.
Use of this source code is governed by the LICENSE file in this repository.
--}


module Pages.RepoSettings exposing
    ( Msgs
    , alert
    , checkbox
    , enableUpdate
    , validAccessUpdate
    , validEventsUpdate
    , validPipelineTypeUpdate
    , view
    )

import Dict exposing (Dict)
import Errors exposing (viewResourceError)
import FeatherIcons
import Html
    exposing
        ( Html
        , a
        , br
        , button
        , div
        , em
        , h2
        , img
        , input
        , label
        , p
        , section
        , small
        , span
        , strong
        , text
        , textarea
        )
import Html.Attributes
    exposing
        ( alt
        , attribute
        , checked
        , class
        , classList
        , disabled
        , for
        , href
        , id
        , readonly
        , rows
        , src
        , type_
        , value
        , wrap
        )
import Html.Events exposing (onCheck, onClick, onInput)
import RemoteData exposing (RemoteData(..), WebData)
import Util
import Vela
    exposing
        ( ChownRepo
        , Copy
        , DisableRepo
        , EnableRepo
        , Enabled
        , Enabling
        , Field
        , RepairRepo
        , Repositories
        , Repository
        , SourceRepositories
        , UpdateRepositoryPayload
        )



-- TYPES


{-| CheckboxUpdate : type that takes Msg for forwarding checkbox input callback to Main.elm
-}
type alias CheckboxUpdate msg =
    String -> String -> String -> (Bool -> msg)


{-| RadioUpdate : type that takes Msg for forwarding radio input callback to Main.elm
-}
type alias RadioUpdate msg =
    String -> String -> String -> (String -> msg)


{-| NumberInputChange : type that takes Msg for forwarding number input callback to Main.elm
-}
type alias NumberInputChange msg =
    String -> String -> String -> Int -> msg


{-| StringInputChange : type that takes Msg for forwarding string input callback to Main.elm
-}
type alias StringInputChange msg =
    String -> msg


{-| Msgs : record containing msgs routeable to Main.elm
-}
type alias Msgs msg =
    { eventsUpdate : CheckboxUpdate msg
    , accessUpdate : RadioUpdate msg
    , limitUpdate : NumberInputChange msg
    , inLimitChange : StringInputChange msg
    , timeoutUpdate : NumberInputChange msg
    , inTimeoutChange : StringInputChange msg
    , counterUpdate : NumberInputChange msg
    , inCounterChange : StringInputChange msg
    , disableRepo : DisableRepo msg
    , enableRepo : EnableRepo msg
    , copy : Copy msg
    , chownRepo : ChownRepo msg
    , repairRepo : RepairRepo msg
    , pipelineTypeUpdate : RadioUpdate msg
    }



-- VIEW


{-| view : takes model, org and repo and renders page for updating repo settings
-}
view : WebData Repository -> Msgs msg -> String -> String -> Int -> Html msg
view repo actions velaAPI velaURL maxLimit =
    let
        ( accessUpdate, pipelineTypeUpdate ) =
            ( actions.accessUpdate, actions.pipelineTypeUpdate )

        ( limitUpdate, inLimitChange ) =
            ( actions.limitUpdate, actions.inLimitChange )

        ( timeoutUpdate, inTimeoutChange ) =
            ( actions.timeoutUpdate, actions.inTimeoutChange )

        ( counterUpdate, inCounterChange ) =
            ( actions.counterUpdate, actions.inCounterChange )

        ( eventsUpdate, disableRepo, enableRepo ) =
            ( actions.eventsUpdate, actions.disableRepo, actions.enableRepo )

        ( chownRepo, repairRepo ) =
            ( actions.chownRepo, actions.repairRepo )
    in
    case repo of
        Success repo_ ->
            div [ class "repo-settings", Util.testAttribute "repo-settings" ]
                [ events repo_ eventsUpdate
                , access repo_ accessUpdate
                , limit maxLimit repo_.inLimit repo_ limitUpdate inLimitChange
                , timeout repo_.inTimeout repo_ timeoutUpdate inTimeoutChange
                , counter repo_.inCounter repo_ counterUpdate inCounterChange
                , badge repo_ velaAPI velaURL actions.copy
                , admin disableRepo enableRepo chownRepo repairRepo repo_
                , pipelineType repo_ pipelineTypeUpdate
                ]

        Loading ->
            div []
                [ Util.largeLoader
                ]

        NotAsked ->
            div []
                [ Util.largeLoader
                ]

        Failure _ ->
            viewResourceError { resourceLabel = "your repo settings", testLabel = "settings" }


{-| access : takes model and repo and renders the settings category for updating repo access
-}
access : Repository -> RadioUpdate msg -> Html msg
access repo msg =
    section [ class "settings", Util.testAttribute "repo-settings-access" ]
        [ h2 [ class "settings-title" ] [ text "Access" ]
        , p [ class "settings-description" ] [ text "Change who can access build information." ]
        , div [ class "form-controls", class "-stack" ]
            [ radio repo.visibility "private" "Private" <| msg repo.org repo.name "visibility" "private"
            , radio repo.visibility "public" "Any" <| msg repo.org repo.name "visibility" "public"
            ]
        ]


{-| pipelineType : takes model and repo and renders the settings category for updating repo pipeline type
-}
pipelineType : Repository -> RadioUpdate msg -> Html msg
pipelineType repo msg =
    section [ class "settings", Util.testAttribute "repo-settings-pipeline-type" ]
        [ h2 [ class "settings-title" ] [ text "Pipeline Type" ]
        , p [ class "settings-description" ] [ text "Change how the compiler treats the base vela config." ]
        , div [ class "form-controls", class "-stack" ]
            [ radio repo.pipeline_type "yaml" "YAML" <| msg repo.org repo.name "pipeline_type" "yaml"
            , radio repo.pipeline_type "go" "Go" <| msg repo.org repo.name "pipeline_type" "go"
            , radio repo.pipeline_type "starlark" "Starlark" <| msg repo.org repo.name "pipeline_type" "starlark"
            ]
        ]


{-| badge : takes repo and renders a section for getting your build status badge
-}
badge : Repository -> String -> String -> Copy msg -> Html msg
badge repo velaAPI velaURL copyMsg =
    let
        badgeURL : String
        badgeURL =
            String.join "/" [ velaAPI, "badge", repo.org, repo.name, "status.svg" ]

        baseURL : String
        baseURL =
            velaURL
                |> String.split "/"
                |> List.take 3
                |> String.join "/"

        buildURL : String
        buildURL =
            String.join "/" [ baseURL, repo.org, repo.name ]

        mdCode : String
        mdCode =
            "[![Build Status](" ++ badgeURL ++ ")](" ++ buildURL ++ ")"
    in
    section [ class "settings", Util.testAttribute "repo-settings-badge" ]
        [ h2 [ class "settings-title" ] [ text "Status Badge" ]
        , p [ class "settings-description" ]
            [ text "Show off your build status."
            , br [] []
            , em [] [ text "Uses the default branch on your repository." ]
            ]
        , div []
            [ p [ class "build-badge" ]
                [ img [ alt "build status badge", src badgeURL ] [] ]
            , text "Markdown"
            , div [ class "form-controls", class "-no-x-pad" ]
                [ textarea
                    [ class "form-control"
                    , class "copy-display"
                    , class "-is-expanded"
                    , rows 2
                    , readonly True
                    , wrap "soft"
                    ]
                    [ text mdCode ]
                , button
                    [ class "copy-button"
                    , class "button"
                    , class "-icon"
                    , class "-white"
                    , attribute "data-clipboard-text" mdCode
                    , attribute "aria-label" "copy status badge markdown code"
                    , Util.testAttribute "copy-md"
                    , onClick <| copyMsg mdCode
                    ]
                    [ FeatherIcons.copy
                        |> FeatherIcons.withSize 18
                        |> FeatherIcons.toHtml []
                    ]
                ]
            , small []
                [ text "To customize branch, "
                , a [ href "https://go-vela.github.io/docs/usage/badge/" ] [ text "see our Badges documentation" ]
                , text "."
                ]
            ]
        ]


{-| events : takes model and repo and renders the settings category for updating repo webhook events
-}
events : Repository -> CheckboxUpdate msg -> Html msg
events repo msg =
    section [ class "settings", Util.testAttribute "repo-settings-events" ]
        [ h2 [ class "settings-title" ] [ text "Webhook Events" ]
        , p [ class "settings-description" ]
            [ text "Control which events on Git will trigger Vela pipelines."
            , br [] []
            , em [] [ text "Active repositories must have at least one event enabled." ]
            ]
        , div [ class "form-controls", class "-stack" ]
            [ checkbox "Push"
                "allow_push"
                repo.allow_push
              <|
                msg repo.org repo.name "allow_push"
            , checkbox "Pull Request"
                "allow_pull"
                repo.allow_pull
              <|
                msg repo.org repo.name "allow_pull"
            , checkbox "Tag"
                "allow_tag"
                repo.allow_tag
              <|
                msg repo.org repo.name "allow_tag"
            , checkbox "Release"
                "allow_release"
                repo.allow_release
              <|
                msg repo.org repo.name "allow_release"
            , checkbox "Comment"
                "allow_comment"
                repo.allow_comment
              <|
                msg repo.org repo.name "allow_comment"
            , checkbox "Deploy"
                "allow_deploy"
                repo.allow_deploy
              <|
                msg repo.org repo.name "allow_deploy"
            ]
        ]


{-| limit : takes model and repo and renders the settings category for updating repo build limit
-}
limit : Int -> Maybe Int -> Repository -> NumberInputChange msg -> (String -> msg) -> Html msg
limit maxLimit inLimit repo clickMsg inputMsg =
    section [ class "settings", Util.testAttribute "repo-settings-limit" ]
        [ h2 [ class "settings-title" ] [ text "Build Limit" ]
        , p [ class "settings-description" ] [ text "Concurrent builds (pending or running) that exceed this limit will be stopped." ]
        , div [ class "form-controls" ]
            [ limitInput repo maxLimit inLimit inputMsg
            , updateLimit maxLimit inLimit repo repo.limit <| clickMsg repo.org repo.name "build_limit" <| Maybe.withDefault 0 inLimit
            ]
        , limitWarning maxLimit inLimit
        ]


{-| timeout : takes model and repo and renders the settings category for updating repo build timeout
-}
timeout : Maybe Int -> Repository -> NumberInputChange msg -> (String -> msg) -> Html msg
timeout inTimeout repo clickMsg inputMsg =
    section [ class "settings", Util.testAttribute "repo-settings-timeout" ]
        [ h2 [ class "settings-title" ] [ text "Build Timeout" ]
        , p [ class "settings-description" ] [ text "Builds that reach this timeout setting will be stopped." ]
        , div [ class "form-controls" ]
            [ timeoutInput repo inTimeout inputMsg
            , updateTimeout inTimeout repo.timeout <| clickMsg repo.org repo.name "timeout" <| Maybe.withDefault 0 inTimeout
            ]
        , timeoutWarning inTimeout
        ]


{-| counter : takes model and repo and renders the settings category for updating repo build counter
-}
counter : Maybe Int -> Repository -> NumberInputChange msg -> (String -> msg) -> Html msg
counter inCounter repo clickMsg inputMsg =
    section [ class "settings", Util.testAttribute "repo-settings-counter" ]
        [ h2 [ class "settings-title" ] [ text "Build Counter" ]
        , p [ class "settings-description" ] [ text "Builds increment based off this number." ]
        , div [ class "form-controls" ]
            [ counterInput repo inCounter inputMsg
            , updateCounter inCounter repo repo.counter <| clickMsg repo.org repo.name "counter" <| Maybe.withDefault 0 inCounter
            ]
        , counterWarning inCounter
        ]


{-| checkbox : takes field name, id, state and click action, and renders an input checkbox.
-}
checkbox : String -> Field -> Bool -> (Bool -> msg) -> Html msg
checkbox name field state msg =
    div [ class "form-control", Util.testAttribute <| "repo-checkbox-" ++ field ]
        [ input
            [ type_ "checkbox"
            , id <| "checkbox-" ++ field
            , checked state
            , onCheck msg
            ]
            []
        , label [ class "form-label", for <| "checkbox-" ++ field ] [ strong [] [ text name ] ]
        ]


{-| radio : takes current value, field id, title for label, and click action and renders an input radio.
-}
radio : String -> String -> Field -> msg -> Html msg
radio value field title msg =
    div [ class "form-control", Util.testAttribute <| "repo-radio-" ++ field ]
        [ input
            [ type_ "radio"
            , id <| "radio-" ++ field
            , checked (value == field)
            , onClick msg
            ]
            []
        , label [ class "form-label", for <| "radio-" ++ field ] [ strong [] [ text title ], updateAccessTip field ]
        ]


{-| limitInput : takes repo, user input, and button action and renders the text input for updating build limit.
-}
limitInput : Repository -> Int -> Maybe Int -> (String -> msg) -> Html msg
limitInput repo maxLimit inLimit inputMsg =
    div [ class "form-control", Util.testAttribute "repo-limit" ]
        [ input
            [ id <| "repo-limit"
            , onInput inputMsg
            , type_ "number"
            , Html.Attributes.min "1"
            , Html.Attributes.max <| String.fromInt maxLimit
            , value <| String.fromInt <| Maybe.withDefault repo.limit inLimit
            ]
            []
        , label [ class "form-label", for "repo-limit" ] [ text "limit" ]
        ]


{-| updateLimit : takes maybe int of user entered limit and current repo limit and renders the button to submit the update.
-}
updateLimit : Int -> Maybe Int -> Repository -> Int -> msg -> Html msg
updateLimit maxLimit inLimit repo repoLimit msg =
    case inLimit of
        Just _ ->
            button
                [ classList
                    [ ( "button", True )
                    , ( "-outline", True )
                    ]
                , onClick msg
                , disabled <| not <| validLimit maxLimit inLimit repo <| Just repoLimit
                ]
                [ text "update" ]

        Nothing ->
            text ""


{-| limitWarning : takes maybe string of user entered limit and renders a disclaimer on updating the build limit.
-}
limitWarning : Int -> Maybe Int -> Html msg
limitWarning maxLimit inLimit =
    case inLimit of
        Just _ ->
            p [ class "notice" ]
                [ text "Disclaimer: it is highly recommended to optimize your pipeline before increasing this value. Limits must also lie between 1 and "
                , text <| String.fromInt maxLimit
                , text "."
                ]

        Nothing ->
            text ""


{-| timeoutInput : takes repo, user input, and button action and renders the text input for updating build timeout.
-}
timeoutInput : Repository -> Maybe Int -> (String -> msg) -> Html msg
timeoutInput repo inTimeout inputMsg =
    div [ class "form-control", Util.testAttribute "repo-timeout" ]
        [ input
            [ id <| "repo-timeout"
            , onInput inputMsg
            , type_ "number"
            , Html.Attributes.min "1"
            , Html.Attributes.max "90"
            , value <| String.fromInt <| Maybe.withDefault repo.timeout inTimeout
            ]
            []
        , label [ class "form-label", for "repo-timeout" ] [ text "minutes" ]
        ]


{-| updateTimeout : takes maybe int of user entered timeout and current repo timeout and renders the button to submit the update.
-}
updateTimeout : Maybe Int -> Int -> msg -> Html msg
updateTimeout inTimeout repoTimeout msg =
    case inTimeout of
        Just _ ->
            button
                [ classList
                    [ ( "button", True )
                    , ( "-outline", True )
                    ]
                , onClick msg
                , disabled <| not <| validTimeout inTimeout <| Just repoTimeout
                ]
                [ text "update" ]

        Nothing ->
            text ""


{-| timeoutWarning : takes maybe string of user entered timeout and renders a disclaimer on updating the build timeout.
-}
timeoutWarning : Maybe Int -> Html msg
timeoutWarning inTimeout =
    case inTimeout of
        Just _ ->
            p [ class "notice" ]
                [ text "Disclaimer: if you are experiencing build timeouts, it is highly recommended to optimize your pipeline before increasing this value. Timeouts must also lie between 1 and 90 minutes."
                ]

        Nothing ->
            text ""


{-| counterInput : takes repo, user input, and button action and renders the text input for updating build counter.
-}
counterInput : Repository -> Maybe Int -> (String -> msg) -> Html msg
counterInput repo inCounter inputMsg =
    div [ class "form-control", Util.testAttribute "repo-counter" ]
        [ input
            [ id <| "repo-counter"
            , onInput inputMsg
            , type_ "number"
            , Html.Attributes.min <| String.fromInt <| repo.counter
            , value <| String.fromInt <| Maybe.withDefault repo.counter inCounter
            ]
            []
        , label [ class "form-label", for "repo-counter" ] [ text "count" ]
        ]


{-| updateCounter : takes maybe int of user entered counter and current repo counter and renders the button to submit the update.
-}
updateCounter : Maybe Int -> Repository -> Int -> msg -> Html msg
updateCounter inCounter repo repoCounter msg =
    case inCounter of
        Just _ ->
            button
                [ classList
                    [ ( "button", True )
                    , ( "-outline", True )
                    ]
                , onClick msg
                , disabled <| not <| validCounter inCounter repo <| Just repoCounter
                ]
                [ text "update" ]

        Nothing ->
            text ""


{-| counterWarning : takes maybe string of user entered counter and renders a disclaimer on updating the build counter.
-}
counterWarning : Maybe Int -> Html msg
counterWarning inCounter =
    case inCounter of
        Just _ ->
            p [ class "notice" ]
                [ text "Disclaimer: Incrementing the build counter can not be reversed. Updating this value will start future builds from this value as the build number"
                ]

        Nothing ->
            text ""


{-| admin : takes admin actions and repo and returns view of the repo admin actions.
-}
admin : DisableRepo msg -> EnableRepo msg -> ChownRepo msg -> RepairRepo msg -> Repository -> Html msg
admin disableRepoMsg enableRepoMsg chownRepoMsg repairRepoMsg repo =
    let
        enabledDetails =
            if disableable repo.enabling then
                ( "Disable Repository", "This will delete the Vela webhook from this repository." )

            else
                ( "Enable Repository", "This will create the Vela webhook for this repository." )
    in
    section [ class "settings", Util.testAttribute "repo-settings-admin" ]
        [ h2 [ class "settings-title" ] [ text "Admin" ]
        , p [ class "settings-description" ] [ text "These actions require admin privileges." ]
        , div [ class "admin-action-container" ]
            [ div [ class "admin-action-description" ]
                [ text "Chown Repository"
                , small []
                    [ em [] [ text "This will make you the owner of the webhook for this repository." ] ]
                ]
            , button
                [ class "button"
                , class "-outline"
                , attribute "aria-label" <| "become owner of the webhook for " ++ repo.full_name
                , Util.testAttribute "repo-chown"
                , onClick <| chownRepoMsg repo
                ]
                [ text "Chown" ]
            ]
        , div [ class "admin-action-container" ]
            [ div [ class "admin-action-description" ]
                [ text "Repair Repository"
                , small []
                    [ em [] [ text "This will repair the webhook for this repository." ] ]
                ]
            , button
                [ class "button"
                , class "-outline"
                , attribute "aria-label" <| "repair the webhook for " ++ repo.full_name
                , Util.testAttribute "repo-repair"
                , onClick <| repairRepoMsg repo
                ]
                [ text "Repair" ]
            ]
        , div [ class "admin-action-container" ]
            [ div [ class "admin-action-description" ]
                [ text <| Tuple.first enabledDetails
                , small [] [ em [] [ text <| Tuple.second enabledDetails ] ]
                ]
            , enabledButton disableRepoMsg enableRepoMsg repo
            ]
        ]


{-| enabledButton : takes enable actions and repo and returns view of the repo enable button.
-}
enabledButton : DisableRepo msg -> EnableRepo msg -> Repository -> Html msg
enabledButton disableRepoMsg enableRepoMsg repo =
    let
        baseClasses =
            classList [ ( "button", True ), ( "-outline", True ) ]

        inProgressClasses =
            classList [ ( "button", True ), ( "-outline", True ), ( "-loading", True ) ]

        baseTestAttribute =
            Util.testAttribute "repo-disable"
    in
    case repo.enabling of
        Vela.NotAsked_ ->
            button
                [ baseClasses
                , baseTestAttribute
                , disabled True
                , onClick <| disableRepoMsg repo
                ]
                [ text "Error" ]

        Vela.Enabled ->
            button
                [ baseClasses
                , baseTestAttribute
                , onClick <| disableRepoMsg repo
                ]
                [ text "Disable" ]

        Vela.Disabled ->
            button
                [ baseClasses
                , Util.testAttribute "repo-enable"
                , onClick <| enableRepoMsg repo
                ]
                [ text "Enable" ]

        Vela.ConfirmDisable ->
            button
                [ baseClasses
                , baseTestAttribute
                , class "repo-disable-confirm"
                , onClick <| disableRepoMsg repo
                ]
                [ text "Really Disable?" ]

        Vela.Disabling ->
            button
                [ inProgressClasses
                , class "button"
                , class "-outline"
                , class "-loading"
                , Util.testAttribute "repo-disabling"
                ]
                [ text "Disabling"
                , span [ class "loading-ellipsis" ] []
                ]

        Vela.Enabling ->
            div
                [ inProgressClasses
                , class "button"
                , class "-outline"
                , class "-loading"
                , Util.testAttribute "repo-enabling"
                ]
                [ text "Enabling"
                , span [ class "loading-ellipsis" ] []
                ]



-- HELPERS


{-| alert : takes update field and updated repo and returns how to alert the user.
-}
alert : Field -> Repository -> String
alert field repo =
    let
        prefix =
            msgPrefix field

        suffix =
            msgSuffix field repo
    in
    String.replace "$" repo.full_name <| prefix ++ suffix


{-| validLimit : takes maybe string of user entered limit and returns whether or not it is a valid update.
-}
validLimit : Int -> Maybe Int -> Repository -> Maybe Int -> Bool
validLimit maxLimit inLimit _ repoLimit =
    case inLimit of
        Just t ->
            if t >= 1 && t <= maxLimit then
                case repoLimit of
                    Just ti ->
                        t /= ti

                    Nothing ->
                        True

            else
                False

        Nothing ->
            True


{-| validTimeout : takes maybe string of user entered timeout and returns whether or not it is a valid update.
-}
validTimeout : Maybe Int -> Maybe Int -> Bool
validTimeout inTimeout repoTimeout =
    case inTimeout of
        Just t ->
            if t >= 1 && t <= 90 then
                case repoTimeout of
                    Just ti ->
                        t /= ti

                    Nothing ->
                        True

            else
                False

        Nothing ->
            True


{-| validCounter : takes maybe string of user entered counter and returns whether or not it is a valid update.
-}
validCounter : Maybe Int -> Repository -> Maybe Int -> Bool
validCounter inCounter repo repoCounter =
    case inCounter of
        Just t ->
            if t >= repo.counter then
                case repoCounter of
                    Just ti ->
                        t /= ti

                    Nothing ->
                        True

            else
                False

        Nothing ->
            True


{-| validAccessUpdate : takes model webdata repo and repo visibility update and determines if an update is necessary
-}
validAccessUpdate : WebData Repository -> UpdateRepositoryPayload -> Bool
validAccessUpdate originalRepo repoUpdate =
    case originalRepo of
        RemoteData.Success repo ->
            case repoUpdate.visibility of
                Just visibility ->
                    repo.visibility /= visibility

                Nothing ->
                    False

        _ ->
            False


{-| validPipelineTypeUpdate : takes model webdata repo and repo pipeline type update and determines if an update is necessary
-}
validPipelineTypeUpdate : WebData Repository -> UpdateRepositoryPayload -> Bool
validPipelineTypeUpdate originalRepo repoUpdate =
    case originalRepo of
        RemoteData.Success repo ->
            case repoUpdate.pipeline_type of
                Just pipeline_type ->
                    repo.pipeline_type /= pipeline_type

                Nothing ->
                    False

        _ ->
            False


{-| validEventsUpdate : takes model webdata repo and repo events update and determines if an update is necessary
-}
validEventsUpdate : WebData Repository -> UpdateRepositoryPayload -> Bool
validEventsUpdate originalRepo repoUpdate =
    case originalRepo of
        RemoteData.Success repo ->
            Maybe.withDefault repo.allow_push repoUpdate.allow_push
                || Maybe.withDefault repo.allow_pull repoUpdate.allow_pull
                || Maybe.withDefault repo.allow_deploy repoUpdate.allow_deploy
                || Maybe.withDefault repo.allow_tag repoUpdate.allow_tag
                || Maybe.withDefault repo.allow_release repoUpdate.allow_release
                || Maybe.withDefault repo.allow_comment repoUpdate.allow_comment

        _ ->
            False


{-| updateAccessTip : takes field and returns the tip to display after the label.
-}
updateAccessTip : Field -> Html msg
updateAccessTip field =
    case field of
        "private" ->
            text " (restricted to those with repository access)"

        "public" ->
            text " (anyone with access to this Vela instance)"

        _ ->
            text ""


{-| msgPrefix : takes update field and returns alert prefix.
-}
msgPrefix : Field -> String
msgPrefix field =
    case field of
        "private" ->
            "$ privacy set to "

        "trusted" ->
            "$ set to "

        "visibility" ->
            "$ visibility set to "

        "allow_pull" ->
            "Pull events for $ "

        "allow_push" ->
            "Push events for $ "

        "allow_deploy" ->
            "Deploy events for $ "

        "allow_tag" ->
            "Tag events for $ "

        "allow_release" ->
            "Release events for $ "

        "allow_comment" ->
            "Comment events for $ "

        "build_limit" ->
            "Build limit for $ "

        "timeout" ->
            "Build timeout for $ "

        "counter" ->
            "Build counter for $ "

        "pipeline_type" ->
            "$ pipeline type set to "

        _ ->
            "Unrecognized update made to $."


{-| msgSuffix : takes update field and returns alert suffix.
-}
msgSuffix : Field -> Repository -> String
msgSuffix field repo =
    case field of
        "private" ->
            toggleText "private" repo.private

        "trusted" ->
            toggleText "trusted" repo.trusted

        "visibility" ->
            repo.visibility ++ "."

        "allow_pull" ->
            toggleText "allow_pull" repo.allow_pull

        "allow_push" ->
            toggleText "allow_push" repo.allow_push

        "allow_deploy" ->
            toggleText "allow_deploy" repo.allow_deploy

        "allow_comment" ->
            toggleText "allow_comment" repo.allow_comment

        "build_limit" ->
            "set to " ++ String.fromInt repo.limit

        "timeout" ->
            "set to " ++ String.fromInt repo.timeout ++ " minute(s)."

        "counter" ->
            "set to " ++ String.fromInt repo.counter

        "pipeline_type" ->
            repo.pipeline_type ++ "."

        _ ->
            ""


{-| toggleText : takes toggle field id and value and returns the text to display when toggling.
-}
toggleText : Field -> Bool -> String
toggleText field value =
    let
        ( enabled, disabled ) =
            case field of
                "private" ->
                    ( "private.", "any." )

                "trusted" ->
                    ( "trusted.", "untrusted." )

                _ ->
                    ( "enabled.", "disabled." )
    in
    if value then
        enabled

    else
        disabled


{-| disableable : takes enabling status and returns if the repo is disableable.
-}
disableable : Enabling -> Bool
disableable status =
    case status of
        Vela.Enabled ->
            True

        Vela.ConfirmDisable ->
            True

        Vela.Disabling ->
            True

        Vela.Enabling ->
            False

        Vela.Disabled ->
            False

        Vela.NotAsked_ ->
            False


{-| enableUpdate : takes repo, enabled status and source repos and sets enabled status of the specified repo
-}
enableUpdate : Repository -> Enabled -> WebData SourceRepositories -> WebData SourceRepositories
enableUpdate repo status sourceRepos =
    case sourceRepos of
        Success repos ->
            case Dict.get repo.org repos of
                Just orgRepos ->
                    RemoteData.succeed <| enableRepoDict repo status repos orgRepos

                _ ->
                    sourceRepos

        _ ->
            sourceRepos


{-| enableRepoDict : update the dictionary containing org source repo lists
-}
enableRepoDict : Repository -> Enabled -> Dict String Repositories -> Repositories -> Dict String Repositories
enableRepoDict repo status repos orgRepos =
    Dict.update repo.org (\_ -> Just <| enableRepoList repo status orgRepos) repos


{-| enableRepoList : list map for updating single repo status by repo name
-}
enableRepoList : Repository -> Enabled -> Repositories -> Repositories
enableRepoList repo status orgRepos =
    List.map
        (\sourceRepo ->
            if sourceRepo.name == repo.name then
                { sourceRepo | enabled = status }

            else
                sourceRepo
        )
        orgRepos
