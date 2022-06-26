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

    my_face_to = my_state["direction"]
    puts "----my_face_to: #{my_face_to}"
    # prepare data
    attcker_possible_range = {
      "N" => [[my_state["x"], my_state["y"] + 1], [my_state["x"], my_state["y"] + 2], [my_state["x"], my_state["y"] + 3]],
      "W" => [[my_state["x"] + 1, my_state["y"]], [my_state["x"] + 2, my_state["y"]], [my_state["x"] + 3, my_state["y"]]],
      "S" => [[my_state["x"], my_state["y"] - 1], [my_state["x"], my_state["y"] - 2], [my_state["x"], my_state["y"] - 3]],
      "E" => [[my_state["x"] - 1, my_state["y"]], [my_state["x"] - 2, my_state["y"]], [my_state["x"] - 3, my_state["y"]]]
    }

    case my_face_to
    when "N"
      attackable_range = [[my_state["x"], my_state["y"] - 1], [my_state["x"], my_state["y"] - 2], [my_state["x"], my_state["y"] - 3]]
      reverse_face_to = "S"
      my_next_step = [my_state["x"], my_state["y"] - 1]
      next_step_is_out_of_range = (my_state["y"] - 1) <= 0
    when "W"
      attackable_range = [[my_state["x"] - 1, my_state["y"]], [my_state["x"] - 2, my_state["y"]], [my_state["x"] - 3, my_state["y"]]]
      reverse_face_to = "E"
      my_next_step = [my_state["x"] - 1, my_state["y"]]
      next_step_is_out_of_range = (my_state["x"] - 1) <= 0
    when "S"
      attackable_range = [[my_state["x"], my_state["y"] + 1], [my_state["x"], my_state["y"] + 2], [my_state["x"], my_state["y"] + 3]]
      reverse_face_to = "N"
      my_next_step = [my_state["x"], my_state["y"] + 1]
      next_step_is_out_of_range = (my_state["y"] + 1) >= max_height
    when "E"
      attackable_range = [[my_state["x"] + 1, my_state["y"]], [my_state["x"] + 2, my_state["y"]], [my_state["x"] + 3, my_state["y"]]]
      reverse_face_to = "W"
      my_next_step = [my_state["x"] + 1, my_state["y"]]
      next_step_is_out_of_range = (my_state["x"] + 1) >= max_width
    end

    puts "----attackable_range: #{attackable_range}"

    closest_person_location = [max_width, max_height]
    closest_person_dis = max_width + max_height
    attackable = false
    anyone_in_front_of_me = false
    attcker_count = 0
    current_status["arena"]["state"].sort_by {|_, state| state["score"] }.reverse.each do |user_link, state|
      next if user_link == me
      anyone_in_front_of_me ||= my_next_step.include?([state["x"], state["y"]])
      can_attack = attackable_range.include?([state["x"], state["y"]])
      # always attack if no one attack me and I can attack
      return "T" if can_attack && !my_state["wasHit"]

      current_dis = (state["x"] - my_state["x"]).abs + (state["y"] - my_state["y"]).abs
      if current_dis < closest_person_dis
        closest_person_location = [state["x"], state["y"]]
        closest_person_dis = current_dis
      end

      is_possible_attacker = attcker_possible_range[state["direction"]].include?([state["x"], state["y"]])
      attackable = true if can_attack
      attcker_count += 1 if is_possible_attacker
      next if !is_possible_attacker
    end

    strategy = if attcker_count == 1 && attackable && my_state["wasHit"]
      # try to find back or run
      ["fight", "run", "run"].sample
    elsif my_state["wasHit"]
      "run"
    end
    puts "----strategy: #{strategy}"
    case strategy
    when "fight"
      return "T"
    when "run"
      return "F" unless anyone_in_front_of_me || next_step_is_out_of_range
      return ["R", "L"].sample
    end

    puts "----final closest_person_location: #{closest_person_location}"

    # find closest one and decide next step
    puts "----my_state: #{my_state}"
    x_direction = closest_person_location[0] - my_state["x"]
    y_direction = closest_person_location[1] - my_state["y"]

    puts "----x_direction: #{x_direction}"
    puts "----y_direction: #{y_direction}"
    action_take = if x_direction == 0 && y_direction < 0
      # up
      case my_face_to
      when "N"
        "F"
      when "W"
        "R"
      when "S"
        "L"
      when "E"
        "L"
      end
    elsif x_direction == 0 && y_direction > 0
      # down
      case my_face_to
      when "N"
        "R"
      when "W"
        "L"
      when "S"
        "F"
      when "E"
        "R"
      end
    elsif x_direction > 0 && y_direction == 0
      # right
      case my_face_to
      when "N"
        "R"
      when "W"
        "L"
      when "S"
        "L"
      when "E"
        "F"
      end
    elsif x_direction < 0 && y_direction == 0
      # left
      case my_face_to
      when "N"
        "L"
      when "W"
        "F"
      when "S"
        "R"
      when "E"
        "L"
      end
    elsif x_direction > 0 && y_direction > 0
      # right + down
      case my_face_to
      when "N"
        "R"
      when "W"
        "L"
      when "S"
        "F"
      when "E"
        "F"
      end
    elsif x_direction > 0 && y_direction < 0
      # right + up
      case my_face_to
      when "N"
        "F"
      when "W"
        "R"
      when "S"
        "L"
      when "E"
        "F"
      end
    elsif x_direction < 0 && y_direction < 0
      # left + down
      case my_face_to
      when "N"
        "L"
      when "W"
        "F"
      when "S"
        "F"
      when "E"
        "R"
      end
    elsif x_direction < 0 && y_direction > 0
      # left + up
      case my_face_to
      when "N"
        "F"
      when "W"
        "F"
      when "S"
        "L"
      when "E"
        "R"
      end
    end

    unless (action_take == "F" && next_step_is_out_of_range) || my_state["y"] == max_height || my_state["x"] == max_width
      puts "----action take: #{action_take}"
      return action_take
    end

    quadrant = if my_state["x"] >= max_width / 2 && my_state["y"] <= max_height / 2
      1
    elsif my_state["x"] <= max_width / 2 && my_state["y"] <= max_height / 2
      2
    elsif my_state["x"] <= max_width / 2 && my_state["y"] >= max_height / 2
      3
    elsif my_state["x"] >= max_width / 2 && my_state["y"] >= max_height / 2
      4
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
    puts "Something went wrong: #{e.backtrace}"
    ["F", "L", "R", "T"].sample
  end
end
