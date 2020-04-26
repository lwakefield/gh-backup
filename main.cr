require "base64"
require "dir"
require "http/client"
require "json"
require "log"
require "uuid"

Log.setup_from_env

Log.info { "Configuring rclone" }

`rclone config create ghbackup s3 \
    access_key_id #{ENV["S3_ACCESS_KEY_ID"]} \
    secret_access_key #{ENV["S3_SECRET_ACCESS_KEY"]} \
    endpoint #{ENV["S3_ENDPOINT"]}
`
at_exit do
    `rclone config delete ghbackup`
end

params = HTTP::Params.encode({"affiliation" => "owner,collaborator,organization_member" })

next_page_url = "https://api.github.com/user/repos?" + params

until next_page_url.nil?
    Log.info { "Fetching \"#{next_page_url}\"" }
    params = HTTP::Params.encode({"affiliation" => "owner,collaborator,organization_member" })
    headers = HTTP::Headers{"Authorization" => "Basic #{ Base64.strict_encode(ENV["GH_USERNAME"] + ":" + ENV["GH_TOKEN"]) }"}
    response = HTTP::Client.get next_page_url, headers
    links = response.headers["Link"]
        .split(",")
        .map(&.strip.split(';').map(&.strip))
        .map do |pair|
            left, right = pair[0], pair[1]
            url =  left.strip("<>")
            type = right.sub(/rel="(.+)"/, "\\1")
            { type, url }
        end

    body = JSON.parse response.body


    body.as_a.each do |repo|
        dir = Dir.tempdir + "/" + UUID.random.to_s

        Log.info { "Cloning \"#{repo["clone_url"]}\" to \"#{dir}\"" }
        uri = URI.parse repo["clone_url"].to_s
        uri.user = ENV["GH_USERNAME"]
        uri.password = ENV["GH_TOKEN"]
        `git clone "#{uri.to_s}" #{dir}`

        Log.info { "Archiving \"#{dir}\"" }
        archive = "#{dir}/#{Time.local.to_rfc3339}.tar.gz"
        `tar -czf #{archive} -C #{dir} .`

        Log.info { "Uploading archive" }
        `rclone copy #{archive} ghbackup:/#{ENV["S3_BUCKET"]}/ghbackups/#{repo["full_name"]}`

        Log.info { "Cleaning up" }
        `rm -rf #{dir}`
    end

    if next_page = links.find { |k,v| k == "next" }
        next_page_url = next_page[1]
    else
        next_page_url = nil
    end
end
