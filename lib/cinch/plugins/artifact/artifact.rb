require 'cinch-cooldown'
require 'cinch-storage'

module Cinch::Plugins
  class Artifact
    include Cinch::Plugin

    self.help = "Use .<artifact to get the artifact, even though you know it belongs in a museum."

    enforce_cooldown

    # Due to scoping issues that are annoying, we are hardcoding this config file.
    CONFIG_FILE = 'config/artifacts.yaml'

    def initialize(*args)
      super
      @storage = CinchStorage.new(config[:filename] || 'yaml/artifact.yml')
      @storage.data[:current] ||= Hash.new
      @storage.data[:last]    ||= Hash.new
      @storage.data[:stats]   ||= Hash.new
      Artifact.help = config[:help] if config[:help]
    end

    set(:prefix => '')

    @artifacts = {:artifact => { } }
    if File.exists?(CONFIG_FILE)
      @artifacts = YAML::load(File.open(CONFIG_FILE))
    end

    @artifacts.keys.each do |artifact|
      match /^[!\.](#{artifact})$/,       :method => :steal
      match /^[!\.](#{artifact}) info/,   :method => :info
      match /^[!\.](#{artifact}) stats/,  :method => :stats
    end

    def get_artifacts
    end

    def steal(m, item)
      if m.channel.nil?
        m.user.msg "You must use that command in the main channel."
        return
      end

      current_nick = @storage.data[:current][:nick]
      current_time = @storage.data[:current][:time]

      if current_nick
        if current_nick == m.user.nick
          m.reply artifact_message(:same_user), true
        else
          m.channel.action artifact_message(:new_owner, { :new => m.user.nick,
                                                          :old => current_nick })
          add_stats(current_nick, 0, current_time)
          current = { :nick => m.user.nick, :time => Time.now,
                      :times_passed => @storage.data[:item][:current][:times_passed] + 1 }
          @storage.data[:current] = current
          add_stats(m.user.nick, 1)
        end
      else
        m.channel.action artifact_message(:new, {:new => m.user.nick})
        @storage.data[:current] = {:nick => m.user.nick, :time => Time.now, :times_passed => 0 }
        add_stats(m.user.nick, 1)
      end

      synchronize(:save_artifact) do
        @storage.save
      end

    end

    def stats(m)
      stats = []
      @storage.data[:stats].each_pair do |nick,info|
        stats << { :nick => nick, :time => info[:time], :count => info[:count] }
      end

      stats.sort! {|x,y| y[:count] <=> x[:count] }
      m.user.msg "Top 5 users by times they've had the #{@item}:"
      stats[0..4].each_index do |i|
        m.user.msg "#{i + 1}. #{stats[i][:nick]} - #{stats[i][:count]}"
      end

      stats.sort! {|x,y| y[:time] <=> x[:time] }
      m.user.msg "Top 5 users by the total time they've had the #{@item}:"
      stats[0..4].each_index do |i|
        m.user.msg "#{i + 1}. #{stats[i][:nick]} - #{Cinch::Toolbox.time_format(stats[i][:time])}"
      end
    end

    def info(m)
      if @storage.data.key?(:current)
        if @storage.data[:current].key?(:nick)
          message = "#{@storage.data[:current][:nick]} is"
        else
          message = 'I am'
        end

        message << " currently holding the #{@item}"

        if @storage.data[:current].key?(:time)
          message << ". I gave it to them #{@storage.data[:current][:time].ago.to_words}"
        end

        unless @storage.data[:current].key?(:times_passed)
          message << " and it's been shared by #{@storage.data[:current][:times_passed]} other people"
        end

        top = get_top_users

        unless top.nil?
          if top.key?(:count) && top.key?(:time) && top[:count][:nick] == top[:time][:nick]
            message << ". #{top[:count][:nick].capitalize} seems to love the #{@item} because they've held " +
                       "on to it more times (#{top[:count][:number]}) and " +
                       "for longer (#{Cinch::Toolbox.time_format(top[:time][:number])}) than anyone else "
          elsif top.key?(:count) && top.key?(:time)
            message << ". So far, #{top[:count][:nick]} has had the #{@item} the most times at #{top[:count][:number]}, " +
                       "while #{top[:time][:nick]} has held it for the longest time at  #{Cinch::Toolbox.time_format(top[:time][:number])}"
          elsif top.key?(:count)
            message << ". So far, #{top[:count][:nick]} has had the #{@item} the most times at #{top[:count][:number]}"
          elsif top.key?(:time)
            message << ". So far, #{top[time][:nick]} has held the #{@item} for the longest time at #{Cinch::Toolbox.time_format(top[:time][:number])}"
          end
        end
        message.strip!
        message << '.'
      else
        message = "no one seems to want my #{@item} :("
      end

      m.reply message, true
    end

    def add_stats(user, count, time = nil)
      unless @storage.data[:stats].key?(user)
        @storage.data[:stats][user] = { :count => 0, :time => 0 }
      end

      @storage.data[:stats][user][:count] += count
      @storage.data[:stats][user][:time]  += (Time.now - time) unless time.nil?
    end

    def get_top_users
      counts = @storage.data[:stats].sort {|a,b| b[1][:count] <=> a[1][:count] }
      times = @storage.data[:stats].sort {|a,b| b[1][:time] <=> a[1][:time] }
      { :count => { :nick => counts.first[0], :number => counts.first[1][:count] },
        :time  => { :nick => times.first[0],  :number => times.first[1][:time] }}
    end

    def artifact_message(event, data = nil)
      case event
      when :same_user
        "you still have the #{@item}. Chill the fuck out."
      when :new_owner
        "reaches over to #{data[:old]}, takes #{@item}, and hands it to #{data[:new]}"
      when :new
        "reaches down and grabs the #{@item} and hands it to #{data[:new]}"
      end
    end
  end
end
