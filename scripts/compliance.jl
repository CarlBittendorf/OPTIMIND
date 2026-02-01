include("../src/main.jl")

function script()
    # bearer token, which is valid for five minutes
    token = download_interaction_designer_token(USERNAME, PASSWORD, CLIENT_SECRET)

    # all current participant uuids
    participantuuids = download_interaction_designer_participants(token, STUDY_UUID)

    # calculate cutoff based on day of week
    day = dayname(dayofweek(now()))
    cutoff = day == "Monday" ? Date(now() - Day(3)) : Date(now() - Day(2))

    variables = getproperty.(COMPLIANCE_VARIABLES, :name)

    df = @chain begin
        download_interaction_designer_variable_values(
            token,
            STUDY_UUID,
            participantuuids,
            COMPLIANCE_VARIABLES;
            cutofftime = floor(now(), Day),
            hoursinpast = 32 * 24
        )

        transform(:DateTime => ByRow(Date) => :Date)

        # use only participants who are still active
        groupby(:Participant)
        subset(:Date => (x -> maximum(x; init = cutoff) == Date(now()) - Day(1)))

        # count the appearances of each variable
        groupby([:Participant, :Date])
        combine((:Variable => (x -> count(isequal(name), x)) => name for name in variables)...)

        sort([:Participant, :Date])

        groupby(:Participant)
        transform(:Date => enumerate_days => :Day)

        transform(
            :Day => ByRow(x -> x <= 3 ? 8 : 4) => :Target,
            Cols(endswith("Triggered")) => ByRow(+) => :Triggered,
            Cols(endswith("Finished")) => ByRow(+) => :Finished
        )

        groupby(:Participant)
        combine(
            [:Day, :Date] => ((days, dates) -> format_days(days[dates .>= cutoff])) => :Days,
            [:Target, :Finished] => ((targets, finishes) -> sum(finishes) / sum(targets)) => :Total,
            [:Target, :Date] => ((targets, dates) -> sum(targets[dates .>= cutoff])) => :Target,
            [:Finished, :Date] => ((finishes, dates) -> sum(finishes[dates .>= cutoff])) => :Finished
        )

        transform([:Target, :Finished] => ByRow((targets, finishes) -> finishes / targets) => :Compliance)
        sort([:Compliance, :Total])

        transform([:Compliance, :Total] .=> ByRow(format_compliance); renamecols = false)
        select(:Participant, :Days, :Target, :Finished, :Compliance, :Total)
    end

    if nrow(df) > 0
        send_compliance_email(EMAIL_CREDENTIALS, EMAIL_FEEDBACK_RECEIVERS, df)
    end
end

run_script(script, EMAIL_CREDENTIALS, EMAIL_ERROR_RECEIVER)