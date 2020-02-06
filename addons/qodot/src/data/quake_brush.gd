class_name QuakeBrush

# Resource representation of a .map file brush

var faces = []
var center = Vector3.ZERO

func _init(faces):
	self.faces = faces
	self.find_face_vertices()

	for face_idx in range(self.faces.size() - 1, -1, -1):
		var face = self.faces[face_idx]
		if face.face_vertices.size() < 3:
			self.faces.remove(face_idx)

	self.find_face_centers()
	self.face_vertices_to_local()
	self.wind_face()

	self.center = Vector3.ZERO
	var vertex_count = 0
	for face in self.faces:
		self.center += face.center
	self.center /= self.faces.size()

# Find vertices for each face
func find_face_vertices():
	for face1 in self.faces:
		for face2 in self.faces:
			for face3 in self.faces:
				if face1 == face2 or face1 == face3 or face2 == face3:
					continue

				var vertex = face1.intersect_faces(face2, face3)
				if vertex:
					if self.vertex_in_hull(vertex):
						if not face1.has_vertex(vertex) and not face2.has_vertex(vertex) and not face3.has_vertex(vertex):
							var normal = (face1.normal + face2.normal + face3.normal).normalized()
							face1.add_vertex(vertex, normal)
							face2.add_vertex(vertex, normal)
							face3.add_vertex(vertex, normal)

func find_face_centers():
	for face in self.faces:
		var center = Vector3.ZERO

		for vertex in face.face_vertices:
			center += vertex
		center /= face.face_vertices.size()

		face.center = center

func face_vertices_to_local():
	for face in self.faces:
		for idx in range(0, face.face_vertices.size()):
			face.face_vertices[idx] = face.face_vertices[idx] - face.center

func wind_face():
	for face in self.faces:
		var vertices = face.face_vertices
		var normals = face.face_normals

		var wound_vertex_rotation = []
		for vert_idx in range(0, vertices.size()):
			var vertex = vertices[vert_idx]
			var normal = normals[vert_idx]
			var winding_rotation = get_winding_rotation(vertex, face.normal, vertices[1] - vertices[0])
			wound_vertex_rotation.append([vertex, normal, winding_rotation])

		wound_vertex_rotation.sort_custom(self, 'sort_vertices_by_winding')

		var wound_vertices = PoolVector3Array()
		var wound_normals = PoolVector3Array()
		for vertex_rotation in wound_vertex_rotation:
			wound_vertices.append(vertex_rotation[0])
			wound_normals.append(vertex_rotation[1])

		face.face_vertices = wound_vertices
		face.face_normals = wound_normals

func sort_vertices_by_winding(a, b):
	return a[2] > b[2]

func get_winding_rotation(face_local_vertex, face_normal, face_basis):
	var vertex_uv = get_face_coords(face_local_vertex, face_normal, face_basis)
	var angle = vertex_uv.angle()
	return angle

func get_face_coords(face_local_vertex, face_normal, face_basis):
	var u = face_basis.normalized()
	var v = u.cross(face_normal).normalized()

	var pu = -face_local_vertex.dot(u)
	var pv = face_local_vertex.dot(v)

	return Vector2(pu, pv)

# Check to see if a given vertex resides inside a set of brush faces
func vertex_in_hull(vertex: Vector3):
	for face in self.faces:
		if(face.plane.is_point_over(vertex) && face.plane.distance_to(vertex) > 0.001):
			return false

	return true

func is_clip_brush():
	for face in faces:
		if(face.texture.findn('clip') != -1):
			return true
	return false
