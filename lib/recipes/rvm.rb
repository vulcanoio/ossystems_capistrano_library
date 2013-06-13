Capistrano::Configuration.instance(:must_exist).load do
  require "rvm/capistrano"

  # RVM methods:
  set :rvm_type, :system
  set :rvm_ruby_string, :local
  set :rvm_autolibs_flag, "enable"
  set :rvm_install_with_sudo, true
  set(:rvm_add_to_group) { user }
  set :rvm_path, "/usr/local/rvm" # force path since rvm-capistrano tries to install in the user home dir

  namespace :rvm do
    desc "[internal] Closes all active sessions."
    task :close_sessions do
      sessions.values.each { |session| session.close }
      sessions.clear
    end
  end

  def rvmsudo(command, options={})
    rvmsudo_user = options[:user].nil? ? "" : "-u #{options[:user]} "
    path = (options[:path] or current_path)
    env_vars = (options[:env_vars] or "")
    run "rvm#{sudo} #{rvmsudo_user} bash -c 'cd #{path} && RAILS_ENV=#{rails_env} #{env_vars} bundle exec #{command}'"
  end

  before 'deploy:setup', 'rvm:install_rvm'
  after 'rvm:install_rvm', 'rvm:close_sessions' # restart sessions to avoid permission bugs
  before 'deploy:setup', 'rvm:install_ruby' # install Ruby and create gemset for the first time
  before 'deploy:update', 'rvm:install_ruby' # in case an update changes the installed ruby
end
