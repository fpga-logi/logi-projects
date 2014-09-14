

import numpy
import time
import math
#import matplotlib.pyplot as plt

from coordinates import EuclidianPoint
		

class PurePursuit():
	
	look_ahead_dist = 5.0

	def __init__(self):
		self.curv = 0.0
	
	def computeSteering(self, point_A, point_B, pos, heading):	
		toRad = math.pi/180.0		
		eq_path = [0, 0]	
		# compute path equation

		#special case, avoid division by zero ...
		if (point_A.x - point_B.x) == 0:
			return 0.0
		
		#compute path equation from A to B
		eq_path[0] = (point_A.y - point_B.y)/(point_A.x - point_B.x)
		eq_path[1] = point_B.y - (point_B.x*eq_path[0])
			
		# case of equation on being constant
		if eq_path[0] != 0.0:	
			eq_orth = [(-1/eq_path[0]), 0]
			eq_orth[1] = pos.y - (eq_orth[0]*pos.x)
			cross_x = (eq_orth[1] - eq_path[1])/(eq_path[0] - eq_orth[0])
			cross_y = cross_x * eq_path[0] + eq_path[1]
		else:
			#compute equation of line orthogonal to path and passing by current position
			eq_orth = [0.0, pos.x]
			cross_x = pos.x
			cross_y = eq_path[1]
				
		#compute coordinates of lookahead point on A to B path
		tetha = math.atan(eq_path[0]) # compute line angle

		# handle path direction to compute lokkahead point
		if point_A.x < point_B.x:
			look_ahead_point_y = cross_y + (self.look_ahead_dist * math.sin(tetha)) 
			look_ahead_point_x = cross_x + (self.look_ahead_dist * math.cos(tetha))
		else:
			look_ahead_point_y = cross_y - (self.look_ahead_dist * math.sin(tetha)) 
			look_ahead_point_x = cross_x - (self.look_ahead_dist * math.cos(tetha))
		
		#compute distance from cross position to look ahead
		dist_to_look_ahead = math.sqrt(math.pow(cross_x - look_ahead_point_x, 2) + math.pow(cross_y - look_ahead_point_y, 2))
		#compute distance to point B		
		dist_to_target = math.sqrt(math.pow(cross_x - point_B.x, 2) + math.pow(cross_y - point_B.y, 2))
		
		# look ahead point is ahead of target, using target as look_ahead
		if dist_to_look_ahead > dist_to_target :
			look_ahead_point_y = point_B.y
			look_ahead_point_x = point_B.x
				
				
		# now translating and rotating to center on robot
		look_ahead_point_x_trans = look_ahead_point_x - pos.x
		look_ahead_point_y_trans = look_ahead_point_y - pos.y
		
		
		#rotation to align on robot reference frame, heading pointing 90
		rotation_tetha = heading
		look_ahead_point_x_rob = look_ahead_point_x_trans * math.cos(toRad*rotation_tetha) - look_ahead_point_y_trans * math.sin(toRad*rotation_tetha)
		look_ahead_point_y_rob = look_ahead_point_x_trans * math.sin(toRad*rotation_tetha) + look_ahead_point_y_trans * math.cos(toRad*rotation_tetha)
		
		# following is based on 
		# http://www8.cs.umu.se/kurser/TDBD17/VT06/utdelat/Assignment%20Papers/Path%20Tracking%20for%20a%20Miniature%20Robot.pdf
		
		D_square = pow(look_ahead_point_x_rob, 2) + pow(look_ahead_point_y_rob, 2)
		r = D_square/(2.0*look_ahead_point_x_rob)
		curvature = 1.0/r
		return curvature
		
'''	
		plt.subplot(211)
		plt.plot(point_A.x, point_A.y, '+r')
		plt.plot(point_B.x, point_B.y, '+g' )
		plt.plot(pos.x,  pos.y, '+b')
		plt.plot(cross_x, cross_y, '+k')
		plt.plot(look_ahead_point_x, look_ahead_point_y, '+c')
		
		path_x = numpy.linspace(point_A.x,point_B.x,100) # 100 linearly spaced numbers
		path_y = eq_path[0]*path_x + eq_path[1]
		plt.plot(path_x, path_y)
		equ_x = numpy.linspace(cross_x, pos.x, 100) # 100 linearly spaced numbers
		equ_y = eq_orth[0]*equ_x + eq_orth[1]
		plt.plot(equ_x, equ_y, 'r')
		#plt.axis([0.0, 25, 0.0, 25])


		
		plt.subplot(212)
		circ = plt.Circle((r, 0),r,color='r', fill=False)
		plt.plot(0.0, 0.0, '+r')
		plt.plot(look_ahead_point_x_rob, look_ahead_point_y_rob, '+b')
		plt.plot(r, 0.0, '+k')
		
		plt.gca().add_artist(circ)
		plt.show()

		#positive value is turning right, negative value is turning left
		return curvature
'''		


if __name__ == "__main__":	
	path = PurePursuit()
	curv = path.computeSteering(EuclidianPoint(0.0, 0.0), EuclidianPoint(-25.0, -8.0), EuclidianPoint(0.0, 0.0), 76.83)
	steering = math.sinh(curv)*(180.0/math.pi)
	print curv
	print steering
		

		
		
		
