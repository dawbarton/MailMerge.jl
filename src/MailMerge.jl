module MailMerge

using CSV: CSV
using DataFrames: DataFrames, DataFrame, eachrow, nrow
using Mustache: Mustache
using CommonMark: CommonMark, RawContentRule
using JSON3: JSON3

export mailmerge

const DRAFTS_PATH = joinpath(@__DIR__, "..", "Drafts")

function mailmerge(template_filename)
    (basename, _) = splitext(template_filename)
    return mailmerge(template_filename, basename * ".csv")
end

function mailmerge(template_filename, recipients_filename; kwargs...)
    (name, ext) = splitext(template_filename)
    ext = lowercase(ext)
    if (ext == ".md") || (ext == ".markdown")
        markdown = true
    else
        markdown = false
    end
    if !isfile(template_filename)
        error("Template file not found: $template_filename")
    end
    if !isfile(recipients_filename)
        error("Recipients file not found: $recipients_filename")
    end
    template = Mustache.parse(read(template_filename, String))
    recipients = CSV.read(recipients_filename, DataFrame)
    if markdown
        merge_markdown(basename(name), template, recipients; kwargs...)
    else
        merge_raw(basename(name), template, recipients; kwargs...)
    end
    return nothing
end

function merge_markdown(basename, template, recipients; kwargs...)
    n = length("$(nrow(recipients))")
    p = CommonMark.Parser()
    CommonMark.enable!(p, RawContentRule())
    for (i, row) in enumerate(eachrow(recipients))
        text = CommonMark.html(p(Mustache.render(template, row)))
        write_email(joinpath(DRAFTS_PATH, "$(basename)-$(lpad(string(i), n, "0"))"), row, text; kwargs...)
    end
    return nothing
end

function merge_raw(basename, template, recipients; kwargs...)
    n = length("$(nrow(recipients))")
    for (i, row) in enumerate(eachrow(recipients))
        text = Mustache.render(template, row)
        write_email(joinpath(DRAFTS_PATH, "$(basename)-$(lpad(string(i), n, "0"))"), row, text; kwargs...)
    end
    return nothing
end

function write_email(filename, headers, body; verbose = true, preview = false)
    cc = hasproperty(headers, "cc") ? headers.cc : ""
    bcc = hasproperty(headers, "bcc") ? headers.bcc : ""
    email = Dict("subject" => headers.subject, "to" => headers.to, "cc" => cc, "bcc" => bcc, "body" => body)
    if preview
        open(filename * ".html", "w") do io
            println(io, "<html><body>")
            println(io, "<p><strong>Subject:</strong> $(email["subject"])<br><strong>To:</strong> $(email["to"])<br><strong>Cc:</strong> $(email["cc"])<br><strong>Bcc:</strong> $(email["bcc"])</p>")
            println(io, email["body"])
            println(io, "</body></html>")
        end
    else
        open(filename * ".json", "w") do io
            JSON3.pretty(io, email)
        end
    end
    if verbose
        @info "Wrote $(filename)"
    end
    return nothing
end

end
