include("../src/main.jl")

function script()
    # bearer token, which is valid for five minutes
    token = download_interaction_designer_token(USERNAME, PASSWORD, CLIENT_SECRET)

    # all current participant uuids
    participantuuids = download_interaction_designer_participants(token, STUDY_UUID)

    # calculate cutoff based on day of week
    day = dayname(dayofweek(now()))
    cutoff = day == "Monday" ? Date(now() - Day(3)) : Date(now() - Day(2))

    df = @chain begin
        download_interaction_designer_variable_values(
            token,
            STUDY_UUID,
            participantuuids,
            COMPLIANCE_VARIABLES;
            cutofftime=floor(now(), Day),
            hoursinpast=36 * 24
        )

        unstack([:Participant, :DateTime], :Variable, :Value)

        transform(:DateTime => ByRow(Date) => :Date)

        groupby([:Participant, :Date])
        combine(
            :OverallDayCount => (x -> coalesce(x...)) => :Day,
            [:CalibrationPhaseEMATriggered, :CalibrationPhaseEMAFinished] .=>
                (x -> count(!ismissing, x)) .=> [:Triggered, :Finished]
        )

        subset(
            :Date => ByRow(x -> x >= cutoff),
            :Day => ByRow(x -> (x <= 3) || (7 < x <= 35))
        )

        sort([:Participant, :Date])

        transform(:Day => ByRow(x -> (x <= 3) ? 8 : 4) => :Target)

        groupby(:Participant)
        combine(
            :Day => format_days => :Days,
            [:Target, :Finished] => ((targets, finishes) -> sum(finishes) / sum(targets)) => :Total,
            [:Target, :Finished] .=> sum;
            renamecols=false
        )

        transform([:Target, :Finished] => ByRow((targets, finishes) -> finishes / targets) => :Compliance)
        sort([:Compliance, :Total])

        transform([:Compliance, :Total] .=> ByRow(format_compliance); renamecols=false)
        select(:Participant, :Days, :Target, :Finished, :Compliance, :Total)
    end

    if nrow(df) > 0
        send_compliance_email(EMAIL_CREDENTIALS, EMAIL_FEEDBACK_RECEIVERS, df)
    end
end

run_script(script, EMAIL_CREDENTIALS, EMAIL_ERROR_RECEIVER)