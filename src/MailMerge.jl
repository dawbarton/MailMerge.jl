module MailMerge

using CSV: CSV
using DataFrames: DataFrames, DataFrame, eachrow
using Mustache: Mustache
using CommonMark: CommonMark


function load_template(template_filename)
    template = read(template_filename, String)
    return Mustache.parse(template)
end

function load_recipients(recipients_filename)
    return CSV.read(recipients_filename, DataFrame)
end

function merge(basename; markdown = true)
    template = load_template(template_filename)
    if markdown
        parser = CommonMark.Parser()
        CommonMark.enable!(parser, CommonMark.RawContentRule())
        template = CommonMark.parse!(template)
    end

    recipients = load_recipients(recipients_filename)
    for row in eachrow(recipients)
        merged_row = render(template, row)
        push!(merged, merged_row)
    end
    return merged
end

end

# rows = CSV.read("tutors.csv", DataFrame)
# for (i, row) in enumerate(eachrow(rows))
#     text = Mustache.render(tokens, row)
#     tutoremail = match(r"<(.*)>", row.Email).captures[1]
#     email = Dict("subject" => "Tutees from the International Foundation Programme", "to" => tutoremail, "body" => text)
#     open("2024-03-14-ifp-focusgroups-tutors-$(i).json", "w") do io
#         JSON3.pretty(io, email)
#     end
# end
