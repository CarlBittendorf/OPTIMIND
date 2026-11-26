include("../src/main.jl")

function script()
    # bearer token, which is valid for five minutes
    token = download_interaction_designer_token(USERNAME, PASSWORD, CLIENT_SECRET)

    # all current participant uuids
    participantuuids = download_interaction_designer_participants(token, STUDY_UUID)

    yesterday = Date(now() - Day(1))

    df = @chain begin
        download_interaction_designer_variable_values(
            token,
            STUDY_UUID,
            participantuuids,
            STARTUP_VARIABLES;
            cutofftime=floor(now(), Day),
            hoursinpast=36 * 24
        )

        transform(:DateTime => ByRow(Date) => :Date)

        unstack([:Participant, :Date], :Variable, :Value)

        "IsStartUpSessionFinished" in names(_) ? _ :
        transform(_, All() => ByRow((x...) -> missing) => :IsStartUpSessionFinished)

        "InterventionPhaseDayCount" in names(_) ? _ :
        transform(_, All() => ByRow((x...) -> missing) => :InterventionPhaseDayCount)

        sort([:Participant, :Date])

        groupby(:Participant)
        transform(
            :IsStartUpSessionFinished => fill_down;
            renamecols=false
        )

        transform(
            :IsStartUpSessionFinished => ByRow(x -> ismissing(x) ? false : x);
            renamecols=false
        )
        subset(
            :Date => ByRow(isequal(yesterday)),
            :OverallDayCount => ByRow(x -> x >= 7),
            :IsStartUpSessionFinished => ByRow(!),
            :InterventionPhaseDayCount => ByRow(ismissing)
        )

        select(:Participant, :OverallDayCount, :IsStartUpSessionFinished)
    end

    if nrow(df) > 0
        send_startup_email(EMAIL_CREDENTIALS, EMAIL_FEEDBACK_RECEIVERS, df)
    end
end

run_script(script, EMAIL_CREDENTIALS, EMAIL_ERROR_RECEIVER)