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
    attcker_possible_range = [
      [my_state["x"], my_state["y"] - 1], [my_state["x"], my_state["y"] - 2], [my_state["x"], my_state["y"] - 3],
      [my_state["x"] - 1, my_state["y"]], [my_state["x"] - 2, my_state["y"]], [my_state["x"] - 3, my_state["y"]],
      [my_state["x"], my_state["y"] + 1], [my_state["x"], my_state["y"] + 2], [my_state["x"], my_state["y"] + 3],
      [my_state["x"] + 1, my_state["y"]], [my_state["x"] + 2, my_state["y"]], [my_state["x"] + 3, my_state["y"]]
    ]
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

    # always attack if no one attack me and I can attack
    current_status["arena"]["state"].sort_by {|_, state| state["score"] }.reverse.each do |user_link, state|
      next if user_link == me
      can_attack = attackable_range.include?([state["x"], state["y"]])
      return "T" if can_attack && !my_state["wasHit"]

      is_possible_attacker = attcker_possible_range.include?([state["x"], state["y"]])
      next if !is_possible_attacker
      return ["T", "T", "T", "F"].sample if is_possible_attacker && state["score"] >= my_state["score"] && can_attack
      return ["R", "R", "L", "L", "F"].sample if is_possible_attacker && state["score"] >= my_state["score"] && !can_attack && reverse_face_to == state["direction"]
    end

    action_take = ["F", "R", "L"].sample

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
    puts "Something went wrong: #{e.message}"
    ["F", "L", "R", "T"].sample
  end
end
