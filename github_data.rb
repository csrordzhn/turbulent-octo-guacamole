require 'httparty'
require 'json'
require 'vcr'
require 'webmock'

VCR.configure do |config|
  config.cassette_library_dir = "fixtures/vcr_cassettes"
  config.hook_into :webmock # or :fakeweb
end


# get user repos https://api.github.com/users/csrordzhn/repos
def repo_list_to_tsv
  VCR.use_cassette("csrordzhn_repos") do
    github_api_url = 'https://api.github.com'
    request_url = "#{github_api_url}/users/csrordzhn/repos"
    response = HTTParty.get(request_url)
    repos = JSON.parse(response.body)
    headers = repos[0]
    headers.delete('owner')
    File.write('repo_data.tsv', headers.keys.join("\t") + "\n", mode: 'a')
      repos.each do |repo|
        #puts "The repo at #{repo['full_name']} is a #{repo['language']} project with a size of #{repo['size']}Kb."
        repo.delete('owner')
        File.write('repo_data.tsv', repo.values.join("\t") + "\n", mode: 'a')
      end
  end
end

repo_list_to_tsv
