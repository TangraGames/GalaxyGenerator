# Credits: Procedural Generation in Godot: Dungeon Generation by KidsCanCode https://youtu.be/o3fwlk1I-w

extends Node2D

var StarSystem = preload("res://StarSystem.tscn");

var num_stars = 600
var unit_size = 80
var horizontal_spread = 2000 # how spread out is the map on the horizontal axis
var vertical_spread = 500 # how spread out is the map on the vertical axis
var min_size = 1
var max_size = 3
var cull = 0.10

var path #AStar pathing object
var path_enhanced #AStar pathing object with additional connections

func _ready():
	randomize()
	create_galaxy()
	
func create_galaxy():
	for i in range(num_stars):
		var a = rand_range(-horizontal_spread, horizontal_spread)
		var b = rand_range(-vertical_spread, vertical_spread)
				
		var pos  = Vector2(a,b)
		var star = StarSystem.instance()
		var size = (min_size + randi() % (max_size - min_size)) * unit_size
		star.make_star(pos, size)
		$Galaxy.add_child(star)
		# wait for movement to stop
	yield(get_tree().create_timer(1.1), 'timeout')
	
	update()
	yield(get_tree().create_timer(1.1), 'timeout')
	
	#cull some star systems
	var star_locations = []
	
	for star in $Galaxy.get_children():
		if randf() < cull || star.size < (unit_size * 2):
		#if star.size < (min_size * unit_size * 3):
			star.queue_free()
		else:
			#star.size = 3 * unit_size
			star.mode = RigidBody2D.MODE_STATIC
			star_locations.append(Vector3(star.position.x, star.position.y, 0.0))
	yield(get_tree(), 'idle_frame')
	
	update()
	yield(get_tree().create_timer(1.1), 'timeout')
	
	
	# generate a minimum spanning tree connecting all stars
	path = find_mst(star_locations)
	
	update()
	yield(get_tree().create_timer(1.1), 'timeout')
	
	path_enhanced = astar_copy(path)
	
	#path_enhanced = add_more_connections_3(path_enhanced)
	path_enhanced = add_more_connections_3(path)
	update()

func _draw():
	for star in $Galaxy.get_children():
		draw_circle(star.position,  48, Color(1,1,1))
		draw_circle_arc(star.position,  star.size, 0, 360, Color(0.5,0.5,1))
		
	if path_enhanced:
		for p in path_enhanced.get_points():
			for c in path_enhanced.get_point_connections(p):
				var pp = path_enhanced.get_point_position(p)
				var cp = path_enhanced.get_point_position(c)
				draw_line(Vector2(pp.x, pp.y), Vector2(cp.x, cp.y), Color(1,0,0), 15, true)
	
	if path:
		for p in path.get_points():
			for c in path.get_point_connections(p):
				var pp = path.get_point_position(p)
				var cp = path.get_point_position(c)
				draw_line(Vector2(pp.x, pp.y), Vector2(cp.x, cp.y), Color(1,1,1), 15, true)

#custom function to draw circle arc, or empty circle. Default godot function draws filled circle only
func draw_circle_arc(center, radius, angle_from, angle_to, color):
	var nb_points = 32
	var points_arc = PoolVector2Array()
	
	for i in range(nb_points + 1):
		var angle_point = deg2rad(angle_from + i * (angle_to-angle_from) / nb_points - 90)
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)
	
	for index_point in range(nb_points):
		draw_line(points_arc[index_point], points_arc[index_point + 1], color)

#func _process(delta):
#	update()
	
func _input(event):
	if event.is_action_pressed('ui_select'):
		for n in $Galaxy.get_children():
			n.queue_free()
		path = null
		path_enhanced = null
		create_galaxy()
		
func find_mst(nodes):
	# Prim's algorithm
	var path = AStar.new()
	
	path.add_point(path.get_available_point_id(), nodes.pop_front())
	
	# repeat untill no more nodes remain
	while nodes:
		var min_dist = INF # min distanance found
		var min_p = null # position of the node with min distance to selected node
		var p = null # current position
		# Loop through all nodes on the path
		for p1 in path.get_points():
			var p1_pos = path.get_point_position(p1)
			# Loop through the remaing nodes
			for p2 in nodes:
				if p1_pos.distance_to(p2) < min_dist:
					min_dist = p1_pos.distance_to(p2)
					min_p = p2
					p = p1_pos
		var n = path.get_available_point_id()
		path.add_point(n, min_p)
		path.connect_points(path.get_closest_point(p), n)
		nodes.erase(min_p)
	return path

# add more hyperlanes
# remove crossing paths
func add_more_connections_3(astar):
	for p1 in astar.get_points():
		for p2 in astar.get_points():
			var p1_pos = astar.get_point_position(p1)
			var p2_pos = astar.get_point_position(p2)
			if p1_pos.distance_to(p2_pos) <= ((max_size * 2) * unit_size):
				if (p1 != p2):
					var pp = astar.get_point_path(p1,p2)
					if (pp.size() >= 5):
					#if (astar._estimate_cost >= 3.0):
						astar.connect_points(p1, p2)
	return astar

func astar_copy(astar):
	var astar_copy  = AStar.new()
	
	for p1 in astar.get_points():
		var p1_pos = astar.get_point_position(p1)
		astar_copy.add_point(p1, p1_pos)
		for p2 in astar.get_point_connections(p1):
			var p2_pos = astar.get_point_position(p2)
			astar_copy.add_point(p2, p2_pos)
			if !astar_copy.are_points_connected(p1,p2):
				astar_copy.connect_points(p1, p2)
	return astar_copy



