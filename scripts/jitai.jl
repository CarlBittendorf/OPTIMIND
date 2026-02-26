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

        transform(:DateTime => ByRow(Date) => :Date)
    end

    df_emergency = @chain df begin
        subset(:Variable => ByRow(isequal("EmergencyInteraction")))
        transform(
            :DateTime => ByRow(Date) => :Date,
            :DateTime => ByRow(x -> Dates.format(Time(x), dateformat"HH:MM")) => :Time,
            :Value => :Counter
        )
        select(:Participant, :Date, :Time, :Counter)
    end

    df_conversation = @chain df begin
        subset(:Variable => ByRow(isequal("Conversation")))
        transform(:Value => ByRow(x -> isequal(x, 1) ? "Yes" : "No") => :Conversation)
        select(:Participant, :Date, :Conversation)
    end

    df_jitai = @chain begin
        leftjoin(df_emergency, df_conversation; on = [:Participant, :Date])

        select(:Participant, :Date, :Time, :Counter, :Conversation)
    end

    if nrow(df_jitai) > 0
        send_jitai_email(EMAIL_CREDENTIALS, EMAIL_FEEDBACK_RECEIVERS, df_jitai)
    end
end

run_script(script, EMAIL_CREDENTIALS, EMAIL_ERROR_RECEIVER)