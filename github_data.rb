require 'httparty'
require 'json'
require 'vcr'
require 'webmock'

# Configuration
VCR.configure do |config|
  config.cassette_library_dir = "fixtures/vcr_cassettes"
  config.hook_into :webmock # or :fakeweb
end

GH_API_URL = 'https://api.github.com'

# Methods
def to_tsv(hash_arr,file_name)
  File.write("#{file_name}.tsv", hash_arr[0].keys.join("\t") + "\n", mode: 'a')
    hash_arr.each do |data|
      File.write("#{file_name}.tsv", data.values.join("\t") + "\n", mode: 'a')
    end
end

def api_data(url)
  cassette_name = url.gsub(':','-').gsub('/','_')
  VCR.use_cassette(cassette_name) do
    response = HTTParty.get(url)
    results = JSON.parse(response.body)
  end
end

# get user repos https://api.github.com/users/csrordzhn/repos
def repo_list(user)
  request_url = "#{GH_API_URL}/users/#{user}/repos"
  results = api_data(request_url)
  results.map do |repo|
    repo.delete('owner')
    repo
  end
end

def user_dates(user)
    request_url = "#{GH_API_URL}/users/#{user}"
    results = api_data(request_url)
    { created_at: results['created_at'], updated_at: results['updated_at'] }
end

def user_commits(user)
  repos = repo_list(user)
  commits_list = []
  repos.each do |repo|
    request_url = "#{GH_API_URL}/repos/#{user}/#{repo['name']}/commits"
    commits = api_data(request_url)
    # commits_list << commits.size
    commits.each do |commit|
    commits_list << {
        sha: commit['sha'],
        repo: repo['name'],
        date_authored: commit['commit']['author']['date'],
        author: commit['commit']['author']['name'],
        author_email: commit['commit']['author']['email'],
        date_committed: commit['commit']['committer']['date'],
        committer: commit['commit']['committer']['name'],
        committer_email: commit['commit']['committer']['email'],
        message: commit['commit']['message'].gsub("\n",' ').gsub("\r",' ')
      }
    end
    # sha repo date author date committer message
  end
  commits_list
end

# puts repo_list('csrordzhn').size
# to_tsv(repo_list('csrordzhn'), "mydata")
# puts user_dates('csrordzhn').to_s
# puts user_commits('csrordzhn').size
to_tsv(user_commits('csrordzhn'), "commits")
