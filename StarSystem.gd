extends RigidBody2D

var size

func make_star (_pos, _size):
	position =_pos
	size = _size
	
	var s  = CircleShape2D.new()
	s.set_radius(size);
	$CollisionShape2D.shape = s
	