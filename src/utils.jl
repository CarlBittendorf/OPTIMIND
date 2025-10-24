
chunk(N, size) = [((i - 1) * size + 1):min(i * size, N) for i in 1:ceil(Int, N / size)]

format_cutoff_time(x) = string(x) * "Z"

function format_days(x)
    min, max = extrema(x)

    if min == max
        return string(max)
    else
        return join([min, max], "-")
    end
end

format_compliance(x) = string(round(x * 100; digits = 2)) * "%"

function parse_value(T, x)
    if isnothing(x)
        return missing
    elseif typeof(x) == T
        return x
    else
        return parse(T, x)
    end
end

parse_created_at(x) = DateTime(x[1:(end - 4)])

enumerate_days(x) = Dates.value.(Date.(x) .- Date(minimum(x))) .+ 1