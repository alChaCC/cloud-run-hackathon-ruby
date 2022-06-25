require 'sinatra'

$stdout.sync = true

configure do
  set :port, 8080
  set :bind, '0.0.0.0'
end

get '/' do
  'Let the battle begin!'
end

post '/' do
  begin
    current_status = JSON.parse(request.body.read)
    puts "----current_status: #{current_status}"

    me = current_status["_links"]["self"]["href"]
    my_state = current_status["arena"]["state"][me]
    max_width = current_status["arena"]["dims"][0]
    max_height = current_status["arena"]["dims"][1]
    quadrant = if my_state["x"] >= max_width / 2 && my_state["y"] <= max_height / 2
      1
    elsif my_state["x"] <= max_width / 2 && my_state["y"] <= max_height / 2
      2
    elsif my_state["x"] <= max_width / 2 && my_state["y"] >= max_height / 2
      3
    elsif my_state["x"] >= max_width / 2 && my_state["y"] >= max_height / 2
      4
    end

    my_face_to = my_state["direction"]
    puts "----my_face_to: #{my_face_to}"
    # Attack if someone in front of me either face to me
    attackable_range =
      case my_face_to
      when "N"
        [[my_state["x"], my_state["y"] - 3], [my_state["x"], my_state["y"] - 2], [my_state["x"], my_state["y"] - 1]]
      when "W"
        [[my_state["x"] - 3, my_state["y"]], [my_state["x"] - 2, my_state["y"]], [my_state["x"] - 1, my_state["y"]]]
      when "S"
       [[my_state["x"], my_state["y"] + 3], [my_state["x"], my_state["y"] + 2], [my_state["x"], my_state["y"] + 1]]
      when "E"
        [[my_state["x"] + 3, my_state["y"]], [my_state["x"] + 2, my_state["y"]], [my_state["x"] + 1, my_state["y"]]]
      end

    puts "----attackable_range: #{attackable_range}"

    current_status["arena"]["state"].each do |user_link, state|
      next if user_link == me

      if attackable_range.include?([state["x"], state["y"]])
        if my_state["wasHit"]
          # if anyone is able to attach me then run
          my_next_step =
            case my_face_to
            when "N"
              [my_state["x"], my_state["y"] - 1]
            when "W"
              [my_state["x"] - 1, my_state["y"]]
            when "S"
              [my_state["x"], my_state["y"] + 1]
            when "E"
              [my_state["x"] + 1, my_state["y"]]
            end
          unless my_next_step[0] < 0 || my_next_step[0] > max_width || my_next_step[1] < 0 || my_next_step[1] > max_height || (my_next_step[0] == state["x"] && my_next_step[1] == state["y"])
            puts "----action take: F"
            return "F"
          end
        else
          # try attack again
          puts "----action take: F"
          return "T"
        end
      end
    end

    moves = case quadrant
    when 1
      case my_face_to
      when "N"
        ["L"]
      when "W"
        ["F", "L"]
      when "S"
        ["F", "R"]
      when "E"
        ["R"]
      end
    when 2
      case my_face_to
      when "N"
        ["R"]
      when "W"
        ["L"]
      when "S"
        ["L", "F"]
      when "E"
        ["R", "F"]
      end
    when 3
      case my_face_to
      when "N"
        ["F", "R"]
      when "W"
        ["R"]
      when "S"
        ["L"]
      when "E"
        ["L", "F"]
      end
    when 4
      case my_face_to
      when "N"
        ["F", "L"]
      when "W"
        ["F", "R"]
      when "S"
        ["R"]
      when "E"
        ["L"]
      end
    end
    action = moves.sample
    puts "----action take: #{action}"
    action
  rescue => e
    puts "Something went wrong: #{e.message}"
    ["F", "L", "R", "T"].sample
  end
end
