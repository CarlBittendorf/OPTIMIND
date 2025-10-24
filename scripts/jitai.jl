include("../src/main.jl")

function script()
    hoursinpast = parse(Int, only(ARGS))

    # bearer token, which is valid for five minutes
    token = download_interaction_designer_token(USERNAME, PASSWORD, CLIENT_SECRET)

    # all current participant uuids
    participantuuids = download_interaction_designer_participants(token, STUDY_UUID)

    df = @chain begin
        download_interaction_designer_variable_values(
            token,
            STUDY_UUID,
            participantuuids,
            JITAI_VARIABLES;
            cutofftime = floor(now(), Hour),
            hoursinpast
        )

        subset(:Variable => ByRow(isequal("EmergencyInteraction")))
        transform(
            :DateTime => ByRow(Date) => :Date,
            :DateTime => ByRow(x -> Dates.format(Time(x), dateformat"HH:MM")) => :Time,
            :Value => :Counter
        )
        select(:Participant, :Date, :Time, :Counter)
    end

    if nrow(df) > 0
        send_jitai_email(EMAIL_CREDENTIALS, EMAIL_FEEDBACK_RECEIVERS, df)
    end
end

run_script(script, EMAIL_CREDENTIALS, EMAIL_ERROR_RECEIVER)