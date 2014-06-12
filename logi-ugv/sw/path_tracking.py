

import numpy
import time



class PurePursuit():
	
	look_ahead_dist = 10.0

	def __init__(self):

	
	def computeSteering(self, point_A, point_B, pos, heading):	
		eq_path = (0, 0)	
		# compute path equation
		eq_path[0] = (point_A.y - point_B.y)/(point_A.x - point_B.x)
		eq_path[1] = point_B.y - (point_B.x*eq_path[0])
		#compute equation of line orthogonal to path and passing by current position		
		eq_orth = ((-1/eq_path[0]), 0)
		eq_orth[1] = pos.y - (eq_orth[0]*pos.x)
		cross_x = (eq_path[1] - eq_orth[1])/(eq_path[0] - eq_orth[0])
		cross_y = cross_x * eq_path[0] + eq_path[1]		
		#comute coordinates of lookahead point
		tetha = math.atan(eq_path[0]) # compute line angle
		look_ahead_point_y = (look_ahead_dist * math.sin(tetha)) + cross_y
		look_ahead_point_x = (look_ahead_dist * math.cos(tetha)) + cross_x
		
		# should check that the look_ahead point is not further that the target waypoint
				
		# now translating and rotating to center on robot
		look_ahead_point_x = look_ahead_point_x - pos.x
		look_ahead_point_y = look_ahead_point_y - pos.y

		#rotation to align on robot reference frame		
		rotation_tetha = 90.0 - heading
		look_ahead_point_x = look_ahead_point_x * cos(toRad*rotation_tetha)
		look_ahead_point_y = look_ahead_point_y * sin(toRad*rotation_tetha)

		
		

		
		
		
