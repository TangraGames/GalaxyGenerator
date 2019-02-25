extends Node2D

var StarSystem = preload("res://StarSystem.tscn");

var num_stars = 200
var unit_size = 75
var horizontal_spread = 2000 # how spread out is the map on the horizontal axis
var vertical_spread = 200 # how spread out is the map on the vertical axis
var min_size = 1
var max_size = 5
var cull = 0.25

var path #AStar pathing object

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
		#cull some star systems
	
	var star_locations = []
	
	for star in $Galaxy.get_children():
		#if randf() < cull:
		if star.size < (min_size * unit_size * 3):
			star.queue_free()
		else:
			star.mode = RigidBody2D.MODE_STATIC
			star_locations.append(Vector3(star.position.x, star.position.y, 0.0))
	yield(get_tree(), 'idle_frame')
	yield(get_tree().create_timer(1.1), 'timeout')	
	# generate a minimum spanning tree connecting all stars
	path = find_mst(star_locations)

func _draw():
	for star in $Galaxy.get_children():
		draw_circle(star.position,  32, Color(1,1,1))
		draw_circle_arc(star.position,  star.size, 0, 360, Color(0.5,0.5,1))
	if path:
		for p in path.get_points():
			for c in path.get_point_connections(p):
				var pp = path.get_point_position(p)
				var cp = path.get_point_position(c)
				draw_line(Vector2(pp.x, pp.y), Vector2(cp.x, cp.y), Color(0,1,0), 15, true)

#custom function to draw circle arc, or empty circle
func draw_circle_arc(center, radius, angle_from, angle_to, color):
	var nb_points = 32
	var points_arc = PoolVector2Array()
	
	for i in range(nb_points + 1):
		var angle_point = deg2rad(angle_from + i * (angle_to-angle_from) / nb_points - 90)
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)
	
	for index_point in range(nb_points):
		draw_line(points_arc[index_point], points_arc[index_point + 1], color)

func _process(delta):
	update()
	
func _input(event):
	if event.is_action_pressed('ui_select'):
		for n in $Galaxy.get_children():
			n.queue_free()
		path = null
		create_galaxy()
		
func find_mst(nodes):
	# Prim's algorithm
	var path = AStar.new()
	path.add_point(path.get_available_point_id(), nodes.pop_front())
	
	# repeat untill no more nodes remain
	while nodes:
		var min_dist = INF # min distanance found
		var min_p = null # position of that node
		var p = null # current position
		# Loop through all nodes on the path
		for p1 in path.get_points():
			p1 = path.get_point_position(p1)
			# Loop through the remaing nodes
			for p2 in nodes:
				#if p1.distance_to(p2) < min_dist:
				if p1.distance_to(p2) < min_dist:
					min_dist = p1.distance_to(p2)
					min_p = p2
					p = p1
		var n = path.get_available_point_id()
		path.add_point(n, min_p)
		path.connect_points(path.get_closest_point(p), n)
		nodes.erase(min_p)
	return path
		
			
