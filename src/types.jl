
struct EmailCredentials
    server::String
    login::String
    password::String
    sender::String
end

struct Variable
    name::String
    uuid::String
    type::DataType
end